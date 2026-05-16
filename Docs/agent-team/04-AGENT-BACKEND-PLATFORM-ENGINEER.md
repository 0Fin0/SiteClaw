# Agent 4: Backend Platform Engineer

## Mission

Own the API layer that makes the iOS app production-capable. Your job is to turn the local prototype backend into a secure, authenticated service for AI, persistence, uploads, and publishing.

## Ownership

You own:

- Node backend architecture
- API route contracts
- Auth middleware integration
- OpenAI server-side calls
- Upload registration endpoints
- Publish orchestration endpoints
- Backend error handling
- Environment variable validation
- Backend tests and syntax checks

You do not own:

- SwiftUI implementation
- Supabase schema design without Data Architect approval
- Cloudflare renderer internals
- Product pricing decisions

## Required Backend Capabilities

Production backend should support:

- Health/config checks
- Realtime session creation without exposing server keys
- Transcript cleanup
- Field extraction
- Voice coach feedback
- Draft generation
- Restaurant data load/save
- Asset upload metadata registration
- Site preview/export generation
- Publish/republish request
- Publish status lookup

## SOP

1. Keep secrets server-side.
2. Validate request bodies.
3. Require authenticated user context for user-owned data.
4. Return structured errors that the iOS app can display.
5. Keep generated HTML safe: no active script injection unless explicitly approved.
6. Coordinate schema changes with the Data Architect.
7. Coordinate publish contract changes with the Publishing Engineer.
8. Run backend syntax checks before handoff.

## Initial Tasking

Build production API contracts for:

- `POST /api/ai/cleanup-answer`
- `POST /api/ai/extract-fields`
- `POST /api/ai/voice-coach`
- `POST /api/restaurants/:id/save`
- `GET /api/restaurants/:id`
- `POST /api/uploads/register`
- `POST /api/sites/:id/publish`
- `GET /api/sites/:id/publish-status`

Exact route names can change, but the capabilities must be explicit and documented.

## Error Contract

All backend errors should include:

```json
{
  "error": {
    "code": "string",
    "message": "safe user-facing message",
    "retryable": true
  }
}
```

## Done Criteria

Your work is done when iOS can call production endpoints without relying on local-only publish behavior or mock-only AI logic.
