# Backend API Contracts

Owner: Agent 4, Backend Platform Engineer

Status: Draft v0.1 for Milestone 1 production foundation

Last updated: 2026-05-15

## Goal

This document defines the production API surface the iOS app and other SiteClaw agents should integrate against. It keeps the current local demo endpoints working while naming the authenticated production endpoints needed for founding beta.

## Scope

In scope:

- Health and config checks
- Realtime client-secret creation
- Voice answer cleanup
- Structured field extraction
- Voice coach feedback
- Draft generation
- Restaurant workspace load/save
- Upload metadata registration
- Preview artifact generation
- Publish, republish, and publish status lookup
- Structured backend errors

Out of scope for this contract:

- Final Supabase table and RLS migrations
- Final Cloudflare renderer internals
- Stripe billing enforcement
- iOS UI implementation

## Base URLs

| Environment | Base URL | Notes |
| --- | --- | --- |
| Local demo | `http://localhost:8787` | Current Node backend, no production auth required |
| Staging | `https://staging-api.siteclaw.com` | Planned authenticated backend |
| Production | `https://api.siteclaw.com` | Planned authenticated backend |

## Auth Expectations

Production owner endpoints require:

```http
Authorization: Bearer <supabase_access_token>
Content-Type: application/json
```

The backend must verify the Supabase JWT and derive:

```json
{
  "user_id": "uuid",
  "auth_provider": "supabase"
}
```

Server-owned operations use service credentials only inside the backend. The iOS app must never receive:

- `OPENAI_API_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- Cloudflare API tokens
- Storage service credentials

Local demo behavior:

- Existing local endpoints can continue without auth.
- Production routes may run in a local auth-bypass mode only when explicitly configured for development.
- Local auth-bypass responses must be marked with `"environment": "local"`.

## Standard Success Envelope

Endpoints that return business data should include stable metadata:

```json
{
  "ok": true,
  "request_id": "req_local_123",
  "data": {}
}
```

Compatibility note: existing local endpoints may continue returning their current flatter shapes during the demo branch, but production endpoints should use the envelope above.

## Standard Error Contract

All production errors must use:

```json
{
  "error": {
    "code": "string",
    "message": "safe user-facing message",
    "retryable": true
  }
}
```

Recommended codes:

| Code | HTTP | Retryable | Meaning |
| --- | ---: | --- | --- |
| `bad_request` | 400 | false | Invalid JSON or missing required field |
| `unauthorized` | 401 | false | Missing or invalid user token |
| `forbidden` | 403 | false | User does not own the requested resource |
| `not_found` | 404 | false | Restaurant, upload, or publish job not found |
| `conflict` | 409 | false | Version conflict or slug conflict |
| `payload_too_large` | 413 | false | Body or asset metadata exceeds limit |
| `rate_limited` | 429 | true | Per-user or per-restaurant limit exceeded |
| `upstream_unavailable` | 502 | true | OpenAI, Supabase, or Cloudflare request failed |
| `service_unavailable` | 503 | true | Required backend dependency unavailable |
| `internal` | 500 | true | Unexpected backend failure |

## IDs And Ownership

- `restaurant_id` is a UUID owned by the authenticated user.
- `site_id` should equal `restaurant_id` for MVP unless the Data Architect approves a separate `sites` table.
- `upload_id` is backend-generated.
- `publish_id` is backend-generated for every publish or republish attempt.
- Writes should accept an optional `expected_version` to prevent overwriting stale iOS state.

## Endpoint Summary

| Capability | Method | Route | Auth | Current local equivalent |
| --- | --- | --- | --- | --- |
| Health | `GET` | `/health` | No | `/health` |
| Runtime config | `GET` | `/api/config` | Optional | None |
| Realtime session | `POST` | `/api/realtime/session` | Required in production | `/api/realtime/session` |
| Clean voice answer | `POST` | `/api/ai/cleanup-answer` | Required | None |
| Extract fields | `POST` | `/api/ai/extract-fields` | Required | `/api/extract/profile` |
| Voice coach | `POST` | `/api/ai/voice-coach` | Required | `/api/ai/coach-turn` |
| Generate draft | `POST` | `/api/ai/generate-draft` | Required | `/api/generate/draft` |
| Load restaurant | `GET` | `/api/restaurants/:id` | Required | None |
| Save restaurant | `POST` | `/api/restaurants/:id/save` | Required | None |
| Register upload | `POST` | `/api/uploads/register` | Required | None |
| Generate preview | `POST` | `/api/sites/:id/preview` | Required | Local in app |
| Publish site | `POST` | `/api/sites/:id/publish` | Required | `/api/publish/local` |
| Publish status | `GET` | `/api/sites/:id/publish-status` | Required | `/api/sites/:slug` |
| List local sites | `GET` | `/api/sites` | Local only | `/api/sites` |

## Endpoint Contracts

### `GET /health`

Purpose: verify the backend process is alive and report non-secret dependency status.

Response:

```json
{
  "ok": true,
  "service": "siteclaw-backend",
  "environment": "local",
  "version": "0.1.0",
  "dependencies": {
    "openai": "configured",
    "supabase": "not_configured",
    "cloudflare": "not_configured"
  }
}
```

### `GET /api/config`

Purpose: give the iOS app safe capability flags.

Response:

```json
{
  "ok": true,
  "data": {
    "environment": "staging",
    "auth_required": true,
    "features": {
      "realtime": true,
      "ai_cleanup": true,
      "uploads": true,
      "preview": true,
      "publish": true
    },
    "limits": {
      "max_json_body_bytes": 10000000,
      "max_upload_bytes": 25000000,
      "allowed_upload_mime_types": ["image/jpeg", "image/png", "application/pdf"]
    }
  }
}
```

### `POST /api/realtime/session`

Purpose: mint a short-lived OpenAI Realtime client secret without exposing the server API key.

Request:

```json
{
  "restaurant_id": "uuid",
  "restaurant_name": "Sunset Grill",
  "voice": "marin"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "client_secret": "ephemeral_secret",
    "expires_at": 1778880000,
    "model": "gpt-realtime",
    "transcription_model": "gpt-realtime-whisper",
    "voice": "marin"
  }
}
```

Validation:

- `restaurant_id` must belong to the authenticated user in production.
- `restaurant_name` is display context only and must be sanitized.

### `POST /api/ai/cleanup-answer`

Purpose: clean one raw voice answer while preserving owner meaning.

Request:

```json
{
  "restaurant_id": "uuid",
  "prompt_kind": "hours",
  "question": "When are you open?",
  "raw_answer": "um we are monday thru saturday ten to eight and sunday eleven to six",
  "captured_answers": [
    {
      "prompt_kind": "basics",
      "question": "What is your restaurant called?",
      "answer": "Sunset Grill"
    }
  ]
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "cleaned_answer": "We are open Monday through Saturday from 10 AM to 8 PM, and Sunday from 11 AM to 6 PM.",
    "confidence": "high",
    "removed_filler": true,
    "needs_review": false,
    "warnings": []
  }
}
```

Rules:

- Do not move facts into other fields.
- Do not invent missing facts.
- Mark `needs_review` when the answer is ambiguous.

### `POST /api/ai/extract-fields`

Purpose: extract a safe restaurant data patch from guided answers and transcript context.

Request:

```json
{
  "restaurant_id": "uuid",
  "transcript": "Full normalized transcript when available.",
  "captured_answers": [
    {
      "prompt_kind": "basics",
      "question": "What is your restaurant called?",
      "answer": "Sunset Grill"
    }
  ],
  "current_restaurant": {
    "name": "Sunset Grill",
    "cuisine": "American burgers and sandwiches",
    "neighborhood": "San Jose"
  }
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "reply": "I cleaned up the basics and found hours, location, and menu details for review.",
    "restaurant_patch": {
      "name": "Sunset Grill",
      "cuisine": "American burgers and sandwiches",
      "neighborhood": "San Jose",
      "hours": "Monday through Saturday 10 AM to 8 PM, Sunday 11 AM to 6 PM",
      "story": "",
      "menu_items": [
        {
          "name": "Cheeseburger",
          "description": "",
          "price": 12.99
        }
      ]
    },
    "field_confidence": {
      "name": "high",
      "hours": "medium",
      "menu_items": "medium"
    },
    "suggested_archetype": "neighborhood_utility",
    "needs_owner_review": true
  }
}
```

Compatibility:

- Current local alias: `POST /api/extract/profile`.
- Production route should accept the current Swift request shape while iOS migrates.

### `POST /api/ai/voice-coach`

Purpose: provide per-answer feedback and a safe patch for the native Voice Coach UI.

Request:

```json
{
  "restaurant_id": "uuid",
  "prompt_kind": "story",
  "question": "What makes your restaurant special?",
  "raw_answer": "fresh ingredients fast service friendly neighborhood atmosphere",
  "cleaned_answer": "Fresh ingredients, fast service, and a friendly neighborhood atmosphere.",
  "captured_answers": [],
  "transcript": "",
  "current_restaurant": {},
  "current_design_brief": {}
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "cleaned_answer": "Fresh ingredients, fast service, and a friendly neighborhood atmosphere.",
    "restaurant_patch": {
      "name": "",
      "cuisine": "",
      "neighborhood": "",
      "hours": "",
      "story": "Fresh ingredients, fast service, and a friendly neighborhood atmosphere.",
      "menu_items": []
    },
    "confidence": "high",
    "missing_details": [],
    "suggested_follow_up": "",
    "archetype_hint": "neighborhood_utility",
    "design_notes": [
      "Use friendly neighborhood language because the owner emphasized atmosphere."
    ],
    "status_message": "This answer is ready for review."
  }
}
```

Compatibility:

- Current local alias: `POST /api/ai/coach-turn`.

### `POST /api/ai/generate-draft`

Purpose: generate owner-facing website copy and a supported design brief from approved restaurant data.

Request:

```json
{
  "restaurant_id": "uuid",
  "transcript": "Normalized transcript",
  "restaurant": {},
  "draft": {},
  "restaurant_json": {},
  "site_strategy": {
    "design_decisions": [],
    "story_opportunities": [],
    "recommended_modules": [],
    "voice_coach_notes": []
  }
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "reply": "Draft generated.",
    "draft": {
      "headline": "Fresh Burgers in San Jose",
      "subheadline": "A friendly neighborhood grill for lunch, dinner, and easy takeout.",
      "call_to_action": "View Menu",
      "pages": ["Home", "Menu", "Hours", "Location"],
      "seo_keywords": ["burgers San Jose", "Sunset Grill"],
      "design_brief": {
        "archetype": "neighborhood_utility",
        "primary_cta": "View Menu",
        "secondary_ctas": ["Call Now", "Get Directions"],
        "section_order": ["hero", "menu", "visit"],
        "design_decisions": [],
        "story_opportunities": [],
        "recommended_modules": []
      },
      "last_generated_summary": "Created a neighborhood restaurant website draft."
    },
    "model": "gpt-5.4-mini",
    "source": "openai_responses"
  }
}
```

Compatibility:

- Current local alias: `POST /api/generate/draft`.

### `GET /api/restaurants/:id`

Purpose: load the authenticated owner's restaurant workspace.

Response:

```json
{
  "ok": true,
  "data": {
    "restaurant_id": "uuid",
    "owner_id": "uuid",
    "version": 7,
    "updated_at": "2026-05-15T18:00:00Z",
    "restaurant": {},
    "restaurant_json": {},
    "draft": {},
    "uploads": [],
    "publish": {
      "status": "draft",
      "site_url": null,
      "last_published_at": null
    }
  }
}
```

Authorization:

- Return `403 forbidden` if the restaurant is not owned by the user.

### `POST /api/restaurants/:id/save`

Purpose: persist owner-approved workspace changes.

Request:

```json
{
  "expected_version": 7,
  "source": "build_review",
  "restaurant": {},
  "restaurant_json": {},
  "draft": {},
  "changed_fields": ["hours", "menu.items"],
  "client_updated_at": "2026-05-15T18:01:00Z"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "restaurant_id": "uuid",
    "version": 8,
    "updated_at": "2026-05-15T18:01:03Z",
    "changed_fields": ["hours", "menu.items"],
    "needs_preview_refresh": true,
    "needs_republish": true
  }
}
```

Validation:

- Body must be valid JSON.
- `restaurant_json` must match the renderer contract before publish, but save may allow incomplete drafts.
- If `expected_version` is stale, return `409 conflict`.

### `POST /api/uploads/register`

Purpose: create metadata and upload instructions for menu PDFs, menu photos, dish photos, logos, and hero images.

Request:

```json
{
  "restaurant_id": "uuid",
  "asset_type": "menu_photo",
  "filename": "sunset-menu.png",
  "content_type": "image/png",
  "byte_count": 1842240,
  "sha256": "optional-client-hash"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "upload_id": "uuid",
    "storage_bucket": "restaurant-data",
    "storage_path": "uuid/uploads/menu_photo/upload_id-sunset-menu.png",
    "upload_url": "signed_upload_url",
    "expires_at": "2026-05-15T18:10:00Z",
    "public_render_url": null,
    "status": "registered"
  }
}
```

Rules:

- Allowed `asset_type`: `menu_pdf`, `menu_photo`, `dish_photo`, `logo`, `hero_image`, `gallery_image`.
- Validate MIME type and byte limit before signing.
- Owner can register uploads only under their own restaurant path.
- The backend records upload metadata before returning a signed URL.

### `POST /api/sites/:id/preview`

Purpose: generate a preview artifact from the current `restaurant.json`.

Request:

```json
{
  "expected_version": 8,
  "restaurant_json": {},
  "mode": "owner_preview"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "site_id": "uuid",
    "preview_id": "uuid",
    "preview_url": "https://staging-api.siteclaw.com/previews/uuid",
    "artifact": {
      "html_bytes": 248211,
      "restaurant_json_bytes": 18224
    },
    "generated_at": "2026-05-15T18:02:00Z",
    "expires_at": "2026-05-22T18:02:00Z"
  }
}
```

Notes:

- The iOS native preview may remain local for MVP.
- This endpoint becomes required when preview must match Cloudflare output exactly.

### `POST /api/sites/:id/publish`

Purpose: publish or republish an approved restaurant site.

Request:

```json
{
  "expected_version": 8,
  "requested_slug": "sunset-grill",
  "mode": "publish",
  "owner_approved": true,
  "preview_artifact_hash": "sha256:optional-known-preview-hash"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "publish_id": "uuid",
    "site_id": "uuid",
    "restaurant_id": "uuid",
    "status": "queued",
    "slug": "sunset-grill",
    "site_url": "https://sunset-grill.siteclaw.app",
    "preview_artifact_hash": "sha256:...",
    "status_url": "/api/sites/uuid/publish-status",
    "queued_at": "2026-05-15T18:03:00Z"
  }
}
```

Validation:

- `owner_approved` must be `true`.
- Backend renders from the stored, owner-scoped `restaurant.json`; production publish must not trust client-supplied HTML.
- `restaurant.json` must pass renderer-contract validation.
- Slug must be lowercase, URL-safe, and unique.
- Generated HTML must reject active script injection unless explicitly approved by the Publishing and QA/Security agents.
- If `preview_artifact_hash` is provided, backend must compare it to the artifact being published and reject stale preview approval.

Local behavior:

- Current local alias: `POST /api/publish/local`.
- Local response may include filesystem paths for proofing.
- Production responses must not expose server filesystem paths.

### `GET /api/sites/:id/publish-status`

Purpose: let iOS poll publish progress and display useful failure states.

Response:

```json
{
  "ok": true,
  "data": {
    "site_id": "uuid",
    "restaurant_id": "uuid",
    "latest_publish_id": "uuid",
    "status": "live",
    "site_url": "https://sunset-grill.siteclaw.app",
    "slug": "sunset-grill",
    "published_artifact_hash": "sha256:...",
    "last_published_at": "2026-05-15T18:05:00Z",
    "error": null,
    "history": [
      {
        "publish_id": "uuid",
        "status": "live",
        "started_at": "2026-05-15T18:03:00Z",
        "finished_at": "2026-05-15T18:05:00Z"
      }
    ]
  }
}
```

Allowed status values:

- `draft`
- `preview_ready`
- `queued`
- `rendering`
- `uploading`
- `verifying`
- `live`
- `needs_republish`
- `failed`
- `cancelled`

Failure shape:

```json
{
  "publish_id": "uuid",
  "status": "failed",
  "error": {
    "code": "cloudflare_build_failed",
    "message": "Publishing failed. Please try again.",
    "retryable": true
  }
}
```

## Environment Variables

Required for local demo:

```env
OPENAI_API_KEY=
PORT=8787
SITECLAW_HOST=127.0.0.1
SITECLAW_ALLOWED_ORIGIN=*
```

Required for authenticated production:

```env
NODE_ENV=production
SITECLAW_API_BASE_URL=https://api.siteclaw.com
SITECLAW_ALLOWED_ORIGIN=siteclaw-ios
OPENAI_API_KEY=
OPENAI_REALTIME_MODEL=gpt-realtime
OPENAI_REALTIME_TRANSCRIPTION_MODEL=gpt-realtime-whisper
OPENAI_GENERATION_MODEL=gpt-5.4-mini
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_JWKS_URL=
CLOUDFLARE_ACCOUNT_ID=
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ZONE_ID=
CLOUDFLARE_SITE_DOMAIN=siteclaw.app
CLOUDFLARE_PAGES_PROJECT_PREFIX=siteclaw-
```

Startup validation:

- Production boot must fail if required secrets are missing.
- Local boot may warn for missing Supabase or Cloudflare values.
- Health must report configured or not configured, never secret values.

## Local Versus Production Behavior

| Area | Local demo | Production |
| --- | --- | --- |
| Auth | Optional | Required Supabase JWT |
| Restaurant storage | In-memory app state and generated local files | Supabase Postgres and Storage |
| OpenAI calls | Backend server key | Backend server key |
| Uploads | Local app file/data URLs | Supabase Storage signed upload |
| Preview | Native/local generated preview | Renderer-matched preview artifact |
| Publish | Writes `Backend/generated-sites/:slug` | Cloudflare Pages Direct Upload project per restaurant |
| Publish status | Reads local generated site summary | Publish job status and history |
| Errors | Existing string errors tolerated | Structured error object required |

## Compatibility Migration Plan

1. Keep current local endpoints available:
   - `/api/realtime/session`
   - `/api/generate/draft`
   - `/api/extract/profile`
   - `/api/ai/coach-turn`
   - `/api/publish/local`
   - `/api/sites`
2. Add production route aliases with the contracts in this document.
3. Update Swift service clients to decode structured errors while tolerating old local error strings.
4. Add auth middleware behind an environment flag.
5. Wire Supabase load/save and upload registration after the Data Architect finalizes schema and storage paths.
6. Wire Cloudflare publish after the Publishing Engineer finalizes slug, artifact, and status behavior.

## Validation Requirements

Backend implementation should include:

- JSON body size limit
- Route-specific required-field checks
- UUID validation for route params
- Ownership checks before any restaurant read/write
- MIME and byte limit checks for uploads
- Safe HTML checks before publish
- Structured logging with request IDs
- No raw transcript or secret values in logs

## Verification For First Implementation Pass

Minimum checks:

```bash
node --check Backend/server.mjs
git diff --check
curl http://localhost:8787/health
```

Route-level checks should be added once production aliases exist:

- unauthenticated request returns `401 unauthorized`
- invalid restaurant id returns `400 bad_request`
- wrong owner returns `403 forbidden`
- stale `expected_version` returns `409 conflict`
- missing OpenAI key returns structured `500 internal` or `503 service_unavailable`
- publish with unsafe HTML returns `400 bad_request`

## Cross-Agent Dependencies

Data/Supabase Architect:

- Confirm table names, version fields, RLS policies, storage buckets, and upload path shape.

AI Voice Pipeline Engineer:

- Confirm cleanup and extraction eval output fields, especially confidence and follow-up behavior.

Web Renderer/Publishing Engineer:

- Confirm preview artifact generation, Cloudflare publish trigger, slug uniqueness, and publish status states.

iOS Product Engineer:

- Confirm Swift request/response model names and migration timing for route aliases and structured errors.

QA/Security:

- Validate auth boundaries, upload safety, transcript handling, publish safety, and secret hygiene.

## Open Decisions

- Whether `site_id` remains equal to `restaurant_id` for all founding beta sites.
- Whether preview artifacts are backend-rendered in Sprint 1 or remain native/local until Cloudflare publish is wired.
- Whether raw transcripts are stored by default or only cleaned answers plus extraction metadata are persisted.
- Whether local auth-bypass should use a fixed development user id or require a signed local Supabase token.
