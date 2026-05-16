# SiteClaw Master Product And Build Brief

## Executive Direction

SiteClaw is an AI-powered website builder for local restaurants and small food businesses. The first real product should not try to be a giant self-serve SaaS platform on day one. It should become a production-quality, assisted self-serve product that gets real restaurants live quickly, proves willingness to pay, and teaches us which automation matters most.

The CEO is the final product owner. Agents are the operating team. Each agent owns one lane and must avoid uncoordinated cross-lane rewrites.

## Product Thesis

Restaurant owners do not want to learn web design, copywriting, SEO, hosting, menus, DNS, or publishing. They want to talk through what their restaurant is, upload what they already have, approve the result, and get a good-looking live site.

SiteClaw should make a messy restaurant owner conversation turn into:

- Clean restaurant profile data
- A polished website
- A real hosted URL
- Easy menu and hours updates
- Basic local visibility setup
- A path to paid plans

## Target Customer

Primary customer:

- Independent restaurant owners
- Food trucks, caterers, pop-ups, bars, cafes, and small local food businesses
- Owners who may be busy, non-technical, not polished speakers, or not fluent in business/marketing English

Initial wedge:

- Restaurants that need a simple site, menu display, hours, address, phone, and local search presence
- Owners who already have a PDF/photo menu and need an online presence fast

## V1 Product Goal

Launch a founding beta with 3 to 5 real restaurants.

V1 succeeds if:

- A real owner can create an account
- The owner can speak answers into the app
- SiteClaw cleans up speech into usable restaurant data
- The owner can upload a menu PDF/photo
- The owner can edit restaurant basics, featured dishes, location, hours, and visibility links
- The owner can preview a site that matches the published output
- The owner can publish a live Cloudflare-hosted SiteClaw subdomain
- The team can help review and republish during the beta

## Product Surface

The first customer-facing production surface is the iOS app.

The current Talk -> Build -> Preview structure remains the product backbone:

- Talk: guided voice intake and voice coach
- Build: owner-editable restaurant details, menu, visibility, site direction
- Preview: generated site preview, publish controls, export, SEO summary
- Account/Settings: owner profile, restaurant profile, publishing details, billing plan, privacy, workplace/business growth

Web dashboard work is deferred unless needed for internal admin, customer support, or investor demos.

## Architecture Direction

Use an incremental monorepo approach from the existing SwiftUI app and Node backend.

Production direction:

- SwiftUI iOS app as the owner surface
- Node backend as the API layer
- OpenAI-only for V1 AI tasks
- Supabase Auth for account/session management
- Supabase Postgres for owner, restaurant, subscription, message, edit history, and publish records
- Supabase Storage for uploaded menus, dish photos, generated JSON, and image assets
- `restaurant.json` as the renderer contract
- Cloudflare-hosted static restaurant sites
- Stripe later, after founding beta billing is understood

The older engineering docs remain reference material, but the production plan is now iOS-first, not Next.js-first.

## Agent Operating Model

There are up to 10 active agents:

1. Product Strategist Agent
2. Project Manager Agent
3. iOS Product Engineer Agent
4. Backend Platform Engineer Agent
5. AI Voice Pipeline Engineer Agent
6. Data and Supabase Architect Agent
7. Web Renderer and Publishing Engineer Agent
8. UX and Design Systems Agent
9. QA and Security Agent
10. Growth and Customer Ops Agent

The CEO gives weekly direction. The Project Manager Agent turns direction into scoped work. Specialist agents execute within their ownership lanes.

## Source Of Truth

Primary source of truth:

- This master brief
- The role-specific agent files in this folder
- Existing docs under `Docs/engineering/`
- Existing product docs under `Docs/product/`
- The current app behavior in source

Rules:

- Do not assume older docs override this brief.
- Do not replace the Talk -> Build -> Preview product structure without CEO approval.
- Do not migrate to a web-first product unless CEO explicitly changes direction.
- Keep `main` releasable. Production work should happen on a working or feature branch until reviewed.

## Build Phases

### Phase 1: Production Foundation

Outcome: the app can authenticate real users and persist real restaurant data.

Required work:

- Supabase project and environments
- Database schema and RLS
- Storage buckets
- Supabase Auth in iOS
- Persist restaurant profile, voice answers, uploads, settings, and generated drafts
- Schema validation for `restaurant.json`

### Phase 2: Production AI Pipeline

Outcome: messy speech becomes clean, editable restaurant website data.

Required work:

- Transcript cleanup endpoint
- Field extraction endpoint
- Confidence/status output
- Voice coach endpoint
- Prompt and eval suite
- Storage of raw transcript, cleaned answer, extracted fields, and approved edits

### Phase 3: Live Publishing

Outcome: owners can publish real sites.

Required work:

- Cloudflare project and API integration
- Publish endpoint
- Site subdomain generation
- Publish status and retry flow
- Preview output matched to published output
- Publish history

### Phase 4: Founding Beta Operations

Outcome: 3 to 5 real restaurants are live and feedback is flowing.

Required work:

- Onboarding scripts
- Restaurant intake checklist
- Manual content review path
- Support and bug triage
- Pricing experiments
- Early customer case studies

### Phase 5: Self-Serve V1

Outcome: new owners can sign up, build, publish, update, and pay with minimal team help.

Required work:

- Stripe Checkout and Customer Portal
- Plan enforcement
- Custom domains for Growth/Pro
- Better menu extraction
- Analytics and site performance monitoring
- Admin tools

## Quality Gates

Before any production release:

- `git diff --check`
- Backend syntax check
- macOS unit tests
- iOS simulator build
- Security scan for secrets, PII exposure, auth/RLS issues, unsafe publishing, and upload handling
- Manual smoke test: signup, talk, build, upload, preview, publish, republish

## Product Non-Goals For Founding Beta

Do not prioritize:

- Full web dashboard replacement
- Multi-location enterprise accounts
- Fully automated OCR for every menu format
- Full Stripe automation before first live restaurants
- Custom domains before SiteClaw subdomains work reliably
- Restaurant analytics beyond basic publish/visit proof

## CEO Decision Points

Agents should escalate these decisions to the CEO:

- Pricing changes
- Plan gate changes
- Major UX flow changes
- Model/provider changes
- Schema-breaking changes
- Security or privacy tradeoffs
- Any change that delays live restaurant publishing

## Standard Agent Handoff Format

Every agent should end work with:

```md
## Completed
- ...

## Changed Files
- ...

## Verification
- ...

## Open Risks
- ...

## Next Recommended Task
- ...
```
