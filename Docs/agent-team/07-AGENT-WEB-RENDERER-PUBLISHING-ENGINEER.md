# Agent 7: Web Renderer And Publishing Engineer

## Mission

Own the generated restaurant websites and the live publishing path. Your job is to make preview and published output match, look professional, and deploy reliably.

## Ownership

You own:

- Generated restaurant site renderer
- HTML/CSS output quality
- Mobile responsiveness
- SEO metadata and structured data
- Uploaded menu display on public sites
- Cloudflare publishing integration
- Subdomain generation
- Publish status and retry behavior
- Custom-domain technical plan

You do not own:

- iOS screen implementation
- AI extraction
- Supabase schema without Data Architect coordination
- Pricing decisions

## Product Standard

The generated site must feel real enough that a restaurant owner would send it to customers.

Minimum public site sections:

- Hero with restaurant name, cuisine, and CTA
- Featured dishes
- Full uploaded menu when present
- Hours
- Address and phone
- Call, Directions, View Menu CTAs
- Owner story/about
- Find Us Online links when provided
- SEO and Restaurant schema

## SOP

1. Treat `restaurant.json` as the renderer contract.
2. Do not invent missing facts.
3. Hide unavailable CTAs instead of rendering dead controls.
4. Keep mobile quality first.
5. Ensure Preview uses the same output as Publish.
6. Record publish status and errors.
7. Coordinate Cloudflare secrets and domain settings with Backend and QA/Security.

## Initial Tasking

Build the live publishing plan:

- SiteClaw subdomain format
- Slug rules
- Cloudflare project setup
- Publish request contract
- Publish status model
- Retry behavior
- Generated artifact storage
- Custom-domain roadmap

## Publishing Work Completed

- Production publishing should use the same generated artifact for Preview and Publish. The renderer takes the latest approved `restaurant.json`, renders a static artifact bundle, stores an artifact hash, and publishes that exact bundle.
- Founding beta URL format: `https://{slug}.siteclaw.app`.
- Use Cloudflare Pages Direct Upload for founding beta publishing, with one Cloudflare Pages project per restaurant: `siteclaw-{slug}`. This avoids one shared Pages project overwriting every restaurant site when a different `RESTAURANT_ID` is built.
- Cloudflare zone setup:
  - Own `siteclaw.app` in Cloudflare.
  - Backend service token can create/read Pages projects, upload deployments, attach custom domains, and read deployment status.
  - Each restaurant project gets the custom domain `{slug}.siteclaw.app`.
  - Keep a reserved fallback URL from Cloudflare Pages for debugging, but only show the SiteClaw subdomain to owners.
- Slug/subdomain rules:
  - Start from the owner-approved restaurant display name or requested slug.
  - Normalize to lowercase ASCII, replace non-alphanumeric runs with `-`, trim leading/trailing `-`, collapse repeated dashes.
  - Allowed length: 3 to 50 characters.
  - Reserved slugs include `www`, `api`, `admin`, `app`, `assets`, `docs`, `help`, `mail`, `preview`, `status`, `support`, `test`, and `siteclaw`.
  - If taken, append `-2`, `-3`, etc. The backend owns uniqueness checks.
  - A live slug is stable. Slug changes after first publish require team review and a redirect plan.
- Production publish request:

```http
POST /api/sites/:site_id/publish
Authorization: Bearer <supabase-session>
Content-Type: application/json
```

```json
{
  "owner_approved": true,
  "requested_slug": "sunset-grill",
  "restaurant_json_version": 7,
  "preview_artifact_hash": "sha256:optional-known-preview-hash"
}
```

- Production publish response:

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

- Retry request:

```http
POST /api/sites/:site_id/publish/:publish_id/retry
Authorization: Bearer <supabase-session>
```

- Backend must render from stored restaurant data, not client-supplied HTML. The iOS app may send the last preview hash to detect preview/publish drift, but the backend is source of truth.

## Renderer Contract Changes

- `restaurant.json` remains the renderer contract. Publish must fail before Cloudflare upload if the JSON is invalid or missing required customer-facing facts.
- Required for first live publish: `restaurant_id`, `schema_version`, `basics.name`, at least one menu category or uploaded menu, hours, and enough contact/location information to be useful.
- Optional facts render only when present:
  - Phone renders only if provided.
  - Directions/map CTA renders only if address or map URL exists.
  - Order/reservation/gift-card/catering CTAs render only if URLs exist.
  - Social links render only if URLs exist.
  - Uploaded menu renders when present and readable; otherwise the renderer falls back to structured menu items.
- SEO output must include title, description, canonical URL, Open Graph metadata, and Restaurant JSON-LD using only available facts.
- Artifact bundle contents:
  - `index.html`
  - static CSS/assets
  - `restaurant.json` copy used for the build
  - `artifact-manifest.json` containing renderer version, restaurant JSON version, artifact hash, slug, generated timestamp, and included asset paths

## Publish States

- `draft`: restaurant data exists but no valid preview artifact.
- `preview_ready`: renderer produced a publishable artifact.
- `queued`: publish job accepted.
- `rendering`: backend is rendering or re-rendering the artifact.
- `uploading`: artifact is being uploaded to Cloudflare Pages.
- `verifying`: backend is checking the live HTTPS URL, status code, and artifact hash marker.
- `live`: latest approved artifact is live.
- `needs_republish`: restaurant data changed after the last live artifact.
- `failed`: publish failed with a safe owner-facing error and internal diagnostic code.
- `cancelled`: superseded by a newer publish job or cancelled by team/admin action.

Failure payload:

```json
{
  "code": "cloudflare_upload_failed",
  "message": "Publishing failed. Please try again.",
  "retryable": true,
  "attempt": 1
}
```

Retry behavior:

- Existing live site remains live until the new deployment verifies successfully.
- Retry only when `retryable` is true.
- Retry reuses the same restaurant JSON version and requested slug unless the owner/team starts a new publish.
- Automatic retry: up to 2 backend attempts for transient Cloudflare/network failures with short exponential backoff.
- Manual retry: owner can retry failed jobs from iOS; backend caps manual retries at 3 per publish job before requiring team review.
- Republish creates a new publish job from the latest approved `restaurant.json`.

## Verification

- Preview/publish parity:
  - Preview generation and publish generation call the same renderer entrypoint.
  - Store and compare `preview_artifact_hash` and `published_artifact_hash`.
  - Publish warns or blocks if owner-approved preview hash differs from the artifact being uploaded.
- Live verification after upload:
  - Fetch `https://{slug}.siteclaw.app/`.
  - Require HTTP 200.
  - Confirm canonical URL matches the SiteClaw subdomain.
  - Confirm artifact hash marker from `artifact-manifest.json` or a build meta tag.
  - Confirm mobile viewport smoke check for hero, menu/uploaded menu, hours, and primary CTA.
- Renderer checks:
  - No placeholder phone/address/hours copy.
  - No unavailable CTA links.
  - Uploaded menu is readable on mobile.
  - Restaurant JSON-LD validates with available facts.

## Risks

- Existing engineering docs mention `siteclaw.com`; current app and renderer output use `siteclaw.app`. Production contracts should standardize on `siteclaw.app`.
- One shared Pages project with build-time `RESTAURANT_ID` is unsafe for multiple restaurants because each deployment can replace the prior restaurant site.
- Cloudflare custom domain provisioning may be asynchronous; iOS must show `verifying` or `queued` instead of pretending the site is live early.
- Uploaded PDFs/images can be large or low-quality. Renderer should cap file size and show a structured menu fallback when the upload is not public-site quality.
- Slug changes after publish can break QR codes, Google Business Profile links, and owner-shared URLs.

## Backend/iOS Dependencies

- Backend:
  - Own authenticated publish, status, retry, slug reservation, Cloudflare token usage, and status persistence.
  - Store publish records with `publish_id`, `site_id`, `restaurant_id`, slug, restaurant JSON version, preview hash, published hash, status, error, attempt count, deployment ID, live URL, timestamps.
  - Generate renderer artifacts server-side from stored restaurant data; never trust client HTML for production publish.
  - Keep Cloudflare API token backend-only.
- iOS:
  - Show `draft`, `preview_ready`, `queued`, `rendering`, `uploading`, `verifying`, `live`, `needs_republish`, `failed`, and `cancelled`.
  - Disable Publish until required renderer facts pass.
  - Send owner approval and optional requested slug.
  - Poll publish status and show retry only when `retryable` is true.
  - Mark the site `needs_republish` whenever owner-approved restaurant details change after a live publish.

## Acceptance Criteria

- Published site loads over HTTPS.
- Owner can republish changed restaurant details.
- Preview and published site do not diverge.
- Uploaded menu is readable on mobile.
- Structured data includes name, cuisine, address, phone, hours, and sameAs links when available.

## Done Criteria

Your work is done when a founding restaurant can get a live SiteClaw URL that looks customer-ready and can be republished safely.
