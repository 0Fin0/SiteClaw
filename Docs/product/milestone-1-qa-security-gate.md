# Milestone 1 QA/Security Gate

Owner: Agent 09 - QA Security

Last updated: May 16, 2026

## Purpose

This gate defines the release quality, regression, privacy, and security checks required before SiteClaw Milestone 1 can be approved.

Milestone 1 currently covers the iOS-first demo flow:

- Mock login and local workspace persistence
- Talk guided voice capture
- Website Details correction flow
- Menu upload and featured dish image handling
- Native Preview and fullscreen preview
- Review & Publish proof flow
- Local backend publish to static generated sites
- Local generated website at `http://localhost:8787/sites/{slug}/`

Current app auth scope: local mock auth only. Supabase auth, OAuth, Stripe, production billing, and production RLS are not live in the iOS demo unless a future branch adds them. Agent 6's Supabase foundation is still in audit scope for Milestone 1 planning, and the Agent 6 Audit Contract below defines what QA/Security will test before any production or founding-beta data path is approved.

## Release Blocking Rule

Block release if any Critical or High issue remains in these areas:

- Auth or ownership boundary failure
- Cross-owner data access
- Secret exposure
- PII or uploaded owner data leaked to public output unintentionally
- Unsafe upload handling that can crash the app, execute code, or escape the workspace
- Unsafe generated HTML, including script injection, event handlers, or `javascript:` links
- Publish flow writing outside the expected local generated-site directory
- A broken golden path: Talk -> Website Details -> Preview -> Review & Publish -> Open Site

The CEO may explicitly accept Medium or Low residual risk. Critical and High release blockers should be fixed before release unless the CEO records an explicit exception with rationale.

## Agent 6 Audit Contract

Agent 6's Supabase/data work is audited against these exact surfaces:

- Every app table must have a clear owner isolation story:
  - `restaurants`
  - `restaurant_profiles`
  - `voice_answers`
  - `generated_drafts`
  - `uploaded_assets`
  - `publish_records`
  - `edit_history`
  - `subscriptions`
- RLS must be enabled on every app table before production use.
- Owner A must not read, insert, update, delete, publish, or list Owner B's restaurant data.
- Backend/service-role access may bypass RLS only server-side.
- No service-role key may appear in iOS code, docs with real values, generated sites, screenshots, or client config.
- Storage buckets must match the intended access model:
  - `restaurant-data`: private `restaurant.json` only
  - `restaurant-uploads`: private menu and dish uploads
  - `published-assets`: public only for approved publish artifacts
- Storage paths must include owner and restaurant boundaries:
  - private data: `{owner_id}/{restaurant_id}/restaurant.json`
  - private uploads: `{owner_id}/{restaurant_id}/uploads/{asset_id}...`
  - public assets: publish-approved paths only
- Publishing must expose only approved public restaurant content, never raw transcript, private notes, secrets, local file paths, or backend error traces.

## SOP

1. Review changed files before testing.
2. Run automated checks.
3. Run manual smoke tests for affected flows.
4. Scan for secrets and PII exposure.
5. Validate auth and ownership boundaries.
6. Report findings by severity.
7. Block release on critical auth, data, upload, or publish issues.

## Severity Guide

Critical:
Compromises secrets, owner data, auth boundaries, publish integrity, or allows executable content injection.

High:
Breaks the core demo path, loses owner-entered data, publishes wrong restaurant data, accepts unsafe upload content, or opens external links unsafely.

Medium:
Creates confusing UX, partial regressions, accessibility failures on important controls, stale preview/publish mismatch, or non-blocking validation gaps.

Low:
Copy, polish, minor layout, or documentation issues that do not affect release safety or the golden path.

## Test Checklist

Changed files review:

- Review `git status --short --untracked-files=all` before testing.
- Review `git diff --stat` and `git diff --name-only`.
- Confirm all intended app assets are inside the project folder before commit, especially:
  - `SiteClaw/Resources/sunset-grill-demo-menu.png`
  - `SiteClaw/Resources/DemoDishPhotos/*.png`
  - `SiteClaw/Assets.xcassets/SiteClawLogo.imageset/*`
  - `SiteClaw/Assets.xcassets/AppIcon.appiconset/*`
- Confirm no local generated demo state is committed unless intentionally approved:
  - `Backend/generated-sites/`
  - Simulator-derived temporary files
  - Local screenshots unless they are part of docs

Automated checks:

- Run backend syntax check:

```bash
/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs
```

- Run whitespace/conflict check:

```bash
git diff --check
```

- Run macOS unit tests when available:

```bash
xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS'
```

- Run iOS simulator build/run through XcodeBuildMCP on iPhone 17 Pro:
  - Confirm the active project, scheme, and simulator defaults first.
  - Then run `build_run_sim`.
- Record current iOS test limitation if still present:
  - XcodeBuildMCP `test_sim` has previously failed before tests run because the `SiteClaw iOS` scheme is not configured for `test-without-building`.
  - This is not the same as a failing unit test. Treat it as a scheme configuration gap and keep macOS unit tests plus iOS build/run verification as the Milestone 1 fallback.

Backend route checks:

- Start backend:

```bash
/Applications/Codex.app/Contents/Resources/node Backend/server.mjs
```

- Verify health:

```bash
curl http://localhost:8787/health
```

- After publishing from the app, verify:
  - `GET /sites/sunset-grill/` serves customer-facing HTML.
  - `GET /api/sites` lists the local generated site registry.
  - `GET /api/sites/sunset-grill` returns the generated site record when present.

Core regression checks:

- Talk prompt parsing still fills Restaurant Basics, hours, menu items, and owner story.
- `Save Answer` remains the customer-facing Talk action label.
- Review Captured Answers and transcript remain available but collapsed by default.
- Website Details sections render in the expected order:
  1. Restaurant Basics
  2. Use Your Existing Menu
  3. Featured Dishes
  4. Choose Website Style
  5. Contact & Visibility
  6. Growth Toolkit
- Use Your Existing Menu prioritizes Upload File and Use Photo over Demo Menu.
- Contact & Visibility keeps checklist progress collapsed by default.
- Conversion/customer action link UI remains hidden or deferred unless intentionally reintroduced.
- Preview shows owner safety status before publish.
- Fullscreen preview opens and dismisses cleanly.
- Review & Publish shows What happens next, Get Found on Google, Publish or Share, privacy reassurance, and proof tools.
- Generated site has no redundant top Location/Hours/Menu fact strip.
- Generated site Visit Us section remains the single address/hours presentation.
- Generated site Hours nav anchors to the Visit Us hours card.

## Security Checklist

Secrets:

- No real API key, bearer token, Supabase service role key, private key, OAuth secret, Stripe key, or personal credential is present in tracked code, docs, generated HTML, screenshots, or JSON fixtures.
- `Backend/.env` may exist locally, but must remain untracked.
- `Backend/.env.example` may contain placeholder names only.
- The iOS app must not contain server-only keys. If Supabase is added later, the app may only contain public anon keys.

Generated HTML safety:

- Generated HTML must pass existing safety checks, including `isSafeGeneratedHTML`.
- Generated site output must not include arbitrary `<script>` tags, event handler attributes, unsafe inline JS, or `javascript:` URLs.
- JSON-LD, if rendered, must be controlled and escaped.
- Owner-provided text must be escaped before insertion into HTML.
- Menu item names, descriptions, prices, uploaded filenames, alt text, cuisine, address, and owner story must not break markup.
- External profile and customer links must be sanitized to accepted schemes only:
  - `http`
  - `https`
  - `mailto`
  - `tel`
- Invalid URLs should be omitted or blocked by quality audit rather than rendered as broken or unsafe links.

Publish safety:

- Local publish writes only under the expected generated-site storage area.
- Slugs must not allow path traversal, absolute paths, hidden directories, or shell-like path expansion.
- Republish should overwrite/update only the intended generated site.
- Generated `restaurant.json` should contain expected public restaurant fields only.
- Generated output should not expose raw transcripts, debug model output, private notes, local file paths, or API error traces.

Privacy:

- Raw voice transcript stays inside the app/workspace review UI and should not be emitted to public generated HTML.
- Uploaded menu and dish image data may be included in generated public output only when the user chooses to preview/publish that restaurant website.
- Demo privacy copy must accurately state that uploaded menu and restaurant details stay in the local demo workspace.
- Logs and UI should avoid exposing sensitive owner data beyond what is needed for local debug and demo.

External links:

- `Find us online` links in Review & Publish and generated websites must open intended external URLs directly.
- Link labels should not imply review incentives, discounts, or policy-unsafe behavior.
- Google review and Yelp copy should remain compliance-safe.

Dependencies and network:

- No new package, binary, or remote script should be added without review.
- Backend AI endpoints must fail gracefully if `OPENAI_API_KEY` is missing or network access is unavailable.
- The app must remain useful through local parsing when AI polish/coach calls fail.

Codex Security scans:

- For each release candidate, Agent 09 must run a diff-scoped Codex Security scan against changed code and sensitive supporting files.
- For the first production/Supabase release, Agent 09 must run repository-wide coverage over auth, RLS, storage, uploads, publish, generated HTML, backend secrets, and public artifacts.
- Findings must use the Agent 09 handoff format in this document.
- Any surviving Critical or High Codex Security finding blocks release.

## Secret Scan Checklist

Run before release and before any commit/push:

```bash
git status --short --untracked-files=all
git diff --name-only
git diff --cached --name-only
```

Search sensitive terms in tracked and newly staged files:

```bash
rg -n --hidden --glob '!Backend/.env' --glob '!Backend/generated-sites/**' --glob '!.git/**' 'OPENAI_API_KEY|sk-[A-Za-z0-9]|xox[baprs]-|gh[pousr]_|SUPABASE|SERVICE_ROLE|STRIPE|Bearer |PRIVATE KEY|password|secret|token'
```

Review any hits manually. Placeholders are acceptable only when clearly fake, documented, and not usable.

Required secret-scan decisions:

- `Backend/.env` exists locally: allowed only if untracked.
- Real API key in docs or generated site: release blocker.
- Real key in git history: stop release and rotate key.
- Service role key in iOS code: release blocker.
- User PII in generated public demo output beyond restaurant public details: release blocker until removed or explicitly approved.

## Auth/RLS Test Cases

Milestone 1 current state:

- Mock login only.
- No production Supabase auth.
- No production RLS enforcement.
- No production multi-tenant backend.

Current-state checks:

- Continue with Demo signs into local mock account.
- Sign out returns to login.
- Local workspace reloads only when a saved account is marked signed in.
- Reset demo data does not leave stale published/private data in the active app state.
- Account Settings copy does not imply real billing, real auth, or real production account protection.
- Local publish remains a demo proof flow, not a production deployment claim.

Future Supabase/RLS blocking tests:

- Owner A cannot select Owner B rows across every app table.
- Owner A cannot insert rows using Owner B's `owner_id`.
- Owner A cannot update, delete, publish, or list Owner B sites.
- Owner A cannot attach uploads to Owner B's restaurant.
- Owner A cannot read Owner B uploaded menus or dish photos.
- Owner A cannot read or write files in Owner B storage paths.
- Authenticated owners cannot write directly to `published-assets` unless an approved publish path/role explicitly allows it.
- Anonymous users cannot access private restaurant data or uploads.
- Generated-site records and publish records are scoped to the owning account/workspace.
- Publish endpoint requires an authenticated owner session or trusted backend service role.
- Backend does not trust client-supplied owner IDs without server validation.
- Supabase service role key is never shipped to iOS or public client config.
- RLS policies deny by default.
- Expired sessions are blocked from mutation routes.
- Logout clears local access to private workspace data.
- Public generated site routes expose only intentionally published public content.

If Supabase/RLS lands before Milestone 1 release, these tests are mandatory and release-blocking.

## Upload Safety Checks

Menu upload:

- Accept expected menu image/PDF content types only.
- Reject or ignore unsupported executable/content types such as HTML, JS, SVG, shell scripts, archives, or arbitrary binaries.
- Large uploads should not crash the app, freeze the UI, or create unusable generated HTML.
- Invalid or non-extractable menus should preserve existing owner-entered menu details and show recoverable state.
- Fullscreen uploaded menu preview should not be clipped, squished, or distorted at the bottom.
- Uploaded menu image should render within safe bounds on iPhone 17 Pro and larger Dynamic Type.
- Public JSON/HTML must not leak raw local file paths.

Featured dish images:

- Photo import stores image data in app state without raw local file paths in public JSON.
- `restaurant.json` exports dish `image_url` data URLs only when image data exists.
- Generated site renders dish images in menu cards without breaking layout.
- Missing dish image should fall back to normal menu card layout.
- Dish image alt text should be safe owner/menu text, not local file paths.

File handling:

- Security-scoped file URLs should be accessed only for the needed read duration.
- File import should not write outside app-controlled storage or project-approved demo resources.
- Demo resources committed to the repo should be intentionally staged and small enough for Git.

Release blocker examples:

- Uploading a menu can execute code in generated HTML.
- Uploading a file can make publish write outside the generated-site directory.
- A malformed upload crashes the golden path.
- A local absolute file path appears in public generated HTML or JSON.

## Manual Smoke Test Script

Setup:

1. Start backend with `/Applications/Codex.app/Contents/Resources/node Backend/server.mjs`.
2. Confirm `curl http://localhost:8787/health` returns healthy.
3. Build/run iOS app on iPhone 17 Pro simulator.
4. Tap `Continue with Demo`.

Talk:

1. Confirm first viewport shows a guided active question, voice controls, and no large always-visible transcript block.
2. Answer each prompt using the Sunset Grill script.
3. Tap `Save Answer` after each answer.
4. Confirm captured answers update and transcript remains available under collapsed review UI.
5. Tap `Continue to Build`.

Website Details:

1. Confirm navigation title says `Website Details`.
2. Confirm section order matches the Test Checklist.
3. Open Restaurant Basics and verify name, cuisine, location, and owner story.
4. Open Use Your Existing Menu.
5. Tap Demo Menu and confirm uploaded-menu state is ready.
6. Open Featured Dishes and verify four menu items.
7. Add repo-backed dish photos if needed for proof:
   - `SiteClaw/Resources/DemoDishPhotos/sunset-smash-burger.png`
   - `SiteClaw/Resources/DemoDishPhotos/bbq-bacon-cheeseburger.png`
   - `SiteClaw/Resources/DemoDishPhotos/chicken-sandwich.png`
   - `SiteClaw/Resources/DemoDishPhotos/grilled-mahi-sandwich.png`
8. Open Choose Website Style and switch archetypes. Confirm Preview tone/CTA changes after refresh.
9. Open Contact & Visibility.
10. Tap Fill Demo Visit Details and Fill Demo Visibility.
11. Confirm Progress is collapsed by default and expands when tapped.
12. Confirm no conversion/customer action link busywork fields appear in this MVP flow.
13. Tap Generate Restaurant Website or Open Preview.

Preview:

1. Confirm Owner Approval says `Not published yet`.
2. Confirm phone preview shows Sunset Grill, four dishes, menu image, location, and hours.
3. Open fullscreen preview and dismiss it.
4. Confirm fullscreen menu image is not squished at the bottom.
5. Open Review & Publish.
6. Confirm What happens next, Get Found on Google, Publish or Share, privacy reassurance, and proof tools are present.
7. Confirm Find Us Online entries are tappable when URLs are present.
8. Publish/open site.

Generated website:

1. Confirm site opens at `http://localhost:8787/sites/sunset-grill/`.
2. Confirm Home/Menu/Hours/Location nav works.
3. Confirm no top Location/Hours/Menu fact strip appears after hero.
4. Confirm Visit Us contains Address and detailed Hours.
5. Confirm Hours nav scrolls to the hours card.
6. Confirm dish cards and uploaded full menu render.
7. Confirm online links open intended external URLs in a new browser context.
8. Confirm no raw transcript, debug JSON, local file path, or API error appears on the public page.

Account and settings:

1. Open gear/account settings.
2. Confirm current plan, monthly price, custom domain state, and privacy/data reassurance render as informational only.
3. Confirm sign out returns to mock login.
4. Sign back in with Continue with Demo and confirm workspace state behaves as expected.

Accessibility and layout:

1. Recheck Talk, Website Details, Preview, Review & Publish, and Account Settings at larger Dynamic Type.
2. Confirm primary buttons are not hidden behind the floating tab bar.
3. Confirm icon-only buttons have accessibility labels.
4. Confirm important status text remains readable in light mode.

## Handoff Format

Use this format for every QA/Security report:

```md
## QA/Security Result

## Checks Run

## Findings

## Severity

## Required Fixes

## Residual Risk

## Release Recommendation
```

Release recommendation must be one of:

- Approve
- Approve with accepted residual risk
- Block release

## Release Approval Criteria

Approve only when:

- Golden path passes on iPhone 17 Pro simulator.
- Automated checks pass or documented limitations are accepted.
- No Critical or High findings remain open.
- Secrets scan is clean.
- Upload and generated HTML safety checks are clean.
- Mock auth limitations are clearly described and not misrepresented as production auth.
- Generated public website contains only intentional public restaurant content.
- CEO has explicitly accepted any remaining Medium residual risk.
