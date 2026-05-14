# SiteClaw Local Branch Turnover For Omar

Date: May 14, 2026  
Branch: `carlos-platform-shell-local`  
Planned review branch: `Cyclaw_working`  
Status: Local only, uncommitted, unpushed  
Main branch: Intentionally untouched

## Executive Summary

This branch turns the SiteClaw prototype from a three-tab demo into a more complete local iOS demo shell around the same `Talk -> Build -> Preview` story. The main work adds mock login/account settings, better voice cleanup, uploaded menu support, a real Sunset Grill demo menu path, generated-site preview improvements, visibility/SEO tooling, stronger generated HTML/contact UX, app visual polish, dish photos, local workspace persistence, and security hardening for the local backend/publish flow.

Nothing has been committed or pushed yet. The intent is for Omar to review this work in slices, decide what should go forward, and then move the local changes into the repo branch named `Cyclaw_working` for the morning commit/push/review path. `main` should remain untouched.

## Current Git State

The branch has a large uncommitted diff:

- 19 tracked files modified.
- Several new untracked source, asset, resource, and product-doc files.
- Approximate tracked diff size: 9,643 insertions and 633 deletions.
- No commit has been made from this work.
- Planned destination branch for the review push is `Cyclaw_working`.

Important untracked additions:

- `Docs/product/`
- `SiteClaw/Views/AccountSettingsView.swift`
- `SiteClaw/Views/MockLoginView.swift`
- `SiteClaw/Resources/sunset-grill-demo-menu.png`
- `SiteClaw/Resources/DemoDishPhotos/*.png`
- `SiteClaw/Assets.xcassets/SiteClawLogo.imageset/`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon*.png`

## Product Goals Addressed

The original review surfaced these product gaps:

- Menu buttons looked clickable but did nothing.
- Voice capture saved messy speech too literally.
- Hours parsing confused day ranges and special Sunday hours.
- Cuisine could leak into hours.
- There was no obvious Account/Settings area.
- Owners needed a practical way to upload an existing menu PDF/photo.
- The Build screen was getting dense and hard to scan.
- The Preview screen needed to match the actual published site more closely.
- Sunset Grill needed a stronger demo story: real menu, full address, contact CTAs, visibility checklist, Google/Yelp/social fields, and more polished generated output.

This branch implements local/demo-safe solutions for those items without adding production auth, billing, cloud storage, OCR, or Stripe/Supabase dependencies.

## Major Changes By Area

### 1. Mock Login And App Shell

Files:

- `SiteClaw/Views/MockLoginView.swift`
- `SiteClaw/Views/SiteClawRootView.swift`
- `SiteClaw/Views/SiteClawTheme.swift`

What changed:

- The app now opens to a mock login/sign-up experience before entering the main workflow.
- Login and sign-up fields are prefilled with neutral demo data:
  - `owner@siteclaw.test`
  - `siteclaw-preview`
  - `Demo Owner`
- Button copy was cleaned up so it reads like normal product UX instead of exposing internal demo language.
- Main app flow remains `Talk`, `Build`, `Preview`.
- Account/settings access remains a toolbar action rather than a fourth tab.

Notes for Omar:

- This is not real authentication.
- No OAuth, Supabase session, password handling, or production account security exists here.
- It is only a walkthrough surface for judging/demo purposes.

### 2. Account Settings And Billing Surface

Files:

- `SiteClaw/Views/AccountSettingsView.swift`
- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Views/SitePreviewView.swift`

What changed:

- Added an Account/Settings screen with:
  - Owner profile.
  - Restaurant profile.
  - Site/domain settings.
  - Billing/subscription placeholder.
  - Workspace save/duplicate/reset controls.
  - Logout/sign-out placeholder.
- Billing now exposes plan choices so the UI can show plan changes without integrating Stripe.
- Preview includes an entry point from Review & Export.

Notes for Omar:

- Billing is mock-backed.
- The plan UI is useful for product direction, but no payments, invoices, subscription status, or entitlement checks are wired yet.

### 3. Voice Cleanup, Prompt Interpretation, And AI Hooks

Files:

- `SiteClaw/Views/TalkToSiteClawView.swift`
- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Services/SiteGenerationService.swift`
- `Backend/server.mjs`
- `SiteClawTests/SiteClawCoreTests.swift`

What changed:

- Added local transcript normalization before values populate Build fields.
- Common filler and false-start phrases are stripped, including things like `um`, `uh`, `let's say`, and related speech artifacts.
- Guided answers now infer clean values from natural speech:
  - Example: “the name of the restaurant is Plata” saves as `Plata`.
  - Example: “um Thai Palace” saves as `Thai Palace`.
- Cuisine recognition was expanded, including Argentinian.
- Hours extraction was strengthened for:
  - `Tuesday through Saturday`
  - `Tue-Sat`
  - special Sunday hours
  - demo cases where Sunday was misheard as Saturday
- Cuisine-only phrases like `Argentinian food` are blocked from being accepted as hours.
- Added profile extraction and voice coach request/response models.
- Backend gained local AI-facing endpoints:
  - `/api/extract/profile`
  - `/api/ai/coach-turn`
  - `/api/coach/turn`

Notes for Omar:

- The app now has the structure needed for an LLM cleanup pass.
- Local deterministic cleanup is already in place for the demo.
- API-backed coaching/extraction paths exist, but production API key management, quotas, rate limits, auth, and logging policy still need a real backend decision.

### 4. Build Screen Cleanup

Files:

- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Views/SiteClawTheme.swift`
- `SiteClaw/Models/SiteClawStudio.swift`

What changed:

- Build is now organized into collapsible sections:
  - Restaurant Basics
  - Website Direction & Links
  - Featured Dishes
  - Uploaded Menu
  - Contact & Visibility
- `Site Style` was renamed/reframed as `Website Direction & Links`.
- `Featured Menu` was renamed to `Featured Dishes`.
- The default Build screen is cleaner and easier to scan.
- Generate/open-preview actions remain prominent outside the collapsed edit sections.
- The old ambiguous toolbar voice icon was removed or absorbed into purposeful voice/workflow controls so the toolbar no longer shows a mystery action.

Notes for Omar:

- The site direction/archetype controls still exist, but they are less visually noisy.
- There is still a product decision to make about how much style control owners should see versus how much should be inferred.

### 5. Uploaded Menu Foundation

Files:

- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`
- `SiteClaw/Resources/sunset-grill-demo-menu.png`

What changed:

- Restaurant profiles can now store uploaded menu asset metadata and embedded data URLs.
- `restaurant.json` now includes uploaded menu asset information:
  - filename
  - media type
  - kind
  - data URL
- Build supports menu upload/import paths for local demo use.
- Preview shows the uploaded menu beside the structured featured dishes.
- Generated local websites embed uploaded menus:
  - images render via `img`
  - PDFs render via object/embed-style handling
- Fullscreen uploaded-menu viewing was added.
- The old demo menu was replaced with the new `sunset-grill-demo-menu.png` image resource.

Notes for Omar:

- This intentionally does not do OCR.
- For real PDF/photo uploads, SiteClaw stores/displays the asset and shows a “structured extraction coming soon” style message.
- For the built-in Sunset Grill demo menu only, the app extracts known featured dishes through a deterministic demo path.

### 6. Sunset Grill Demo Menu And Featured Dishes

Files:

- `SiteClaw/Resources/sunset-grill-demo-menu.png`
- `SiteClaw/Resources/DemoDishPhotos/*.png`
- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClawTests/SiteClawCoreTests.swift`

What changed:

- The built-in demo menu now uses the provided Sunset Grill PNG.
- Applying the demo menu auto-populates four featured dishes:
  - Sunset Smash Burger — `$17`
  - BBQ Bacon Cheeseburger — `$18`
  - Crispy Chicken Sandwich — `$16`
  - Grilled Mahi Sandwich — `$18`
- Each featured dish can now have an optional image.
- Demo dish images were added for the four Sunset Grill dishes.
- Generated site menu cards render dish images when present and keep the clean text-only layout when no image exists.

Notes for Omar:

- Demo extraction is intentionally asset-specific.
- Production extraction should use OCR/document parsing and should probably run server-side.

### 7. Location, Contact, And Visit Details

Files:

- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`

What changed:

- Build label changed from `City` to `Location` where owner-facing copy needed the broader concept.
- Internal structured fields now support:
  - street address
  - city
  - state
  - ZIP
  - phone
- Added `Fill Demo Visit Details`.
- Demo visit details populate:
  - `1234 Sunset Avenue`
  - `San Jose`
  - `CA`
  - `95112`
  - `(408) 555-0147`
- Generated sites now prefer the full formatted address over city-only display when available.
- Generated sites render customer CTAs conditionally:
  - Call
  - Get Directions
  - View Menu
- Directions links are generated from the formatted address.
- CTAs are hidden when required data is missing.
- Restaurant structured data includes phone/address when available.

Notes for Omar:

- Address/phone values are fictional demo data.
- There is no address validation yet.

### 8. Visibility, SEO, And Online Presence

Files:

- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`

What changed:

- Added visibility fields for:
  - Google Business Profile URL
  - Google review link
  - Yelp business page URL
  - Instagram URL
  - Facebook URL
- Added a local visibility checklist with progress tracking.
- Added Google review warning copy: do not offer discounts, freebies, or incentives for reviews.
- Yelp copy is framed as `Find us on Yelp`, not `Review us on Yelp`.
- Generated sites can render external profile links in a `Find Us Online` style area.
- Restaurant structured data now supports `sameAs` links for Google/Yelp/social URLs.
- Preview includes an owner-facing SEO summary:
  - search title
  - description
  - local keywords
  - visibility progress

Notes for Omar:

- Links are owner-provided only.
- No Google/Yelp API integration exists.
- Invalid external links are filtered and surfaced through quality checks.

### 9. Generated Website Improvements

Files:

- `SiteClaw/Models/GeneratedSiteRenderer.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`

What changed:

- Generated HTML anchors remain available for:
  - `#menu`
  - `#hours`
  - `#location`
- Hero CTA and menu controls scroll to the menu section.
- Generated sites include:
  - full address where available
  - phone and call link where available
  - maps directions link where available
  - uploaded menu embed
  - featured dish cards
  - dish images
  - external profile links
  - structured data with contact and `sameAs`
- Website rendering now filters invalid URLs before output.
- Menu labels now use `Featured Dishes` rather than `Featured Menu`.
- Design archetypes influence layout, CTA choices, and generated copy.

Notes for Omar:

- Some hero imagery still uses remote Unsplash-style images. That is acceptable for demo but should be revisited for production/offline reliability and licensing clarity.

### 10. Preview Screen And Fullscreen Website Preview

Files:

- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`
- `SiteClaw/Views/SiteClawTheme.swift`

What changed:

- Preview now offers a fullscreen generated-site preview using the actual HTML export.
- The fullscreen preview uses `WKWebView` and does not require publishing first.
- Uploaded full menu viewing is available from the compact uploaded-menu card.
- Preview actions are grouped more clearly around inspect, refresh, publish/open, copy/export, QA, and SEO.
- The compact preview is less cramped and the fullscreen preview is the visual source of truth.

Notes for Omar:

- This helps reduce mismatch between in-app mock preview and what Safari/published output actually shows.

### 11. iOS Visual Refinement

Files:

- `SiteClaw/Views/SiteClawTheme.swift`
- `SiteClaw/Views/SiteClawRootView.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Views/TalkToSiteClawView.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Views/MockLoginView.swift`

What changed:

- Added/refined shared UI components and design tokens:
  - `AppSurface`
  - floating tab bar treatment
  - `StatusPill`
  - `SectionDisclosureRow`
  - `PrimaryBottomAction`
  - `IconBadge`
- Visual style was moved toward a calmer native iOS feel:
  - less visual clutter
  - clearer card hierarchy
  - better safe-area handling around the floating tab bar
  - stronger toolbar accessibility labels
  - fewer repeated headings
- Login was shortened so the form appears sooner.
- Screen hierarchy was tightened across Talk, Build, and Preview.

Notes for Omar:

- The visual refinement is broad. It should be reviewed on simulator, not just in code.
- Larger Dynamic Type should be checked manually before merge.

### 12. App Icon And Logo

Files:

- `SiteClaw/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon.png`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon-dark.png`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon-tinted.png`
- `SiteClaw/Assets.xcassets/SiteClawLogo.imageset/siteclaw-logo.png`

What changed:

- Added local app icon assets based on the provided restaurant-site/logo concept.
- Added a reusable logo image asset for in-app surfaces.

Notes for Omar:

- These should be treated as demo/brand-direction assets unless design has already approved them.
- App Store icon sizing/export polish may still be needed later.

### 13. Local Workspace Persistence

Files:

- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Views/AccountSettingsView.swift`
- `SiteClaw/Views/SiteClawRootView.swift`

What changed:

- Added a local workspace/package model so restaurant state can be saved, duplicated, reset, and restored.
- Root view schedules local autosave/load behavior.
- Settings exposes workspace-level actions.

Notes for Omar:

- This stores local restaurant/menu data on device/Application Support style storage.
- Data is not encrypted.
- For production, privacy and data-retention rules need a real decision.

## Backend And Security Hardening

Files:

- `Backend/server.mjs`
- `Backend/.env.example`
- `Backend/README.md`
- `Docs/engineering/02-DASHBOARD.md`
- `Docs/engineering/03-PIPELINE.md`
- `Docs/engineering/06-INFRASTRUCTURE.md`
- `AGENTS.md`

What changed:

- Local backend now binds to `127.0.0.1` by default.
- Default CORS origin is no longer `*`; it defaults to local app/server origin.
- JSON request body limit is explicit and documented.
- Local generated-site publish size limit is explicit and returns `413` if exceeded.
- Generated HTML safety check blocks:
  - active scripts except JSON-LD
  - inline event handlers
  - `javascript:` links
- Local published-site serving uses safer path resolution.
- Old generated sites are pruned.
- Secret-shaped examples were scrubbed from docs and examples:
  - fake `sk-...` examples
  - fake live Stripe-looking examples
  - token-shaped `eyJ...` examples
- `.env.example` now uses placeholder text that should not trigger secret scanners.

Security scan notes:

- `Backend/.env` remains ignored by `.gitignore` and should not be committed.
- `Backend/generated-sites/` remains ignored.
- Xcode user workspace data remains ignored.
- `gitleaks` and `semgrep` were not installed locally, so the scan used a local secret-pattern scanner plus manual review.
- Local secret scan over tracked and untracked non-ignored files reported no findings.

Production security caveats:

- Backend AI endpoints are still unauthenticated local-demo endpoints.
- If exposed beyond localhost, they need authentication, rate limiting, abuse protections, logging/redaction policy, and API key custody rules.
- Uploaded menu assets are embedded as data URLs in JSON/HTML for the prototype; production should use storage/CDN with validation and size/type controls.
- Local generated-site safety checks are useful, but should not be treated as a full sanitizer for arbitrary untrusted HTML in production.

## API And Data Contract Changes

### Restaurant Profile

The local restaurant profile now supports:

- uploaded menu metadata/data URL
- structured full address
- phone
- catering/contact email
- visibility links
- site feature/conversion links
- design archetype/brief
- dish image data URLs
- workspace/account settings state

### `restaurant.json`

The export contract now includes:

- uploaded menu asset metadata and data URL
- `Featured Dishes` category naming
- optional per-dish `image_url`
- contact/address/phone fields
- visibility/social profile fields
- generated-site feature links
- branding/design brief metadata

### Backend Endpoints

Added or expanded local backend behavior:

- profile extraction endpoint
- voice coach endpoint
- local publish endpoint hardening
- generated site registry/serving improvements

## Test And Verification Results

Commands already run successfully:

```sh
/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs
```

```sh
git diff --check
```

```sh
xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS' -derivedDataPath /private/tmp/siteclaw-derived-data CODE_SIGNING_ALLOWED=NO MACOSX_DEPLOYMENT_TARGET=26.3
```

iOS simulator verification:

- Built and ran `SiteClaw iOS` on iPhone 17 Pro simulator with XcodeBuildMCP.
- Project: `SiteClaw.xcodeproj`
- Scheme: `SiteClaw iOS`
- Simulator: `iPhone 17 Pro`
- Result: build/run succeeded with zero warnings/errors in the checked run.

Representative test coverage now includes:

- voice transcript cleanup
- filler removal
- natural restaurant-name extraction
- Argentinian cuisine not leaking into hours
- Tuesday-Saturday and special Sunday hours extraction
- guided voice capture into Build fields
- manual capture before prompt advancement
- profile extraction request/response models
- voice coach request/response/failure/follow-up handling
- uploaded menu asset export
- Sunset Grill demo menu image asset
- demo menu featured dish extraction
- non-extractable upload preserving existing menu items
- dish image export to `restaurant.json`
- generated site dish image cards
- generated site clean cards without images
- full address/contact actions/structured data
- visibility links and `sameAs`
- invalid external link filtering
- billing plan options
- fill demo visit details
- fill demo visibility details
- fill demo conversion/growth tools
- workspace store round trip
- quality audit blocking invalid conversion links
- generated site uploaded menu embed
- generated site anchors and essentials

## Recommended Review Order For Omar

1. Start with product flow in simulator:
   - mock login
   - Talk capture cleanup
   - Build collapsed sections
   - Demo Menu
   - Preview fullscreen
   - Open Site

2. Review model/export contracts:
   - `SiteClaw/Models/SiteClawModels.swift`
   - `SiteClaw/Models/RestaurantJSONModels.swift`
   - `SiteClaw/Models/GeneratedSiteRenderer.swift`

3. Review owner-facing UI:
   - `SiteClaw/Views/BuilderView.swift`
   - `SiteClaw/Views/SitePreviewView.swift`
   - `SiteClaw/Views/TalkToSiteClawView.swift`
   - `SiteClaw/Views/AccountSettingsView.swift`
   - `SiteClaw/Views/MockLoginView.swift`

4. Review backend/security hardening:
   - `Backend/server.mjs`
   - `Backend/.env.example`
   - `Backend/README.md`

5. Review tests:
   - `SiteClawTests/SiteClawCoreTests.swift`

6. Review docs and repo hygiene:
   - `AGENTS.md`
   - `Docs/engineering/*.md`
   - `Docs/product/*.md`

## How To Run Locally

Backend syntax check:

```sh
/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs
```

macOS tests:

```sh
xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS' -derivedDataPath /private/tmp/siteclaw-derived-data CODE_SIGNING_ALLOWED=NO MACOSX_DEPLOYMENT_TARGET=26.3
```

iOS simulator:

- Use scheme `SiteClaw iOS`.
- Preferred simulator used in verification: iPhone 17 Pro.
- The app should open to mock login, then enter the three-tab demo flow after Login/Continue.

Manual smoke path:

1. Launch app.
2. Log in with prefilled mock account.
3. Go through Talk and confirm messy phrases clean into owner-ready fields.
4. Open Build.
5. Tap the demo menu path and confirm the Sunset Grill menu loads.
6. Confirm Featured Dishes populate with four burger/sandwich items.
7. Fill demo visit details.
8. Fill demo visibility details.
9. Generate/refresh the site.
10. Open Preview fullscreen.
11. Tap View Menu and confirm it anchors/scrolls correctly.
12. Open the full uploaded menu and confirm it scrolls to the bottom without clipping.
13. Publish/Open Site locally and confirm Safari/local site renders contact CTAs and uploaded menu.

## Known Caveats And Decisions Needed

### Auth, Billing, And Account

- Login/sign-up are mock only.
- Settings/account is local only.
- Billing plan switching is UI-only.
- Stripe/Supabase/OAuth are intentionally not integrated.

Decision needed:

- Decide whether this mock shell should stay in the MVP branch or be separated behind a demo flag.

### Voice AI

- Deterministic cleanup is implemented.
- Backend AI hooks exist.
- Full production inference needs API key custody, prompt/versioning strategy, moderation/redaction policy, retry behavior, and cost/rate controls.

Decision needed:

- Decide whether the next branch should wire real OpenAI calls or keep local cleanup for judging.

### Menu Upload

- Upload/display works locally.
- Built-in demo menu extraction works for the known Sunset Grill asset.
- Real PDF/photo OCR is not implemented.
- Assets are embedded as data URLs in local export.

Decision needed:

- Decide whether production menu assets live in Supabase Storage, another object store, or a generated-site asset pipeline.

### Generated Site Security

- Local checks block obvious active HTML/script risks.
- This is not a complete production sanitizer.
- External links are filtered to safer URL schemes.

Decision needed:

- Decide how much arbitrary generated HTML will be allowed in production versus rendering from structured templates only.

### Visual Direction

- App UI is significantly more polished, but there are broad visual changes.
- Site direction/archetype controls still exist but may be too much for owners.

Decision needed:

- Decide whether owner-facing style controls should stay visible, be advanced-only, or become fully inferred.

### Assets

- App icon/logo and demo dish/menu imagery are local demo assets.
- Licensing/final brand review may still be needed.

Decision needed:

- Decide whether to treat these as final brand assets, placeholders, or design-direction references.

## Suggested Next Steps Before Push Or PR

1. Finish the next requested task on this same local branch.
2. Re-run:
   - `git diff --check`
   - backend syntax check
   - macOS unit tests
   - iOS simulator build
3. Do one manual simulator smoke pass with the Sunset Grill path.
4. Review ignored files before staging:
   - confirm `Backend/.env` is ignored
   - confirm generated sites are ignored
   - confirm Xcode user data is ignored
5. Stage in logical chunks rather than one giant commit if possible:
   - docs/security hygiene
   - backend hardening
   - models/export contracts
   - voice cleanup/AI hooks
   - uploaded menu/demo assets
   - Build/Preview UI
   - account/login shell
   - tests
6. Move or push the reviewed local work to `Cyclaw_working`, then open a PR from that branch rather than merging directly into `main`.
7. Ask Omar to review the caveats above before approving any production-facing backend/API direction.

## Appendix: Main Files Touched

Tracked modified files:

- `AGENTS.md`
- `Backend/.env.example`
- `Backend/README.md`
- `Backend/server.mjs`
- `Docs/engineering/02-DASHBOARD.md`
- `Docs/engineering/03-PIPELINE.md`
- `Docs/engineering/06-INFRASTRUCTURE.md`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`
- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Services/SiteGenerationService.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Views/SiteClawRootView.swift`
- `SiteClaw/Views/SiteClawTheme.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Views/TalkToSiteClawView.swift`
- `SiteClawTests/SiteClawCoreTests.swift`

Untracked additions to include intentionally if Omar approves:

- `Docs/product/README.md`
- `Docs/product/restaurant-design-archetypes.md`
- `Docs/product/restaurant-website-design-sop.md`
- `Docs/product/ui-feedback-2026-05-13.md`
- `Docs/product/omar-turnover-2026-05-14.md`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon.png`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon-dark.png`
- `SiteClaw/Assets.xcassets/AppIcon.appiconset/siteclaw-app-icon-tinted.png`
- `SiteClaw/Assets.xcassets/SiteClawLogo.imageset/Contents.json`
- `SiteClaw/Assets.xcassets/SiteClawLogo.imageset/siteclaw-logo.png`
- `SiteClaw/Resources/sunset-grill-demo-menu.png`
- `SiteClaw/Resources/DemoDishPhotos/bbq-bacon-cheeseburger.png`
- `SiteClaw/Resources/DemoDishPhotos/chicken-sandwich.png`
- `SiteClaw/Resources/DemoDishPhotos/grilled-mahi-sandwich.png`
- `SiteClaw/Resources/DemoDishPhotos/sunset-smash-burger.png`
- `SiteClaw/Views/AccountSettingsView.swift`
- `SiteClaw/Views/MockLoginView.swift`
