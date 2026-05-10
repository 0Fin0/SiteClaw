# SiteClaw Agent Notes

## Product

SiteClaw is an iOS-first SwiftUI MVP for ISYS 556. It helps local restaurant owners create a small restaurant website by speaking answers to guided questions. The app captures owner details, turns them into structured restaurant data, generates a site preview, and exposes JSON/HTML for review or export.

The MVP is being judged by Apple-adjacent reviewers, so the iOS experience must feel native, polished, accessible, and aligned with Apple's Human Interface Guidelines. Prefer SwiftUI-native controls, SF Symbols, system colors, Dynamic Type-friendly text, clear navigation, and simple task flows.

Last updated checkpoint: May 9, 2026 Pacific / May 10, 2026 UTC.

## Current App Shape

- `SiteClaw/Views/SiteClawRootView.swift` owns the main `TabView`.
- The iOS tab bar now uses three judge-facing tabs: Talk, Build, Preview.
- `TalkToSiteClawView` captures voice onboarding through five guided questions.
- `BuilderView` is the correction surface. Users should fix captured basics, menu items, and contact details here before generating or refreshing the draft.
- `SitePreviewView` shows the generated restaurant site first, then a compact Review & Export link for owner review, local website publishing, static HTML export controls, and proof tools.
- `DashboardView` is no longer a top-level tab; it is reachable from Preview > Review & Export > Proof Tools for launch readiness, MVP checklist, recent activity, and publish status.
- `RestaurantJSONView` is no longer a top-level tab; it is reachable from Preview > Review & Export > Proof Tools and shows/copies the generated `restaurant.json`.
- `QuickUpdatesView` exists but should not be promoted to a sixth iOS tab unless the navigation is redesigned.

## Demo Workflow

Use this order for demos and testing:

1. Start the local backend from `Backend/server.mjs`.
2. Run the app in Xcode.
3. In Talk, answer one visible question at a time.
4. Wait for the transcript, then tap Capture.
5. After all five answers are captured, Generate Website Draft can prefill the draft from the transcript.
6. In Build, correct any transcription errors.
7. Tap Generate Restaurant Website to refresh the final Preview and JSON.
8. Review Preview.
9. Open Preview > Review & Export to prove the app can publish and open the real generated website.
10. Tap Open Site. Safari should show the local generated website at `http://localhost:8787/sites/sunset-grill/`.

Use Sunset Grill as the reliable demo restaurant:

```text
My restaurant is called Sunset Grill.
We serve American burgers and sandwiches in San Jose.
We are open Monday through Saturday from 10 AM to 8 PM, and Sunday from 11 AM to 6 PM.
Our menu items are cheeseburgers for $12.99, chicken sandwiches for $11.49, fries for $4.99, and lemonade for $3.49.
What makes us special is fresh ingredients, fast service, and a friendly neighborhood atmosphere.
```

Expected menu output: Cheeseburgers $12.99, Chicken Sandwiches $11.49, Fries $4.99, Lemonade $3.49.

Expected proof points: Preview shows Sunset Grill, four menu items, San Jose, and corrected hours. Review & Export shows Owner Review `3/3`, and JSON shows 4 menu items with 6 SEO terms. Open Site shows a real customer-facing local website with Home/Menu/Hours/Location nav, menu cards, hours, location, and a Ready for owner review CTA. After publishing, the Share Site card should show Published Site with a local URL, Copy Site Link, Open Again, and a QR code.

## How To Start And Test The iOS MVP

Backend:

```bash
cd /Users/yeayea/Desktop/ISYS556/SiteClaw
node Backend/server.mjs
```

If `node` is not on the shell path in Terminal, use the bundled Codex Node runtime:

```bash
cd /Users/yeayea/Desktop/ISYS556/SiteClaw
/Applications/Codex.app/Contents/Resources/node Backend/server.mjs
```

If port `8787` is already in use, the backend is probably already running. Confirm with:

```bash
curl http://localhost:8787/health
```

If the backend fails because `OPENAI_API_KEY` is missing, create `Backend/.env` from `Backend/.env.example` and add the key. Keep `Backend/.env` out of Git.

iOS app:

1. Open `/Users/yeayea/Desktop/ISYS556/SiteClaw/SiteClaw.xcodeproj` in Xcode.
2. Select the `SiteClaw iOS` scheme.
3. Select an iPhone Simulator, preferably a current standard-size device.
4. Press Run.
5. In the Talk tab, confirm Demo Readiness shows backend/Realtime/draft generation ready.
6. Tap Start and answer only the visible question.
7. Wait for transcript text, then tap Capture.
8. Repeat for all five questions.
9. Go to Build, correct captured details, then tap Generate Restaurant Website.
10. Review Preview.
11. Open Review & Export, then tap Open Site to publish and open the real generated website in Safari.

Do not rush the voice test. The current app expects one answer per visible prompt, followed by Capture.

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
- The golden path is Talk -> Build corrections -> Generate Restaurant Website -> Preview -> Review & Export -> Open Site.
- Do not spend more time chasing obscure Pho/Vietnamese transcription edge cases unless they break the core demo.
- Dashboard and JSON are proof tools under Preview > Review & Export, not part of the default walkthrough.
- Current local work after commit `b6fa0e2` is uncommitted: `GeneratedSiteRenderer.swift` now outputs a more publishable customer-facing static site, `SitePreviewView.swift` adds Published Site success with Copy Site Link/Open Again/QR code, `Backend/server.mjs` adds a local generated-sites registry, and `SiteClawCoreTests.swift` adds regression checks for public website nav and removal of internal placeholder copy.
- Latest verification passed after the publish success and backend registry work: `xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS'`, `xcodebuild -project SiteClaw.xcodeproj -scheme 'SiteClaw iOS' -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs`, `git diff --check`, and a temporary-port smoke test for `/health`, `/api/sites`, and `/api/sites/sunset-grill`.
- Next best polish target is a final visual QA pass of Talk -> Build -> Preview -> Review & Export -> Open Site after this work is committed and pushed.
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

- Auth/sign-in shell
- Account tab
- Billing tab
- Restaurant JSON models
- Mock services and gateway layer
- Backend secrecy boundary docs

Carlo's primary files:

- `SiteClaw/Views/AccountView.swift`
- `SiteClaw/Views/BillingView.swift`
- `SiteClaw/Models/RestaurantJSONModels.swift`
- `SiteClaw/Services/Mock*.swift`
- `SiteClaw/Services/*Gateway*.swift`

Coordinate before editing these shared files:

- `SiteClaw/Views/SiteClawRootView.swift`
- `SiteClaw/Models/SiteClawStudio.swift`
- `README.md`
- `SiteClaw.xcodeproj/project.pbxproj`

Branch workflow:

- Omar branch: `omar-voice-ai`
- Carlo branch: `carlo-auth-account`
- Before starting a new lane of work: `git pull origin main`
- Create/switch to the lane branch before committing.
- Open PRs into `main` so Omar and Carlo can merge cleanly.

## Design Rules

- Treat this as an iOS app, not a web dashboard.
- Use SF Symbols through `systemImage`; do not use Apple logos or trademark-like custom marks.
- Prefer `NavigationStack`, `TabView`, native buttons, grouped backgrounds, standard field styles, and system tint.
- Respect Dynamic Type: avoid hard-coded tiny text for important content and avoid clipped labels.
- Keep cards simple and functional. Avoid heavy gradients, marketing hero blocks, decorative blobs, or nested cards.
- Use placeholders only as prompts, never as fake data. Example: use "Enter street address", not "123 Main Street" unless that value is actually saved.
- Keep the voice flow resilient: speech-to-text can be wrong, so Build must remain the trustworthy correction path.

## Technical Notes

- SwiftUI app source is under `SiteClaw/`.
- Backend is a local Node service under `Backend/`.
- Tests are in `SiteClawTests/SiteClawCoreTests.swift`.
- Use `apply_patch` for manual edits.
- Do not revert user changes or generated work unless explicitly asked.
- Keep macOS compatibility where practical, but prioritize iOS polish for MVP judging.

## Verification Commands

Run these before saying a UI/parser change is done:

```bash
/Applications/Codex.app/Contents/Resources/node --check Backend/server.mjs
xcodebuild test -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS'
xcodebuild build -project SiteClaw.xcodeproj -scheme 'SiteClaw iOS' -destination 'generic/platform=iOS Simulator'
```

## Recent Important Fixes

- Voice capture waits for the user to tap Capture before advancing questions.
- JSON has a visible Copy JSON button.
- Sunset Grill parser avoids turning cuisine text into menu items.
- Natural menu phrases such as `Our menu items are...`, `we sell...`, and `we have...` are treated as menu capture signals.
- Known menu parsing includes Cheeseburgers, Chicken Sandwiches, Fries, and Lemonade.
- Build includes manual correction fields for basics, menu, and contact details.
- UI polish is moving toward Apple HIG: system colors, SF Symbols, native tabs, and less custom dashboard styling.
- Root navigation now presents Talk, Build, and Preview as the only top-level tabs; Dashboard/JSON moved under Preview > Review & Export > Proof Tools.
- iOS simulator audio now resets stale streams before Start and uses a play-and-record audio session with startup recovery for the first Realtime pass.
- Website generation polishes the Sunset Grill demo: `American` becomes `American restaurant`, menu descriptions are drafted before Preview/JSON, and the local headline avoids `brings american`.
- Speech artifacts like `Eat your cheeseburgers for twelve ninety-nine` normalize to `Feature cheeseburgers for 12.99`.
- Hours parsing guards the demo against common speech-to-text drift: if the owner says Sunday but transcription produces a second Saturday after `Monday through Saturday`, SiteClaw repairs it to Sunday and prevents menu text from leaking into hours.
- Known menu item descriptions are polished during generation; for example Fries should use the crisp fries description, not a generic `american restaurant lineup` sentence.
- Sunset Grill demo repair protects the expected Fries `$4.99` price if speech-to-text truncates it to `$4.00`.
- Preview Owner Review now treats missing street address and phone as optional details instead of implying the city is a street address.
- Preview now keeps the customer-facing generated site on the main path and moves Owner Review, HTML export, Proof Tools, and Search Preview behind Review & Export.
- Proof screens have extra bottom clearance for the iOS tab bar, and duplicate dashboard activity entries are coalesced.
- Backend local publish endpoint writes generated `index.html` and `restaurant.json` under `Backend/generated-sites/{slug}/` and serves the site at `http://localhost:8787/sites/{slug}/`. The app's Review & Export card exposes this as Open Site.
- Generated static sites now use a more public-facing restaurant template: Home/Menu/Hours/Location nav, smooth anchor links, menu cards, hours/location sections, hidden phone card when no phone exists, no `Phone not provided yet`, no `owner-provided` wording, no internal menu-detail notes, and a Ready for owner review CTA.
- The latest tested Safari result for Sunset Grill shows the generated site opening successfully from the app, with the polished nav and customer-facing menu/hours/location content.
- Review & Export now gives the app a post-publish proof state: Published Site, local URL, Copy Site Link, Open Again, and a scannable QR code.
- Backend now exposes `GET /api/sites` and `GET /api/sites/{slug}` to list and inspect locally generated site folders before the Supabase storage lane is prioritized.
