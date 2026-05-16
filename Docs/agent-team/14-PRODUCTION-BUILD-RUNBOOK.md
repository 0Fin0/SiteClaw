# SiteClaw Production Build Runbook

## Goal

This runbook turns the current iOS MVP into a production pilot system with real accounts, persisted restaurant data, AI cleanup, menu upload, preview, and live publishing.

## Branching

Use a working or feature branch for production changes. Keep `main` releasable.

Recommended pattern:

- `SiteClaw_Working` for integrated production work
- Short-lived feature branches for risky changes
- Merge only after QA/Security gate

## System Overview

Production V1 components:

- iOS app: owner-facing product
- Node backend: authenticated API and AI gateway
- Supabase Auth: user identity
- Supabase Postgres: restaurant/business records
- Supabase Storage: uploaded menus, dish photos, generated assets
- OpenAI: voice transcription, cleanup, extraction, coaching, draft generation
- Cloudflare: live static restaurant sites
- `restaurant.json`: renderer contract

## Build Sequence

### Step 1: Environment And Secrets

Owners:

- Backend Platform Engineer
- Data/Supabase Architect
- QA/Security

Tasks:

- Define required environment variables.
- Add `.env.example` updates.
- Add startup validation for missing required secrets.
- Document local, staging, and production environments.

Done when:

- Backend can fail clearly when secrets are missing.
- No secret values are committed.

### Step 2: Supabase Foundation

Owner:

- Data/Supabase Architect

Tasks:

- Create tables.
- Enable RLS.
- Create storage buckets.
- Define upload paths.
- Define migration order.
- Generate or document app/backend types.

Done when:

- Authenticated owner can only access owned restaurant data.
- Backend service role can perform trusted server operations.

### Step 3: Backend API Contracts

Owner:

- Backend Platform Engineer

Tasks:

- Define route names and request/response shapes.
- Add auth middleware.
- Add structured error response.
- Expose restaurant load/save.
- Expose AI cleanup/extraction.
- Expose upload registration.
- Expose publish endpoints.

Done when:

- iOS can integrate against documented contracts.
- Tests or route-level verification exist.

### Step 4: AI Cleanup And Extraction

Owner:

- AI Voice Pipeline Engineer

Tasks:

- Create eval cases.
- Implement cleanup prompt.
- Implement extraction prompt.
- Add confidence/status output.
- Add targeted follow-up behavior.
- Prevent cross-field contamination.

Done when:

- Known messy speech cases pass evals.
- Uncertain answers are marked for review.

### Step 5: iOS Production Integration

Owner:

- iOS Product Engineer

Tasks:

- Replace mock login with auth.
- Add session-aware app state.
- Load/save restaurant data.
- Register/display uploaded assets.
- Show backend AI results.
- Show publish status.
- Preserve existing Talk -> Build -> Preview flow.

Done when:

- Owner can leave and return without losing restaurant state.
- No production path depends on local-only mock state.

### Step 6: Renderer And Publishing

Owner:

- Web Renderer/Publishing Engineer

Tasks:

- Define slug/subdomain rules.
- Generate static site artifact from `restaurant.json`.
- Trigger Cloudflare publish.
- Store publish status.
- Support retry.
- Confirm preview/publish parity.

Done when:

- Restaurant can publish to a live HTTPS SiteClaw subdomain.
- Republish updates the live site.

### Step 7: QA, Security, And Pilot Launch

Owners:

- QA/Security
- Growth/Customer Ops

Tasks:

- Run test gate.
- Run security scan.
- Run manual smoke test.
- Onboard first restaurant.
- Track issues and feedback.

Done when:

- First restaurant is live.
- Bugs are triaged into launch blockers and follow-ups.

## Required API Capabilities

The exact route names can change, but production must support:

- Create realtime/transcription session
- Clean voice answer
- Extract structured fields
- Generate voice coach feedback
- Load restaurant workspace
- Save restaurant workspace
- Register uploaded menu/dish asset
- Generate preview artifact
- Publish site
- Get publish status
- Republish site

## Standard Error Shape

```json
{
  "error": {
    "code": "string",
    "message": "safe user-facing message",
    "retryable": true
  }
}
```

## Release Gate

Before release:

- `git diff --check`
- Backend syntax check
- Unit tests
- iOS simulator build
- Security scan
- Manual smoke test

Manual smoke test:

- Sign up
- Log in
- Complete Talk intake
- Edit Build fields
- Upload menu
- Preview
- Publish
- Open live site
- Republish changed data
- Log out and log back in

## Rollback Plan

If a production issue occurs:

- Disable publish endpoint if live publishing is unsafe.
- Keep existing live restaurant sites online when possible.
- Roll back backend deploy.
- Restore prior `restaurant.json` from publish history.
- Notify affected customers directly.

## Documentation Requirements

Every production change that affects another agent must update:

- API contract docs
- Schema/storage docs
- App integration notes
- QA checklist when verification changes
