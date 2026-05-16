# Agent 06 Data Supabase Foundation

Status: Sprint 1 Supabase foundation draft.

This plan gives SiteClaw a production-ready persistence foundation for authenticated restaurant workspaces without changing the current local Talk -> Build -> Preview -> Review & Export -> Open Site demo.

Canonical QA/Security gate:

- `../product/milestone-1-qa-security-gate.md`

Agent 09 will audit this foundation against the gate's Agent 6 Audit Contract before any production or founding-beta data path is approved.

Primary migration:

- `supabase/migrations/0001_siteclaw_foundation.sql`

## Scope Guardrails

- Do not edit SwiftUI screens, backend route handlers, AI prompts, or renderer templates for this packet.
- Do not commit Supabase keys, service role keys, database passwords, or local `.env` values.
- Keep `restaurant.json` compatible with the existing renderer contract in `RestaurantJSONModels.swift`.
- Allow a one-restaurant MVP start without adding a unique owner constraint that would block future multi-restaurant accounts.
- Keep Stripe deferred. `subscriptions` stores plan state but defaults to a starter trial until founding beta/Stripe policy is finalized.

## V1 Tables

| Table | Purpose | Owner Access | Service Role Access |
| --- | --- | --- | --- |
| `restaurants` | Restaurant workspace root, owner id, slug, lifecycle, publish status | Read/insert/update own rows | Full trusted writes |
| `restaurant_profiles` | Editable Build/profile fields plus latest `restaurant.json` snapshot metadata | Read/insert/update own profile | Full trusted writes |
| `voice_answers` | Guided answers, raw transcript, cleaned answer, confidence, extracted patch | Read/insert/update own answers | Full trusted writes |
| `generated_drafts` | AI/backend-generated copy, site strategy, generated `restaurant.json` draft | Read own drafts | Writes trusted drafts |
| `uploaded_assets` | Metadata for private uploads and promoted published assets | Read own assets; insert/update private upload metadata | Writes public/published asset metadata |
| `publish_records` | Publish attempts, statuses, URLs, Cloudflare ids, published path prefix | Read own publish history | Writes publish lifecycle |
| `edit_history` | Audit trail for manual edits, AI cleanup, imports, publish changes | Read own history | Writes audit records |
| `subscriptions` | Plan, billing status, edit limits, Stripe ids for later phase | Read own subscription | Writes billing/plan state |

Owner identity is always `auth.users.id`, stored as `restaurants.owner_id`.

## Relationship Rules

- `restaurants.owner_id -> auth.users.id`.
- Every workspace-owned table has `restaurant_id -> restaurants.id`.
- `uploaded_assets.owner_id` duplicates `restaurants.owner_id` only to make storage-path validation and owner lookups explicit.
- `subscriptions.restaurant_id` is unique for V1, but `restaurants.owner_id` is not unique. One owner can start with one restaurant, and the schema can later support multiple restaurants.
- `restaurant_profiles.restaurant_json` stores the latest app-compatible JSON snapshot. Approved/public publishing should write the same contract to Supabase Storage.

## RLS Policy Notes

RLS is enabled for every V1 table in migration 0001.

Policies:

- Owners can read/write only rows connected to restaurants where `restaurants.owner_id = auth.uid()`.
- Owner writes are limited to core workspace input tables: `restaurants`, `restaurant_profiles`, `voice_answers`, and private `uploaded_assets` metadata.
- Owners can read but not directly write `generated_drafts`, `publish_records`, `edit_history`, or `subscriptions`.
- Service role is backend-only and can perform trusted server writes.
- Anonymous users get no relational table access.
- RLS helpers wrap `auth.uid()` in `select` in policies for Supabase/Postgres RLS performance.
- FK and policy lookup columns are indexed.

Service-role-only writes:

- `generated_drafts`
- `publish_records`
- `edit_history`
- `subscriptions`
- public `uploaded_assets` rows for published assets
- published storage objects

## Storage Buckets

### Private `restaurant-data`

Purpose: validated `restaurant.json` for app/backend/publisher use.

Object path:

```text
{owner_id}/{restaurant_id}/restaurant.json
```

Policy:

- Authenticated owner can read/write only when `{owner_id}` matches `auth.uid()` and `{restaurant_id}` belongs to that owner.
- Anonymous users cannot read.
- Service role can read/write for backend validation and publishing.

### Private `restaurant-uploads`

Purpose: uploaded menus, dish photos, logos, hero images, and other owner-provided inputs.

Object path:

```text
{owner_id}/{restaurant_id}/uploads/{asset_id}
```

Policy:

- Authenticated owner can read/write/delete only inside their own owner/restaurant prefix.
- `uploaded_assets.storage_bucket = 'restaurant-uploads'`.
- `uploaded_assets.storage_path` should match the same path and include the row id as `{asset_id}`.
- Anonymous users cannot read.

### Public-Read-After-Publish `published-assets`

Purpose: approved public site artifacts copied by the publish worker after owner approval.

Object path:

```text
{restaurant_slug}/published/{asset_name}
```

Policy:

- Bucket is public readable.
- Owners do not write directly to this bucket.
- Backend service role writes only after publish approval.
- `publish_records.published_assets_bucket = 'published-assets'`.
- `publish_records.published_path_prefix = '{restaurant_slug}/published/'`.

## `restaurant.json` Contract

Current schema version: `1.0`.

The migration preserves the existing renderer-facing JSON shape:

- `schema_version`
- `restaurant_id`
- `last_updated`
- `basics`
- `contact`
- `hours`
- `menu`
- `seo`
- `branding`
- `visibility`
- `features`
- `growth_tools`
- `design_brief`

Storage rules:

- Latest editable snapshot may live in `restaurant_profiles.restaurant_json`.
- AI/backend draft output may live in `generated_drafts.restaurant_json`.
- Validated workspace JSON should be written to `restaurant-data/{owner_id}/{restaurant_id}/restaurant.json`.
- Published JSON or derived public assets should be copied to `published-assets/{restaurant_slug}/published/...` only after owner approval.

## Migration Order

Migration 0001 runs in this order:

1. Enable `pgcrypto` and create shared helper functions.
2. Create V1 tables.
3. Create indexes for owner lookup, slug lookup, publish history, voice history, edit history, uploads, and subscription lookups.
4. Create ownership/bootstrap helper functions.
5. Create `updated_at` triggers.
6. Enable RLS for every V1 table.
7. Create RLS policies.
8. Grant authenticated read/write scopes and service-role table scopes.
9. Create the three storage buckets.
10. Create private storage policies for `restaurant-data` and `restaurant-uploads`.

## Rollback Notes

Before production data exists:

- Local Supabase: use `supabase db reset`.
- Remote/staging: prefer destroying the fresh staging project or applying a reverse migration before real user data is entered.

Reverse migration order, if needed:

1. Drop storage policies on `storage.objects`.
2. Delete `published-assets`, `restaurant-uploads`, and `restaurant-data` buckets only after objects are removed.
3. Drop table RLS policies.
4. Drop grants and helper functions.
5. Drop triggers.
6. Drop tables in dependency order: `subscriptions`, `edit_history`, `publish_records`, `uploaded_assets`, `generated_drafts`, `voice_answers`, `restaurant_profiles`, `restaurants`.

After production data exists, do not destructive-rollback. Add forward migrations that preserve or migrate existing rows.

## Seed And Demo Strategy

Do not seed production by inserting fake rows directly into `auth.users`.

Fresh staging/local flow:

1. Create two test users through Supabase Auth.
2. Authenticate as owner A and call `public.bootstrap_restaurant_for_owner('Sunset Grill')`.
3. Authenticate as owner B and call `public.bootstrap_restaurant_for_owner('Test Cafe')`.
4. Update owner A's `restaurant_profiles` row with Sunset Grill demo data.
5. Insert `voice_answers` rows for the guided prompts.
6. Create `uploaded_assets` rows first, using client-generated UUIDs for `asset_id`, then upload objects to `restaurant-uploads/{owner_id}/{restaurant_id}/uploads/{asset_id}`.
7. Use backend service role to insert `generated_drafts`, `edit_history`, and `publish_records`.
8. For publish smoke tests, service role copies approved output to `published-assets/{restaurant_slug}/published/{asset_name}`.

## Type Generation Plan

Backend TypeScript:

```bash
supabase gen types typescript --project-id "$SUPABASE_PROJECT_ID" --schema public > Backend/types/supabase.ts
```

iOS:

- Keep `RestaurantJSONModels.swift` as the renderer contract source for this sprint.
- Persist `restaurant_id` and `owner_id` returned by auth/bootstrap.
- Prefer backend API DTOs for trusted writes instead of exposing service-role-only table writes to iOS.

## Agent Handoff

### Agent 03 iOS

- Auth user id maps to `restaurants.owner_id`.
- Current Build form maps primarily to `restaurant_profiles`.
- Guided voice prompt saves map to `voice_answers`.
- Local uploaded menu/dish metadata maps to `uploaded_assets`; object bytes go to `restaurant-uploads`.
- Generated preview JSON remains compatible with `restaurant_profiles.restaurant_json` and `generated_drafts.restaurant_json`.

### Agent 04 Backend

Use service role for:

- `generated_drafts` writes
- `publish_records` writes
- `edit_history` writes
- `subscriptions` writes
- publish promotion rows in `uploaded_assets`
- writes to `published-assets`

Owner-scoped endpoints may read/write:

- `restaurants`
- `restaurant_profiles`
- `voice_answers`
- private `uploaded_assets` metadata

### Agent 07 Publishing

- Publish attempts are recorded in `publish_records`.
- Validated private JSON lives at `restaurant-data/{owner_id}/{restaurant_id}/restaurant.json`.
- Public artifacts live under `published-assets/{restaurant_slug}/published/{asset_name}`.
- `publish_records.status` moves through `queued -> building -> live` or `failed`.
- `publish_records.published_path_prefix` should be the durable prefix for all public assets in that publish.

### Agent 09 QA/Security

Canonical gate:

- `../product/milestone-1-qa-security-gate.md`

Test:

- Owner A cannot read or write Owner B rows.
- Anonymous users cannot read any private workspace table.
- Owner A can read/write own `restaurant_profiles`.
- Owner A cannot write service-role-only tables.
- Service role can write generated drafts, publish records, edit history, subscription state, and published assets.
- Private storage buckets reject anonymous reads.
- `published-assets` is public only for publish-worker-written paths.
- No secrets appear in committed files.

## Verification Instructions

### Migration Applies Cleanly

Fresh local project:

```bash
supabase init
supabase start
supabase db reset
```

Linked remote/staging project:

```bash
supabase init
supabase link --project-ref "$SUPABASE_PROJECT_ID"
supabase db push
```

Run `supabase init` only once if the project has not already been initialized.

### SQL Smoke Queries For Owner Isolation

Create two Supabase Auth users first and copy their UUIDs into the script.

```sql
-- Run as postgres/service role in SQL editor for setup.
select public.bootstrap_restaurant_for_owner('Setup should fail without JWT');
```

The unauthenticated bootstrap call should fail. Then run owner-scoped checks through an authenticated client, or simulate JWT claims in SQL:

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '<owner_a_uuid>', true);

insert into public.restaurants (owner_id, name, slug)
values ('<owner_a_uuid>', 'Owner A Grill', 'owner-a-grill')
returning id;

select * from public.restaurants;
-- Expected: only owner A rows.

select set_config('request.jwt.claim.sub', '<owner_b_uuid>', true);
select * from public.restaurants where slug = 'owner-a-grill';
-- Expected: zero rows.
rollback;
```

Restaurant profile write smoke:

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '<owner_a_uuid>', true);

insert into public.restaurant_profiles (restaurant_id, owner_name, city)
values ('<owner_a_restaurant_id>', 'Owner A', 'San Jose')
on conflict (restaurant_id) do update
set owner_name = excluded.owner_name,
    city = excluded.city;
-- Expected: succeeds for owner A restaurant id.

insert into public.restaurant_profiles (restaurant_id, owner_name)
values ('<owner_b_restaurant_id>', 'Bad Write');
-- Expected: rejected by RLS.
rollback;
```

Service-role write smoke:

```sql
set local role service_role;

insert into public.generated_drafts (restaurant_id, headline, restaurant_json)
values ('<owner_a_restaurant_id>', 'Fresh local food', '{"schema_version":"1.0"}'::jsonb);

insert into public.publish_records (restaurant_id, site_slug, status)
values ('<owner_a_restaurant_id>', 'owner-a-grill', 'queued');
```

### Storage Policy Smoke Test Outline

Using a Supabase client authenticated as owner A:

1. Upload `restaurant.json` to `restaurant-data/{owner_a_id}/{restaurant_a_id}/restaurant.json`; expect success.
2. Upload the same file to `restaurant-data/{owner_b_id}/{restaurant_b_id}/restaurant.json`; expect failure.
3. Upload a menu file to `restaurant-uploads/{owner_a_id}/{restaurant_a_id}/uploads/{asset_id}`; expect success.
4. Attempt anonymous download from `restaurant-data` and `restaurant-uploads`; expect failure.
5. Using service role, upload a public file to `published-assets/{restaurant_slug}/published/site.css`; expect success.
6. Fetch the public published asset without auth; expect success only for the `published-assets` URL.

### Secret Scan And Diff Hygiene

```bash
git diff --check
rg -n "SUPABASE_SERVICE_ROLE_KEY|service_role.*eyJ|postgres://|DATABASE_URL|anon.*eyJ|password=" .
```

The secret scan should produce no committed secret values. Environment variable names in docs or `.env.example` are okay; real values are not.
