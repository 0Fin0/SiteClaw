# SiteClaw Agent Notes

## Product

SiteClaw is an iOS-first SwiftUI MVP for ISYS 556. It helps local restaurant owners create a small restaurant website by speaking answers to guided questions. The app captures owner details, turns them into structured restaurant data, generates a site preview, supports local publish/open proof, and exposes JSON/HTML for review.

The MVP is being judged by Apple-adjacent reviewers, so the iOS experience must feel native, polished, accessible, and aligned with Apple's Human Interface Guidelines. Prefer SwiftUI-native controls, SF Symbols, system colors, Dynamic Type-friendly text, clear navigation, and simple task flows.

Last updated checkpoint: May 14, 2026 Pacific, after the local customer-facing cleanup, owner trust, preview polish, and Contact & Visibility declutter passes.

## Current App Shape

- `SiteClaw/Views/SiteClawRootView.swift` owns the mock login gate, autosave/load behavior, and the main `TabView`.
- The app starts behind `MockLoginView`, a local-only mock auth gate. No Supabase, OAuth, or Stripe work is live in this branch.
- The root shell autosaves signed-in demo workspace changes and reloads the saved workspace on app start when possible.
- The iOS tab bar uses three judge-facing tabs: Talk, Build, Preview, with floating/glass styling from `SiteClawTheme`.
- `TalkToSiteClawView` is a guided owner walkthrough through five visible questions. The customer-facing action label is `Save Answer`, not `Capture`.
- Talk keeps backend readiness and saved answer/transcript review available but visually secondary/collapsed so the first viewport feels like a guided onboarding screen.
- `BuilderView` is the correction surface, now titled `Website Details`. Users should fix basics, uploaded menu, featured dishes, style, and contact/visibility details here before generating or refreshing the draft.
- `SitePreviewView` shows owner safety status, fullscreen preview, preview device modes, then a compact Review & Publish link for owner review, local website publishing, static HTML export controls, and proof tools.
- `DashboardView` is no longer a top-level tab; it is reachable from Preview > Review & Publish > Proof Tools for launch readiness, MVP checklist, recent activity, and publish status.
- `RestaurantJSONView` is no longer a top-level tab; it is reachable from Preview > Review & Publish > Proof Tools and shows/copies the generated `restaurant.json`.
- `QuickUpdatesView` exists but should not be promoted to a sixth iOS tab unless the navigation is redesigned.
- Account & Settings is exposed through a gear toolbar action, backed by `AccountSettingsView`. It covers mock account status, plan summary, owner profile, restaurant profile, site/domain placeholders, billing plan placeholders, workspace/privacy, and growth settings.
- Build sections are collapsible so the demo can scan quickly: Restaurant Basics, Use Your Existing Menu, Featured Dishes, Choose Website Style, Contact & Visibility, and Growth Toolkit.
- Choose Website Style uses restaurant archetype cards instead of manual color/font controls. The supported V1 archetypes are Neighborhood, Order First, Fine Dining, and Cultural Heritage.
- Use Your Existing Menu prioritizes real owner upload/photo actions. Demo Menu is secondary and uses `SiteClaw/Resources/sunset-grill-demo-menu.png`.
- Featured Dishes supports per-dish images through PhotosPicker/file import. Dish images export as `image_url` data URLs in `restaurant.json` and render on generated menu cards.
- Contact & Visibility includes customer contact details, catering email, local SEO/profile fields, demo-fill buttons, and a collapsed nested Progress disclosure for visibility checklist details.
- Conversion/customer action link UI was removed from Build because it felt like busywork. The data/model/rendering support remains deferred for a later iteration.
- Preview has an `Owner Approval` reassurance card: if not published, it says `Not published yet` and `Nothing goes live until you approve it.`
- Review & Publish contains `What happens next`, `Get Found on Google`, `Publish or Share`, workspace privacy reassurance, owner settings, publish history, and proof tools.
- Generated websites should rely on the stronger `Visit Us` section for address/hours. The earlier top Location/Hours/Menu fact strip was removed.

## May 13-14 Local Work Checkpoint

These changes are local in the current worktree unless/until the user explicitly asks to commit and push. May 13 focused on product/design documentation and UI backlog discovery; May 14 focused on wiring that work into the app.

May 13 product documentation:

- Product docs live under `Docs/product/`.
- `restaurant-website-design-sop.md` is the restaurant website design SOP/source-of-truth document.
- `restaurant-design-archetypes.md` captures restaurant archetype guidance and sample `design_brief` shapes for future expansion.
- `ui-feedback-2026-05-13.md` records the live UI review backlog: menu button issues, voice cleanup, hours parsing, cuisine leaking into hours, menu PDF/photo upload, and account/settings entry point.
- Markdown docs are not read by the app at runtime. Runtime behavior is represented in Swift models/constants, backend prompt/schema instructions, and renderer logic.

May 14 implementation:

- Shared SwiftUI polish lives mostly in `SiteClawTheme.swift`: `AppSurface`, `ClawCard`, `StatusPill`, `SectionDisclosureRow`, `GlassFloatingContainer`, `PrimaryBottomAction`, consistent spacing/radius/shadow tokens, and iOS-friendly tab/navigation chrome.
- Root/app shell work added `MockLoginView`, local account state, workspace autosave/load, app/logo assets, and account/settings toolbar access.
- Talk was cleaned up for customers: active question first, `Save Answer` language, voice controls, compact/collapsible readiness, collapsed saved-answer/transcript review, and `Continue to Build` as the main handoff.
- Restaurant design archetypes are wired through prompt/data/UI/renderer behavior. Generated drafts and `restaurant.json` include `design_brief`; old/missing data falls back to `neighborhood_utility`.
- Conversion link fields exist in the model for online ordering, reservations, gift cards, catering, and private dining. Public rendering only uses valid http(s) URLs and falls back to safe actions if URLs are missing or invalid.
- Conversion/customer action link UI is intentionally hidden/deferred. It should stay out of the customer-facing Build flow and should not add publish-blocking busywork in this MVP pass.
- Build was reordered and renamed for owner trust: Restaurant Basics, Use Your Existing Menu, Featured Dishes, Choose Website Style, Contact & Visibility, Growth Toolkit.
- Use Your Existing Menu should make `Upload File` and `Use Photo` primary. `Demo Menu` should stay secondary.
- Build now has a `Fill Demo Visibility` button that populates neutral `example.com` Google/Yelp/social URLs and marks profile/photos/website-link checklist toggles complete.
- Contact & Visibility has `Customer Contact` plus `Visibility Checklist`; the checklist `Progress` grid is nested in a collapsed disclosure to reduce scrolling.
- Restaurant contact now includes `cateringEmail`, exported as `contact.catering_email`, and rendered as a `mailto:` Catering Contact only when it looks valid.
- Account Settings now includes owner plan summary, monthly price, custom domain, demo privacy reassurance, workspace save/duplicate/reset controls, and growth-tool placeholders. No real billing behavior is implemented.
- Preview now has owner-safety copy, fullscreen preview, preview device modes, `Review & Publish`, `What happens next`, `Get Found on Google`, `Publish or Share`, demo privacy reassurance, publish history, and proof tools.
- Voice capture uses guided prompt kinds and deterministic local parsing first. Each captured answer updates the matching Build fields directly, so name, cuisine/location, hours, featured dishes, and owner story do not depend on the full transcript blob.
- Owner Story should come only from the final story prompt. It should not include the whole questionnaire.
- Local cuisine/location parsing handles natural answers such as `Salvadorian and Peruvian food in San Jose` and overwrites stale defaults like `American restaurant`.
- Backend has `POST /api/extract/profile` for optional AI polish after local parsing. The app must remain useful when this endpoint is offline.
- AI polish must not invent facts, URLs, prices, addresses, hours, or unsupported menu details.
- Native Preview reads the resolved archetype directly and should visibly change hero tone, CTA priority, section labels, section order, and menu treatment when the owner changes the direction card.
- Generated HTML and native Preview should stay aligned for archetype CTA behavior, dish images, uploaded menu display, catering email, and visibility links.
- Generated static sites no longer render the top fact strip after the hero. Address and hours should live in Visit Us, with the Hours nav still anchoring to the Visit Us hours card.
- Generated static sites now support dish images, uploaded full menu images, a full-menu anchor/view action, sanitized external online links, and safer public copy that avoids internal/debug wording.
- The four Sunset Grill dish photos now live in `SiteClaw/Resources/DemoDishPhotos/`: `sunset-smash-burger.png`, `bbq-bacon-cheeseburger.png`, `chicken-sandwich.png`, and `grilled-mahi-sandwich.png`. They should travel with the repo when the resources folder is staged and committed.
- `SiteClaw/Resources/sunset-grill-demo-menu.png` is the local demo menu image resource used by the Sunset Grill uploaded-menu flow.
- `SiteClaw/Resources/DemoDishPhotos/` stores portable copies of the Sunset Grill dish photos that were previously only in the simulator Photos library.
- Local brand shell work includes a mock login screen, account/settings sheet, `SiteClawLogo` asset, and app icon asset updates.
- Backend generation has restaurant archetype prompt/schema instructions and optional profile extraction. The local static-site registry and generated-site serving remain under `Backend/`.
- Backend local publish stores generated `index.html` and `restaurant.json`, serves `http://localhost:8787/sites/{slug}/`, lists generated sites through `GET /api/sites`, and prunes generated-site folders conservatively.
- Tests in `SiteClawTests/SiteClawCoreTests.swift` now cover transcript normalization, guided prompt parsing, JSON export additions, uploaded menu assets, dish image data URLs, renderer output, profile extraction encoding/decoding, workspace autosave round trips, visibility progress, quality audit behavior, publish proof, and generated site safety.
- `Backend/generated-sites/` may contain local generated output for manual proofing. Treat generated output as local demo state unless the user explicitly asks to preserve or publish it.

## Demo Workflow

Use this order for demos and testing:

1. Start the local backend from `Backend/server.mjs`.
2. Run the app in Xcode and choose `Continue with Demo` on the mock login screen.
3. In Talk, answer one visible question at a time.
4. Wait for the transcript, then tap Save Answer.
5. After all five answers are captured, Generate Website Draft should use local guided parsing first, then optional backend polish.
6. Tap Continue to Build or open Build manually.
7. In Build, confirm Restaurant Basics, Use Your Existing Menu, Featured Dishes, Choose Website Style, and Contact & Visibility.
8. For the fully decked-out demo, use Demo Menu, Fill Demo Visit Details, and Fill Demo Visibility. Leave Contact & Visibility Progress collapsed unless asked.
9. Add dish photos through Featured Dishes if needed; PhotosPicker can use the current simulator's local Photos library.
10. Tap Generate Restaurant Website or Open Preview to refresh/review the final Preview and JSON.
11. Review Preview, including owner safety status, fullscreen preview, archetype changes, dish images, uploaded full menu, catering email, and visibility links.
12. Open Preview > Review & Publish to prove the app can publish and open the real generated website.
13. Tap Open Site. Safari should show the local generated website at `http://localhost:8787/sites/sunset-grill/`.

Use Sunset Grill as the reliable demo restaurant:

```text
My restaurant is called Sunset Grill.
We serve American burgers and sandwiches in San Jose.
We are open Monday through Saturday from 10 AM to 8 PM, and Sunday from 11 AM to 6 PM.
Our menu items are cheeseburgers for $12.99, chicken sandwiches for $11.49, fries for $4.99, and lemonade for $3.49.
What makes us special is fresh ingredients, fast service, and a friendly neighborhood atmosphere.
```

Expected menu output: Cheeseburgers $12.99, Chicken Sandwiches $11.49, Fries $4.99, Lemonade $3.49.

Expected proof points: Preview shows Sunset Grill, owner approval `Not published yet` before publish, four menu items, San Jose, corrected hours, selected restaurant archetype behavior, dish cards if photos were added, full uploaded menu, catering contact email, and local visibility links. Review & Publish shows Owner Review `3/3`, What happens next, Get Found on Google, and JSON proof. Open Site shows a real customer-facing local website with Home/Menu/Hours/Location nav, no redundant top fact strip, menu cards, complete Visit Us hours/location, and a Plan your visit CTA. After publishing, the Publish or Share card should show Published Site with a local URL, Copy Site Link, Open Again, and a QR code.

## How To Start And Test The iOS MVP

Backend:

```bash
cd "/Users/nolos/Desktop/Codex Apps/556 - Group Project/SiteClaw"
node Backend/server.mjs
```

If `node` is not on the shell path in Terminal, use the bundled Codex Node runtime:

```bash
cd "/Users/nolos/Desktop/Codex Apps/556 - Group Project/SiteClaw"
/Applications/Codex.app/Contents/Resources/node Backend/server.mjs
```

If port `8787` is already in use, the backend is probably already running. Confirm with:

```bash
curl http://localhost:8787/health
```

If the backend fails because `OPENAI_API_KEY` is missing, create `Backend/.env` from `Backend/.env.example` and add the key. Keep `Backend/.env` out of Git.

iOS app:

1. Open `/Users/nolos/Desktop/Codex Apps/556 - Group Project/SiteClaw/SiteClaw.xcodeproj` in Xcode.
2. Select the `SiteClaw iOS` scheme.
3. Select an iPhone Simulator, preferably a current standard-size device.
4. Press Run.
5. Tap Continue with Demo on the mock login screen.
6. In the Talk tab, confirm Demo Readiness shows backend/Realtime/draft generation ready.
7. Tap Start and answer only the visible question.
8. Wait for transcript text, then tap Save Answer.
9. Repeat for all five questions.
10. Go to Build, correct captured details, then tap Generate Restaurant Website.
11. Review Preview.
12. Open Review & Publish, then tap Open Site to publish and open the real generated website in Safari.

Do not rush the voice test. The current app expects one answer per visible prompt, followed by Save Answer.

If the simulator does not capture audio:

1. In the Simulator app menu, choose `I/O > Audio Input > MacBook Pro Microphone` or another real Mac microphone.
2. In macOS, open `System Settings > Privacy & Security > Microphone` and allow Xcode/Simulator.
3. Stop the app in Xcode, run again, and look for `Mic input streaming: ... sent` in the Talk card.
4. If the Simulator logs show repeated `HALC_ProxyIOContext` or `iOSSimulatorAudioDevice` errors, quit Simulator and Xcode, reopen, and retest. The app uses a simulator-friendly play-and-record audio session, but the Simulator audio device can still fail independently of SiteClaw.
5. Known follow-up: the first Realtime attempt after a fresh app restart can occasionally show a listening state before transcript text appears. The app now does startup cleanup and one-time recovery, but if no transcript appears after 10-15 seconds during a rehearsal, tap Reset, tap Start again, and continue the demo.

## Resume Checkpoint

If a conversation fails or restarts, continue from here:

- The current goal is a polished iOS MVP that can win a judged competition.
- Priority is Apple HIG-style polish: native SwiftUI controls, SF Symbols, system colors, clear navigation, accessibility, and a calm high-confidence demo flow.
- The reliable demo restaurant is Sunset Grill, using the script above.
- The golden path is Talk -> Build corrections/demo fillers -> Generate Restaurant Website -> Preview -> Review & Publish -> Open Site.
- The local app starts at the mock login screen; use Continue with Demo for rehearsals.
- Do not spend more time chasing obscure Pho/Vietnamese transcription edge cases unless they break the core demo.
- Dashboard and JSON are proof tools under Preview > Review & Publish, not part of the default walkthrough.
- Commit `a543500` is pushed to `origin/main` and contains the publish proof: customer-facing static site export, Published Site success with Copy Site Link/Open Again/QR code, backend local generated-sites registry, docs, and regression tests.
- Current local work after commit `a543500` is broader than website polish: mock login, workspace autosave, account/settings, design tokens, restaurant archetypes, guided voice-to-Build parsing, optional AI profile polish, customer-facing Talk cleanup, collapsible Build sections, primary uploaded-menu flow, featured dish images, uploaded full menu display, deferred conversion/customer action link fields, catering email, demo visibility links, owner-safety Preview, Review & Publish proof flow, and generated-site renderer updates. Do not assume this is committed or pushed.
- Latest local iOS verification on May 14: XcodeBuildMCP `build_run_sim` for `SiteClaw iOS` on iPhone 17 Pro succeeded after the Contact & Visibility nested-progress change. XcodeBuildMCP `test_sim` still fails before tests run because the `SiteClaw iOS` scheme is not configured for the `test-without-building` action.
- Earlier May 14 verification also passed for `/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs`, `git diff --check`, macOS `xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw ...`, and iOS simulator build. Re-run before claiming final release readiness because local tests may have shifted with recent copy/UI edits.
- Next best polish target is a final visual QA pass in the simulator: Continue with Demo -> Talk -> Build, use Demo Menu / Visit Details / Visibility, add the four dish photos if desired, Generate Restaurant Website, then Preview -> Review & Publish -> Open Site.
- Do not prioritize full Supabase/OAuth/Stripe before the website creation story feels undeniably publishable. Auth/account/billing is useful later, but it is less memorable for judging than Talk -> real website.
- The minor first-start audio transcription stall is parked as a known follow-up unless it becomes a repeatable blocker during rehearsal.
- Technical debug language such as model names, local backend details, and raw JSON should be de-emphasized during the live demo unless asked.

## Team Ownership

Omar owns the voice-first demo path:

- Talk to SiteClaw voice flow
- OpenAI/Realtimes backend connection
- Website generation from transcript
- Preview tab and demo flow

Omar's primary files:

- `SiteClaw/Views/TalkToSiteClawView.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Services/RealtimeSessionService.swift`
- `SiteClaw/Services/RealtimeAudioStreamingService.swift`
- `Backend/`

Carlo/Nolos owns the account and platform shell:

- Mock auth/sign-in shell
- Account & Settings sheet
- Billing plan placeholder UI
- Workspace autosave/load and local workspace controls
- Restaurant JSON models
- Restaurant website strategy docs and design archetype docs
- Demo assets and local proof fixtures
- Build corrections surface and owner-facing UI simplification

Carlo's primary files:

- `SiteClaw/Views/MockLoginView.swift`
- `SiteClaw/Views/AccountSettingsView.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`
- `SiteClaw/Models/SiteClawModels.swift`
- `SiteClaw/Views/BuilderView.swift`
- `SiteClaw/Views/SiteClawTheme.swift`
- `Docs/product/`
- `SiteClaw/Assets.xcassets/`
- `SiteClaw/Resources/`

Coordinate before editing these shared files:

- `SiteClaw/Views/SiteClawRootView.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `SiteClaw/Views/SitePreviewView.swift`
- `SiteClaw/Models/GeneratedSiteRenderer.swift`
- `SiteClaw/Services/SiteGenerationService.swift`
- `SiteClawTests/SiteClawCoreTests.swift`
- `Backend/server.mjs`
- `README.md`
- `SiteClaw.xcodeproj/project.pbxproj`

Branch workflow:

- Omar branch: `omar-voice-ai`
- Carlo branch: `carlo-auth-account`
- Before starting a new lane of work: `git pull origin main`
- Create/switch to the lane branch before committing.
- Open PRs into `main` so Omar and Carlo can merge cleanly.
- Current instruction from the user: work stays local unless they explicitly ask to commit or push.

## Design Rules

- Treat this as an iOS app, not a web dashboard.
- Use SF Symbols through `systemImage`; do not use Apple logos or trademark-like custom marks.
- Prefer `NavigationStack`, `TabView`, native buttons, grouped backgrounds, standard field styles, and system tint.
- Use existing shared components before inventing new ones: `AppSurface`, `ClawCard`, `IconBadge`, `StatusPill`, `SectionDisclosureRow`, `GlassFloatingContainer`, and `PrimaryBottomAction`.
- Keep navigation calm: one clear title per screen, floating tab bar clearance, and bottom primary actions through `safeAreaInset`/`PrimaryBottomAction`.
- Respect Dynamic Type: avoid hard-coded tiny text for important content and avoid clipped labels.
- Keep cards simple and functional. Avoid heavy gradients, marketing hero blocks, decorative blobs, or nested cards.
- Use placeholders only as prompts, never as fake data. Example: use "Enter street address", not "123 Main Street" unless that value is actually saved.
- Keep the voice flow resilient: speech-to-text can be wrong, so Build must remain the trustworthy correction path.
- Restaurant websites should feel atmosphere-first and practical: clear menu, story, location, hours, catering/contact paths, and visibility links without fake links or unnecessary owner setup.
- Use demo fillers only for local walkthrough clarity. Keep optional customer action/conversion links deferred unless the user explicitly asks to bring them back.
- Put owner reassurance near publish/preview actions. The default mental model should be preview first: nothing goes live until the owner approves.

## Technical Notes

- SwiftUI app source is under `SiteClaw/`.
- Backend is a local Node service under `Backend/`.
- Tests are in `SiteClawTests/SiteClawCoreTests.swift`.
- Product/design docs are under `Docs/product/`.
- Bundled demo resources are under `SiteClaw/Resources/`; simulator Photos library imports are not portable unless copied into this folder.
- `restaurant.json` image data currently uses data URLs for dish/menu images in the prototype.
- `SiteClaw/Resources/sunset-grill-demo-menu.png` must be available in the app/test bundle for the Demo Menu path.
- `Backend/.env` is local only and should stay out of Git.
- `Backend/generated-sites/` is local demo output unless the user explicitly asks to preserve it.
- XcodeBuildMCP is configured for `SiteClaw iOS` on iPhone 17 Pro in this environment; always call `session_show_defaults` before simulator build/run/test calls.
- The iOS `test_sim` tool currently reports a scheme setup limitation for `test-without-building`; use simulator build/run for compile verification and macOS tests when available.
- Use `apply_patch` for manual edits.
- Do not revert user changes or generated work unless explicitly asked.
- Keep macOS compatibility where practical, but prioritize iOS polish for MVP judging.

## Verification Commands

Run these before saying a UI/parser change is done:

```bash
/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs
git diff --check
xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS' -derivedDataPath /private/tmp/siteclaw-derived-data CODE_SIGNING_ALLOWED=NO MACOSX_DEPLOYMENT_TARGET=26.3
```

For iOS simulator verification, prefer XcodeBuildMCP with the configured defaults:

- project: `/Users/nolos/Desktop/Codex Apps/556 - Group Project/SiteClaw/SiteClaw.xcodeproj`
- scheme: `SiteClaw iOS`
- simulator: `iPhone 17 Pro` (`5AC6EE5E-814D-46D0-B840-024F93CB9C50`)
- derived data: `/private/tmp/siteclaw-ios-derived-data`

## Recent Important Fixes

- Mock login is now the local entry point. Continue with Demo opens the prepared Sunset Grill workspace; sign-up mode is still local/mock.
- Workspace autosave/load is wired in `SiteClawRootView` and `SiteClawStudio`; signed-in demo edits can round-trip through the local workspace store.
- Shared visual tokens and reusable SwiftUI components were centralized in `SiteClawTheme.swift`, including surface, card, icon badge, disclosure row, floating glass container, and primary bottom action patterns.
- Voice capture waits for the user to tap Save Answer before advancing questions.
- Talk now uses a guided-first first viewport, collapses saved answers/transcript/review tools, and uses Continue to Build as the customer-facing handoff.
- JSON has a visible Copy JSON button.
- Sunset Grill parser avoids turning cuisine text into menu items.
- Natural menu phrases such as `Our menu items are...`, `we sell...`, and `we have...` are treated as menu capture signals.
- Known menu parsing includes Cheeseburgers, Chicken Sandwiches, Fries, and Lemonade.
- Build includes manual correction fields for basics, menu, and contact details.
- Build is now `Website Details`; section order is Restaurant Basics, Use Your Existing Menu, Featured Dishes, Choose Website Style, Contact & Visibility, Growth Toolkit.
- Use Your Existing Menu prioritizes owner upload/photo actions over Demo Menu and adds reassurance copy that featured dishes can be edited after upload.
- Conversion/customer action links were removed from Build and from owner-facing publish blockers. Keep those fields deferred unless explicitly requested.
- Contact & Visibility progress is collapsed inside a nested Progress disclosure to reduce clutter and scrolling.
- UI polish is moving toward Apple HIG: system colors, SF Symbols, native tabs, and less custom dashboard styling.
- Root navigation now presents Talk, Build, and Preview as the only top-level tabs; Dashboard/JSON moved under Preview > Review & Publish > Proof Tools.
- iOS simulator audio now resets stale streams before Start and uses a play-and-record audio session with startup recovery for the first Realtime pass.
- Website generation polishes the Sunset Grill demo: `American` becomes `American restaurant`, menu descriptions are drafted before Preview/JSON, and the local headline avoids `brings american`.
- Speech artifacts like `Eat your cheeseburgers for twelve ninety-nine` normalize to `Feature cheeseburgers for 12.99`.
- Hours parsing guards the demo against common speech-to-text drift: if the owner says Sunday but transcription produces a second Saturday after `Monday through Saturday`, SiteClaw repairs it to Sunday and prevents menu text from leaking into hours.
- Known menu item descriptions are polished during generation; for example Fries should use the crisp fries description, not a generic `american restaurant lineup` sentence.
- Sunset Grill demo repair protects the expected Fries `$4.99` price if speech-to-text truncates it to `$4.00`.
- Preview Owner Review now treats missing street address and phone as optional details instead of implying the city is a street address.
- Preview now keeps the customer-facing generated site on the main path and moves Owner Review, HTML export, Proof Tools, and Search Preview behind Review & Publish.
- Proof screens have extra bottom clearance for the iOS tab bar, and duplicate dashboard activity entries are coalesced.
- Backend local publish endpoint writes generated `index.html` and `restaurant.json` under `Backend/generated-sites/{slug}/` and serves the site at `http://localhost:8787/sites/{slug}/`. The app's Review & Publish card exposes this as Open Site.
- Generated static sites now use a more public-facing restaurant template: Home/Menu/Hours/Location nav, smooth anchor links, menu cards, hours/location sections, hidden phone card when no phone exists, no `Phone not provided yet`, no `owner-provided` wording, no internal menu-detail notes, and a customer-facing Plan your visit CTA.
- The latest tested Safari result for Sunset Grill shows the generated site opening successfully from the app, with the polished nav and customer-facing menu/hours/location content.
- Review & Publish now gives the app a post-publish proof state: Published Site, local URL, Copy Site Link, Open Again, and a scannable QR code.
- Preview now has persistent owner-safety status, a Preview only / Not published yet approval card, fullscreen preview, preview size picker, What happens next, Get Found on Google, Publish or Share, and workspace privacy reassurance.
- Backend now exposes `GET /api/sites` and `GET /api/sites/{slug}` to list and inspect locally generated site folders before the Supabase storage lane is prioritized.
- Restaurant design archetypes now affect both native Preview and generated HTML: CTA priority, tone, headings, section order, and menu treatment.
- Choose Website Style now uses selectable direction cards and no longer shows manual primary color, accent color, font style, or hero button controls in the Build flow.
- Build by Voice now maps guided answers directly to Restaurant Basics and Featured Dishes; captured cuisine/location, hours, menu, and owner story should overwrite stale demo defaults.
- Backend `POST /api/extract/profile` is an optional polish pass, not the source of truth for core Build fields.
- Featured Dishes supports dish images, and generated `restaurant.json` exports them as `image_url` data URLs.
- Uploaded full menu preview now uses a larger portrait display and full-screen viewer that fits the menu without horizontal clipping.
- Contact & Visibility now includes catering email and renders it as a valid `mailto:` Catering Contact on native Preview and generated HTML.
- Contact & Visibility keeps visibility checklist progress collapsed by default inside a nested Progress disclosure to reduce scrolling and clutter.
- Demo buttons now exist for visit details and visibility/profile checklist data. Conversion/customer action links are deferred and should not be reintroduced as busywork in the Build flow without explicit product direction.
- Generated websites no longer show the redundant top Location/Hours/Menu fact strip after the hero; Visit Us is the single address/hours presentation.
- Review & Publish online profile entries use tappable external links where valid profile URLs exist.
- Portable copies of the four Sunset Grill dish photos are now under `SiteClaw/Resources/DemoDishPhotos/`; keep using those for repo-backed assets instead of relying only on the simulator Photos library.
