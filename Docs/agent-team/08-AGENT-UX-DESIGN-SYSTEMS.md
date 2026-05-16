# Agent 08: UX Design Systems

## Mission

Own the product experience and visual quality across the iOS app and generated restaurant sites. Your job is to make SiteClaw feel trustworthy, calm, modern, and easy for non-technical owners.

## Ownership

You own:

- UX flows
- Visual hierarchy
- App design system
- Copy clarity
- Accessibility expectations
- Restaurant site template direction
- Owner onboarding experience
- Design QA

You do not own:

- Production data schema
- Backend implementation
- AI model logic
- Final pricing decisions

## Product Experience Goals

The app should feel:

- Guided
- Calm
- Premium
- Native
- Forgiving
- Clear about what is live versus draft

Restaurant sites should feel:

- Customer-ready
- Mobile-first
- Specific to the restaurant type
- Easy to scan
- Clear on menu, hours, phone, and directions

## SOP

1. Preserve Talk -> Build -> Preview.
2. Reduce cognitive load before adding features.
3. Prefer owner-friendly words over technical labels.
4. Make important actions visible and non-dead.
5. Use accessibility labels for icon-only controls.
6. Check large Dynamic Type and small screens.
7. Keep generated site templates distinct enough to matter.

## Initial Tasking

Create UX specs for:

- Login/signup
- Build section states
- Voice coach collapsed/expanded behavior
- Menu upload review
- Preview and publish flow
- Account/settings plan gates
- Growth Toolkit beta gate

## Production Owner Flow Review

Design-only recommendation for the production owner flow. Preserve `Talk -> Build -> Preview`, reduce owner confusion, and make account, save, publish, settings, and accessibility states clear before adding more product surface.

### Login / Signup

- Use one primary owner path: `Create Account` in production, with `Continue with Demo` limited to demo/dev builds.
- Keep `Sign In` secondary and visually quieter than the primary start action.
- Replace technical/mock language with owner-safe reassurance:
  - `Create your restaurant workspace`
  - `Preview everything before anything goes live`
  - `Nothing is published until you approve it`
- After auth, route owners to `Resume Website` when a workspace exists and `Start New Website` when no workspace exists.
- Avoid owner-facing words such as `mock`, `Supabase`, `OAuth`, `local branch`, `JSON`, or `backend`.

### Save States

- Standardize visible save states across Talk, Build, Preview, and Settings:
  - `Saved` when workspace autosave succeeded.
  - `Saving...` while autosave is pending.
  - `Unsaved changes` when edits exist but autosave has not completed.
  - `Needs preview refresh` when Build data changed after the current generated site.
  - `Save failed` with a short recovery action.
- Put save state near the screen title or primary action; do not bury it only in Settings.
- Build edits should always make the next action obvious: `Refresh Preview`.
- Workspace Settings can keep `Save Now`, `Duplicate Workspace`, and `Reset Demo`, but reset needs a confirmation sheet.

### Publish States

- Use four owner-facing publish states:
  - `Draft`: details are still being entered.
  - `Preview Ready`: site can be reviewed safely.
  - `Published`: a live/local published version exists.
  - `Needs Republish`: saved changes are newer than the published site.
- Preview should always show `Preview only` or `Published` near the top.
- Keep `Review & Publish` below the visible site preview.
- If blockers exist, disable publishing and show the smallest fix, such as `Add menu prices in Build`, `Fix invalid link`, or `Add restaurant name`.
- After publish, show `Published Site`, URL, `Copy Site Link`, `Open Again`, and QR code.
- Keep raw HTML/JSON inside Proof Tools only.

### Account / Settings Notes

- Keep Account & Settings secondary behind the gear icon.
- Recommended grouping:
  - Account
  - Restaurant profile
  - Workspace & privacy
  - Plan
  - Site & domain
  - Growth Toolkit
- Plan gates should not look broken. Use explanatory disabled rows such as `Available after account setup`, `Included with Growth`, and `Beta module`.
- Avoid active-looking controls for unavailable features.
- Keep real local actions clearly labeled: `Save Now`, `Duplicate Workspace`, and `Reset Demo`.
- Billing copy should avoid hard pricing promises unless pricing is approved.

### Accessibility Checklist

- Check iPhone small screen and large Dynamic Type for Login, Build, Preview, and Settings.
- All disclosure rows must announce expanded/collapsed state.
- Status must not rely on color only; every pill needs text.
- Icon-only buttons need labels: `Open account settings`, `Fullscreen preview`, and `Copy site link`.
- Publish state changes should be announced.
- Destructive actions need confirmation and clear labels.
- QR code must have adjacent readable URL text.
- Minimum tap target is 44 by 44 points.
- Generated restaurant sites need alt text for dish/menu images, readable contrast, visible focus states, and customer-ready copy.

### Test / QA Scenarios

- New owner can understand account/demo status without explanation.
- Returning owner can resume a saved workspace.
- Editing Build changes Preview state to `Needs preview refresh`.
- Publish is blocked when required quality issues exist.
- Published site clearly changes to `Needs Republish` after edits.
- Account/Settings has no dead-looking controls.
- Large Dynamic Type does not clip primary actions or status text.
- VoiceOver can navigate Login, Build disclosures, Preview publish actions, and Settings.

### Implementation Boundary

- No public API or data model changes in this design pass.
- Recommended future labels should map to existing concepts: `SitePublishStage` for publish status, workspace status for save state, and preview freshness for stale generated output.
- No app edits, schema edits, or renderer edits are part of this task.

## UX Spec 1

### UX Recommendation

Keep login/signup lightweight, confidence-building, and clearly local/demo-aware until production auth is ready.

### Screen Or Flow

Login/signup entry screen.

### User Problem

Restaurant owners need to understand whether they are starting a real account, a demo, or a temporary local workspace. If this is unclear, the product can feel risky before they even reach the website builder.

### Proposed Interaction

- First viewport should offer one primary path: `Continue with Demo` for rehearsals or `Create Account` for production.
- Keep `Sign In` as a secondary text action.
- Show a short trust note below the primary action: `You can preview everything before anything goes live.`
- When production auth is enabled, use a two-step flow: email first, then password or magic link.
- If auth is unavailable locally, keep the mock gate honest with `Demo workspace only` language.
- After login, route directly to Talk unless there is an unfinished workspace, in which case offer `Resume Website` and `Start New Demo`.

### Copy Guidance

- Use `Create your restaurant workspace`, not `Register`.
- Use `Continue with Demo`, not `Bypass auth`.
- Use `Nothing is published until you approve it`, not `Local-only mode`.
- Avoid backend, token, session, Supabase, or JSON language on owner-facing screens.

### Accessibility Notes

- Primary auth action must be reachable before scrolling on iPhone SE-sized screens.
- Support Dynamic Type without clipping button labels.
- Every icon-only auth affordance needs an accessibility label.
- Error text should be visible, persistent, and announced with accessibility focus.

### Engineering Dependencies

- Production auth state model.
- Workspace resume detection.
- Error contract for invalid email, expired link, offline service, and cancelled sign-in.
- Account deletion/export hooks later, but do not block demo login on those.

## UX Spec 2

### UX Recommendation

Make Build feel like a review checklist, not a long form.

### Screen Or Flow

Build section states.

### User Problem

After voice capture, owners need to verify what SiteClaw heard. If every section is expanded, the screen feels like homework and hides the next action.

### Proposed Interaction

- Keep all major Build sections collapsible: Restaurant Basics, Use Your Existing Menu, Featured Dishes, Choose Website Style, Contact & Visibility, Growth Toolkit.
- Each collapsed row should show a plain-English status summary:
  - `Ready` when minimum required fields are present.
  - `Needs hours` or `Add menu` for missing essentials.
  - `4 dishes` for menu count.
  - `Neighborhood style` for direction.
  - `3 visibility links` for local profiles.
- The current or incomplete section may auto-expand after Talk, but completed sections should stay collapsed.
- Keep `Generate Restaurant Website` or `Refresh Preview` visible outside the sections as the clear next action.
- Use warnings only for publish-impacting issues, not every optional blank field.

### Copy Guidance

- Use `Website Details`, not `Builder`.
- Use `Review what SiteClaw heard`, not `Edit generated metadata`.
- Use `Optional`, `Recommended`, and `Needed before publish` consistently.
- Avoid labels that sound technical: `design_brief`, `schema`, `renderer`, `CTA`.

### Accessibility Notes

- Disclosure rows must expose expanded/collapsed state to VoiceOver.
- Status summaries should not rely on color only.
- Tap targets should remain at least 44 by 44 points.
- Large Dynamic Type should wrap summaries cleanly instead of truncating critical words.

### Engineering Dependencies

- Per-section completion state.
- Required versus optional field classification.
- Stale preview state when Build data changes.
- Shared `SectionDisclosureRow` behavior for consistency.

## UX Spec 3

### UX Recommendation

Treat Voice Coach as a helpful assistant card that stays quiet until it has useful feedback.

### Screen Or Flow

Voice Coach collapse/expand behavior in Talk.

### User Problem

The AI coach is a demo-winning moment, but if it is always large or verbose it competes with the guided question and makes the flow feel complicated.

### Proposed Interaction

- Show Voice Coach collapsed by default after each saved answer.
- Collapsed state should show one sentence: `I heard: Salvadorian and Peruvian food in San Jose`.
- Add a confidence/status pill: `Looks good`, `Needs detail`, or `Could use a follow-up`.
- Expanded state should show:
  - What I heard.
  - Missing details.
  - One suggested follow-up.
  - One design note when relevant.
- If a follow-up exists, show a single `Answer follow-up` action inline.
- Follow-up answers should improve the current section only; they should not reset the five-step walkthrough.
- If AI is offline, show no alarming error. Local parsing continues and the card can say `Saved locally`.

### Copy Guidance

- Use `Voice Coach`, not `AI response`.
- Use `What I heard`, not `cleaned_answer`.
- Use `A useful follow-up`, not `model-generated question`.
- Use `Saved to Build`, not `patch applied`.

### Accessibility Notes

- Confidence labels must be text, not only color.
- Follow-up controls must be reachable in logical order after the saved answer.
- Dynamic Type should keep the current question above the fold where possible.
- Avoid auto-moving focus unless a new error requires attention.

### Engineering Dependencies

- `VoiceCoachTurn` persistence in studio state.
- Safe patch application rules.
- Async loading, failure, and completed states.
- Separate follow-up answer ownership so story/menu/hours do not leak into the wrong Build field.

## UX Spec 4

### UX Recommendation

Make menu upload review prove that SiteClaw captured usable customer-facing menu content.

### Screen Or Flow

Menu upload review.

### User Problem

Owners may upload a menu photo or PDF and assume the site can use it. They need to verify fit, legibility, and whether featured dishes still need editing.

### Proposed Interaction

- After upload/photo/demo menu, show a review card with:
  - Full menu preview.
  - File/source label.
  - `Looks readable` status when the preview fits.
  - `Replace`, `View full menu`, and `Add featured dishes` actions.
- The full menu viewer should fit width, preserve aspect ratio, and scroll vertically without horizontal clipping.
- Featured Dishes should remain separate from uploaded menu because they drive the homepage cards.
- Dish photo upload should show preview, remove action, and clear fallback layout when no image exists.
- If extraction/OCR is later added, show extracted dishes as suggestions requiring owner confirmation.

### Copy Guidance

- Use `Use Your Existing Menu`, not `Uploaded Menu`.
- Use `Featured Dishes`, not `Featured Menu`.
- Use `Add the dishes you want customers to notice first`.
- Avoid implying OCR happened unless it actually did.

### Accessibility Notes

- Menu images need meaningful alt text in generated HTML.
- Full-screen menu viewer needs a clear dismiss action.
- Image upload buttons need labels such as `Add photo for Sunset Smash Burger`.
- Do not put essential menu prices only inside an image; featured cards should expose text prices where known.

### Engineering Dependencies

- Menu asset portability in app bundle/workspace package.
- Aspect-ratio preserving image display.
- Fullscreen menu viewer state.
- Per-dish `image_url` export and generated-site rendering.

## UX Spec 5

### UX Recommendation

Make Preview and Publish separate mental states: Preview is safe, Publish is intentional.

### Screen Or Flow

Preview/publish flow.

### User Problem

Owners fear accidentally publishing wrong information. They need visible reassurance and a final review path that feels real, not hidden in debug tools.

### Proposed Interaction

- Preview top state should say `Not published yet` until publish succeeds.
- Keep the live website preview prominent, with mobile/tablet/desktop modes when available.
- Put `Review & Publish` below the main preview, not as a competing primary action before the site is visible.
- Review & Publish should include:
  - Owner review checklist.
  - What happens next.
  - Get Found on Google.
  - Publish or Share.
  - Proof tools collapsed.
- After publish, show:
  - Published local URL.
  - Copy Site Link.
  - Open Again.
  - QR code.
- If required info is missing, explain the smallest fix and deep-link to the Build section.

### Copy Guidance

- Use `Preview only`, `Not published yet`, and `Published Site` consistently.
- Use `Open Site`, not `Open generated artifact`.
- Use `Fix in Build`, not `Resolve validation failure`.
- Avoid exposing raw HTML/JSON unless inside Proof Tools.

### Accessibility Notes

- Publish state changes should be announced.
- QR code needs adjacent text URL.
- Device preview picker must be usable with VoiceOver and not rely on icon-only labels.
- Color contrast for status pills must pass WCAG AA.

### Engineering Dependencies

- Publish status model: draft, preview, needs republish, published, failed.
- Quality audit deep links to Build sections.
- Local publish URL persistence.
- Generated-site parity checks between native Preview and HTML renderer.

## UX Spec 6

### UX Recommendation

Show account/settings plan gates as future capability, not broken controls.

### Screen Or Flow

Account/settings plan gates.

### User Problem

Plan, billing, domain, and account settings are important for a real product, but in the MVP they can easily look fake or unusable if presented as active controls without behavior.

### Proposed Interaction

- Account & Settings should be a calm secondary surface from the gear icon.
- Group settings into:
  - Account.
  - Restaurant profile.
  - Workspace.
  - Plan.
  - Site and domain.
  - Privacy.
- For gated or future items, show `Coming soon for beta` or `Available after account setup`.
- Do not show dead toggles. Use disabled rows with explanation or active `Learn what this unlocks` style rows.
- Keep local workspace actions real: save, duplicate, reset demo, export data if available.
- Plan gates should explain value in owner terms: custom domain, online updates, publish history, growth modules.

### Copy Guidance

- Use `Your plan`, not `Billing tier`.
- Use `Custom domain`, not `DNS configuration`.
- Use `Save a copy of this workspace`, not `Duplicate local persistence record`.
- Avoid pricing claims until pricing is approved.

### Accessibility Notes

- Disabled controls need explanatory text, not only dimmed opacity.
- Destructive actions like reset demo need confirmation and clear VoiceOver labels.
- Group headings should be real headings for rotor navigation.
- Settings should remain readable at large Dynamic Type without two-column compression.

### Engineering Dependencies

- Plan entitlement model.
- Real versus placeholder action flags.
- Workspace duplicate/reset/export methods.
- Future auth/account IDs from production backend.

## UX Spec 7

### UX Recommendation

Position Growth Toolkit as a beta module recommendation layer, not a distracting feature dump.

### Screen Or Flow

Growth Toolkit beta gate.

### User Problem

Restaurant owners may want specials, events, catering, gift cards, QR menus, reviews, newsletter capture, and analytics, but too many modules during setup will slow the core website creation flow.

### Proposed Interaction

- Keep Growth Toolkit collapsed by default in Build.
- Show 2 to 3 recommended modules based on provided facts and archetype:
  - Catering lead form if catering email exists.
  - Gift cards if gift card URL exists.
  - Events/private dining if owner mentions events or private dining.
  - Review links if visibility URLs exist.
  - Specials if menu changes often.
- Gate inactive modules with `Beta` and a short explanation.
- Let owners opt into a module only after the core site preview is working.
- In Preview, show enabled modules only when they have enough content to look real.

### Copy Guidance

- Use `Growth Toolkit`, not `Marketing automation`.
- Use `Recommended because you added catering contact`.
- Use `Beta`, not `Locked`, unless it is truly unavailable by plan.
- Avoid implying analytics, newsletter delivery, or CRM behavior exists before implementation.

### Accessibility Notes

- Beta badges need text labels.
- Module cards should have clear selected/unselected states.
- Recommendations must not rely only on color or icon.
- Large Dynamic Type should stack module details vertically.

### Engineering Dependencies

- Recommended module rules from `design_brief` and restaurant profile.
- Entitlement/beta flag model.
- Generated-site support for each enabled module.
- Quality audit to prevent empty modules from rendering publicly.

## Design Review Checklist

- Is the next action obvious?
- Is anything clickable but dead?
- Does the app explain draft vs published state?
- Can an owner fix AI mistakes?
- Does Preview match Publish?
- Is the screen readable on iPhone?
- Are we adding clutter instead of confidence?

## Done Criteria

Your work is done when engineering has clear UX direction and the CEO can demo the app without explaining confusing UI.
