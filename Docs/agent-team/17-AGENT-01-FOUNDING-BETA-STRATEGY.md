# Agent 01 Product Strategist Handoff: Founding Beta Strategy

## Product Recommendation

SiteClaw should launch the founding beta as an **assisted self-serve restaurant website product** for 3 to 5 real local food businesses. The beta should prove that a busy owner can talk through their restaurant, upload existing menu material, review/edit the result, and publish a useful live SiteClaw subdomain with team support where needed.

### First 3 To 5 Restaurants

Prioritize restaurants that are close enough for hands-on support, simple enough to publish quickly, and painful enough to validate willingness to pay.

Best-fit founding beta restaurants:

- Independent, single-location restaurants with no website or a weak/outdated website.
- Caterers, food trucks, pop-ups, cafes, bars, or small food businesses with social/Yelp presence but no reliable owned website.
- Owners with an existing PDF/photo/physical menu, current hours, address, photos, and basic story ready.
- Owners who can join a short onboarding call, approve site content, and give feedback within 48 hours.
- Businesses where menu/hours updates matter often enough to prove the value of self-editing.

Avoid for the first beta:

- Multi-location restaurants, franchises, or groups with complex approval chains.
- Restaurants needing POS, ordering, reservations, delivery, loyalty, or CRM integrations to consider the site useful.
- Businesses requiring guaranteed SEO ranking, paid ads performance, or complex custom branding before launch.
- Owners who cannot provide basic business facts or approve content quickly.

### What V1 Must Prove

V1 must prove five things:

- **Real publishing:** SiteClaw can publish a real HTTPS SiteClaw subdomain for each beta restaurant.
- **Owner control:** owners can update menu or hours without developer help.
- **Messy-to-clean intake:** casual voice answers and uploaded menu material can become clean, editable restaurant data.
- **Preview/publish trust:** the in-app preview matches the live published site closely enough for owner approval.
- **Willingness to pay:** at least 2 of the 3 to 5 beta owners indicate they would pay for continued use.

### V1 Scope Priority

Must-have:

- Supabase Auth and persistent owner sessions.
- Restaurant profile persistence.
- Voice cleanup and field extraction for restaurant name, cuisine, location, hours, menu items, and story.
- Editable Build fields for basics, hours, location, featured dishes, menu, visibility links, and publishing details.
- Menu PDF/photo upload with preview and published-site display.
- Generated site preview using the same output that publishes.
- Cloudflare-hosted SiteClaw subdomain publishing.
- Publish status, publish history, open-live-site, and republish flow.
- Basic account/settings and manual founding beta plan display.
- Team review checklist before first live publish.
- QA/security gate for auth, data isolation, uploads, publishing, and secrets.

Should-have:

- Growth Toolkit beta gate visible but manually enabled.
- AI confidence/status output for low-confidence extracted fields.
- AI eval suite for known voice bugs.
- Owner onboarding script and intake checklist.
- Simple SEO/visibility summary in Preview.
- Manual plan assignment for Starter, Growth, and Pro/Managed.

Could-have:

- Stripe Checkout and Customer Portal.
- Custom domains.
- Full OCR extraction from menus.
- Web dashboard.
- Analytics dashboard.

Not-now:

- Multi-location enterprise accounts.
- Guaranteed SEO/ranking claims.
- Fully automated OCR for every PDF/photo format.
- Complex CRM, loyalty, POS, ordering, reservation, or marketing automation.
- Full self-serve launch with no team review.
- Paid ads management as an automated product feature.

### Pricing And Plan Gates

Do not hard-enforce revenue gates until live publishing is reliable. Plans should be visible in-product during beta and manually assigned by the team.

Recommended packaging hypothesis:

- **Free founding beta:** first 3 to 5 restaurants receive assisted onboarding and a live SiteClaw subdomain in exchange for feedback, usage permission, and a willingness-to-pay conversation.
- **Starter, $19/month:** one SiteClaw subdomain site, Talk-to-Build intake, menu/hour edits, menu upload display, QR/menu basics, and limited support.
- **Growth, $50/month:** richer AI site generation, more active updates, custom domain setup after subdomains are stable, stronger local SEO/visibility tools, and Growth Toolkit beta features.
- **Pro/Managed, $100/month:** unlimited or high-touch edits, priority support, dialed-in SEO, promotions, catering/events support, and an assisted managed workflow.

Plan gate guidance:

- Keep core creation, preview, publish, menu upload, and basic edits available to all beta restaurants.
- Gate custom domain, Growth Toolkit, heavier support, advanced SEO/visibility, and managed promotional work behind Growth/Pro.
- Keep paid ads and agency-style growth work assisted, not automated, until after first live restaurant outcomes are understood.

### Assisted Versus Self-Serve

Self-serve in V1:

- Account setup and login.
- Guided Talk intake.
- Reviewing cleaned answers.
- Editing restaurant basics, hours, location, menu, featured dishes, and visibility links.
- Uploading menu PDF/photo.
- Previewing the generated site.
- Publishing or republishing a SiteClaw subdomain after required review gates pass.

Assisted in V1:

- First restaurant onboarding call.
- First-publish content/design review.
- Cleaning difficult menu uploads.
- Resolving low-confidence AI extraction.
- Manual plan assignment and billing conversations.
- Custom domain setup.
- SEO/profile setup beyond basic in-app guidance.
- Any paid ads or managed growth workflow.

Deferred until after first live restaurants:

- Fully automated billing enforcement.
- Fully automated custom domain setup.
- Full OCR for every menu format.
- Self-serve ads, SEO campaigns, or agency operations.
- Analytics dashboard and conversion reporting.
- Web dashboard for owners.

## Why This Matters

The founding beta is not meant to prove that SiteClaw can become a full SaaS platform immediately. It is meant to prove that real restaurant owners value a faster, cheaper, less technical path to a live website.

If V1 tries to automate everything, the team will delay the one proof that matters most: real restaurants live on real URLs. Assisted self-serve keeps the scope focused while still letting the team learn which automation should be built next.

The highest-risk product questions are:

- Can owners trust the AI-cleaned business data?
- Can owners understand draft versus live state?
- Does menu upload make the product immediately useful?
- Can the team publish and republish reliably?
- Will owners pay for continued updates and growth support?

## User Story

As a busy independent restaurant owner, I want to talk through my restaurant, upload my existing menu, review and edit the details, and publish a professional website without learning web design or paying an agency for every change.

As a SiteClaw team member assisting a founding beta restaurant, I want to review cleaned owner data, fix low-confidence fields, confirm menu readability, publish the site, and help the owner republish updates so the beta restaurant goes live smoothly.

## Acceptance Criteria

Founding beta restaurant selection:

- CEO approves 3 to 5 target restaurants that match the best-fit profile.
- Each restaurant has a named owner/operator contact, menu material, hours, address, and launch approval path.
- Each restaurant agrees to feedback after publish and a willingness-to-pay conversation.

Owner account and data:

- Owner can sign up or log in.
- Session persists across app relaunch.
- Owner cannot access another owner's restaurant data.
- Restaurant profile, voice answers, uploads, edits, preview state, and publish records persist.

Talk intake:

- Owner can answer guided questions by voice.
- Filler speech is removed from saved answers.
- Restaurant name, cuisine, location, hours, menu items, and story populate the correct fields.
- Low-confidence extraction asks for review instead of silently corrupting data.

Build review:

- Every AI-populated field is editable.
- Owner can upload a menu PDF/photo.
- Owner can edit basics, hours, location, featured dishes, visibility links, and publishing details.
- Any edit marks preview/publish as needing refresh.

Preview:

- Preview uses the same output that will publish.
- Uploaded menu appears in preview.
- Owner can inspect menu, hours, location, story, SEO/visibility summary, and calls to action.
- Edited owner-approved fields override stale demo or generated copy.

Publish:

- Owner or team can publish to a SiteClaw subdomain over HTTPS.
- Owner can see publish status, open the live site, and republish updates.
- Republish updates changed restaurant data.
- Publish failures show useful errors and retry paths.
- Publish history is stored.

Assisted beta operations:

- Team can run a first-publish checklist before launch.
- Team can manually assign founding beta plan status.
- Team can record owner feedback and willingness-to-pay signal.
- Team can support content cleanup without requiring code changes.

Success metrics:

- 3 to 5 restaurants are live.
- Intake to first preview takes under 30 minutes with assistance.
- Owner can update menu or hours without developer help.
- At least 2 owners indicate willingness to pay.
- No critical auth, data isolation, upload, or publishing failures occur.

## Dependencies

Project Manager Agent:

- Convert this strategy into Sprint 0 and Sprint 1 task packets.
- Track sequence: foundation, AI cleanup, publishing, beta ops.
- Prevent agents from building deferred features before launch blockers.

Growth and Customer Ops Agent:

- Build candidate restaurant list.
- Prepare outreach script, onboarding call script, intake checklist, approval checklist, and feedback questions.
- Confirm owner willingness to participate in a founding beta.

iOS Product Engineer Agent:

- Map current Talk, Build, Preview, Publish, Account/Settings flows to persistent production state.
- Keep owner-facing flow calm and guided.

Backend Platform Engineer Agent:

- Define auth-aware APIs for profile, voice answers, uploads, generated draft, preview, publish, publish history, and plan display.

AI Voice Pipeline Engineer Agent:

- Define cleanup/extraction confidence behavior and evals for known voice bugs.
- Ensure messy speech does not corrupt fields.

Data and Supabase Architect Agent:

- Design tables, RLS, storage buckets, file paths, and `restaurant.json` versioning.

Web Renderer and Publishing Engineer Agent:

- Define Cloudflare subdomain publishing, publish artifacts, preview/publish parity, status states, and retry behavior.

UX and Design Systems Agent:

- Design production owner flow for login/signup, low-confidence review, menu upload, preview/publish status, and settings.

QA and Security Agent:

- Create launch gate for auth/RLS, uploads, PII, secrets, publishing, preview parity, and manual smoke tests.

## CEO Decision Needed

- Approve the first restaurant selection profile and candidate list.
- Approve whether the first 3 to 5 restaurants are fully comped, manually charged, or given a limited free beta period.
- Approve the visible pricing hypothesis: $19 Starter, $50 Growth, $100 Pro/Managed.
- Decide whether the $100 tier should be described as a software plan, an assisted managed workflow, or both.
- Approve that custom domains, Stripe enforcement, full OCR, analytics, and ads management are deferred until after SiteClaw subdomain publishing works for live restaurants.
- Approve the assisted beta promise: team review before first publish, manual plan assignment, and high-touch support during beta.
- Approve the beta success bar: 3 to 5 live restaurants, under-30-minute assisted preview, menu/hour update without developer help, at least 2 willingness-to-pay signals, and zero critical security/publish failures.
