# Sprint 0 And Sprint 1 Production Foundation Plan

Date: 2026-05-15
Owner: Agent 02 - Project Manager

## Sprint Goal

### Sprint 0: Coordination And Contracts

Create the production coordination base without changing the app behavior. Sprint 0 produces approved scope, branch rules, task packets, API/data/publishing contracts, QA gates, and founding beta operations material.

Sprint 0 outcome:

- Every agent has one owned lane.
- No two agents edit the same subsystem without a handoff.
- `main` stays releasable.
- Milestone 1 scope is concrete enough to begin production foundation work.

### Sprint 1: Supabase And Production Persistence Foundation

Prepare SiteClaw for real authenticated restaurant data while preserving the current Talk -> Build -> Preview -> Review & Export -> Open Site demo path.

Sprint 1 outcome:

- Supabase schema, RLS, and storage plans are ready or implemented in a reviewable branch.
- Backend contracts exist for auth, restaurant workspace load/save, uploads, and publish metadata.
- iOS knows exactly which local/mock states will become persisted production states.
- QA/Security has a release gate for auth, RLS, secrets, and manual smoke testing.

## Branching Plan

- `main`: always releasable. No direct production experimentation.
- `SiteClaw_Working`: integration branch for reviewed production foundation work.
- Short-lived feature branches:
  - `agent-01-founding-beta-prd`
  - `agent-03-ios-persistence-map`
  - `agent-04-backend-contracts`
  - `agent-05-ai-evals`
  - `agent-06-supabase-foundation`
  - `agent-07-publishing-contract`
  - `agent-08-owner-flow-ux`
  - `agent-09-qa-security-gate`
  - `agent-10-beta-ops`

Rules:

- Feature branches merge into `SiteClaw_Working` only after required verification.
- `SiteClaw_Working` merges into `main` only after the Milestone 1 release gate passes.
- Agents must not use `git reset --hard`, rewrite shared history, or revert another agent's changes without CEO approval.
- Agents must not commit secrets. `Backend/.env` remains local-only.

## Assigned Tasks

### Sprint 0 Tasks

| Task ID | Owner Agent | Task | Deliverable | Do Not Touch | Verification |
|---|---|---|---|---|---|
| S0-01 | Agent 02 - Project Manager | Publish sprint plan and ownership board | `Docs/agent-team/17-SPRINT-0-1-PRODUCTION-FOUNDATION-PLAN.md` | App source, backend implementation | Plan contains one owner per task and dependency map |
| S0-02 | Agent 01 - Product Strategist | Finalize founding beta PRD | Update/confirm `Docs/agent-team/13-FOUNDING-BETA-PRD.md` | API/schema implementation | CEO can approve scope, pricing hypothesis, and non-goals |
| S0-03 | Agent 03 - iOS Product Engineer | Map current app state to persistence needs | iOS persistence handoff doc | Backend routes, DB schema | Lists models, mock-only state, service clients, risks |
| S0-04 | Agent 04 - Backend Platform Engineer | Draft production API contracts | Backend API contract doc | SwiftUI views, Supabase migrations | Routes include request/response/error/auth expectations |
| S0-05 | Agent 05 - AI Voice Pipeline Engineer | Write cleanup/extraction eval spec | AI eval cases and expected outputs | UI screens, schema migrations | Covers known voice bugs and confidence/follow-up behavior |
| S0-06 | Agent 06 - Data/Supabase Architect | Draft Supabase schema, RLS, storage plan | Schema/RLS/storage design doc | iOS views, renderer template | QA can audit ownership and data boundaries |
| S0-07 | Agent 07 - Publishing Engineer | Define Cloudflare publish contract | Publishing contract doc | Auth/session work, DB RLS | Includes slug rules, artifact model, status, retry, preview parity |
| S0-08 | Agent 08 - UX Design Systems | Define production owner flow notes | UX flow and accessibility checklist | Backend APIs, schema | iOS can implement without inventing UX decisions |
| S0-09 | Agent 09 - QA/Security | Create Milestone 1 quality gate | QA/security checklist | Feature implementation | Checklist covers tests, secrets, auth, RLS, upload/publish risks |
| S0-10 | Agent 10 - Growth/Ops | Prepare founding restaurant ops kit | Outreach, intake, approval, feedback docs | Product pricing source of truth unless approved | CEO can start recruiting 3 to 5 restaurants |

### Sprint 1 Tasks

| Task ID | Owner Agent | Task | Deliverable | Dependencies | Verification |
|---|---|---|---|---|---|
| S1-01 | Agent 06 - Data/Supabase Architect | Create Supabase migration plan | Table list, migration order, RLS policies | S0-02, S0-06 | RLS review cases exist for owner-only data |
| S1-02 | Agent 06 - Data/Supabase Architect | Define storage buckets and object paths | Bucket policy and path rules | S1-01 | Upload paths separate owner, restaurant, generated assets |
| S1-03 | Agent 04 - Backend Platform Engineer | Add environment validation and auth expectations | `.env.example` updates and backend startup/auth notes | S0-04, S1-01 | Missing secrets fail with safe messages; no secrets logged |
| S1-04 | Agent 04 - Backend Platform Engineer | Implement/draft restaurant workspace load/save API | Route contract or implementation branch | S1-01, S1-03 | Route-level smoke checks or documented mock responses |
| S1-05 | Agent 03 - iOS Product Engineer | Add production service-client interface plan | App service protocol list and state transition plan | S0-03, S0-04 | Existing demo path remains unchanged |
| S1-06 | Agent 03 - iOS Product Engineer | Prepare session-aware account/settings integration plan | Auth state entry points and persistence handoff | S1-03, S0-08 | iOS simulator build remains green if code changes occur |
| S1-07 | Agent 05 - AI Voice Pipeline Engineer | Convert eval spec into executable/manual eval pack | Eval fixtures and pass/fail rubric | S0-05 | Known transcript bugs have expected outputs |
| S1-08 | Agent 07 - Publishing Engineer | Define publish metadata persistence shape | Publish record schema handoff and preview/publish parity notes | S0-07, S1-01 | Backend and iOS know publish status states |
| S1-09 | Agent 08 - UX Design Systems | Review production auth/persistence UX | UX review notes for login, save states, publish states | S0-08, S1-05 | No dead controls or unclear loading states in proposed flow |
| S1-10 | Agent 09 - QA/Security | Build Sprint 1 verification matrix | Test matrix for auth, RLS, secrets, persistence, publish smoke | S1-01 through S1-08 | Release gate can be run before integration merge |
| S1-11 | Agent 10 - Growth/Ops | Select first beta restaurant candidates | Candidate list and intake readiness status | S0-10, CEO approval | At least 3 candidate profiles and outreach next step |
| S1-12 | Agent 02 - Project Manager | Produce Sprint 1 integration report | Status, blockers, risks, next sprint recommendations | All S1 tasks | Every agent reports completed work, files, verification, risks, next steps |

## Agent Ownership Table

| Agent | Owns | Must Not Touch Without PM Handoff | Primary Dependencies |
|---|---|---|---|
| Agent 01 - Product Strategist | PRD, V1 scope, pricing hypothesis, non-goals | Backend code, SwiftUI implementation, DB migrations | CEO decisions, Growth/Ops feedback |
| Agent 02 - Project Manager | Sprint plan, task packets, dependency tracking, release checklist | Technical architecture decisions, product pricing decisions | All agents' status reports |
| Agent 03 - iOS Product Engineer | SwiftUI app, service clients, app state, simulator build health | Backend route implementation, DB/RLS policies, renderer internals | Backend contracts, Supabase schema, UX notes |
| Agent 04 - Backend Platform Engineer | Node API, auth middleware, error contracts, route behavior | SwiftUI screens, Supabase RLS ownership, UX copy | Data schema, AI contracts, publishing contract |
| Agent 05 - AI Voice Pipeline Engineer | Transcript cleanup, extraction, prompts, evals, confidence | App navigation, DB migrations, publish templates | Backend API contract, Product acceptance criteria |
| Agent 06 - Data/Supabase Architect | Supabase tables, RLS, storage, migrations, versioning | iOS UI, backend route handlers beyond data contracts | Product scope, Backend auth expectations, QA/security |
| Agent 07 - Publishing Engineer | Renderer contract, publish artifacts, Cloudflare plan, publish status | Auth/session, AI cleanup prompts, account/billing UI | Data publish schema, Backend routes, iOS Preview needs |
| Agent 08 - UX Design Systems | Owner flow, accessibility, design patterns, screen-state guidance | Backend, DB, AI implementation | Product PRD, iOS constraints |
| Agent 09 - QA/Security | Quality gate, test matrix, secret scan, auth/RLS/security review | Feature implementation unless assigned | All implementation agents |
| Agent 10 - Growth/Ops | Beta recruitment, intake, approval, feedback loop | Product pricing changes without CEO approval, code | Product PRD, CEO customer targets |

## Production Foundation Backlog

Priority order:

1. Product scope and beta promise approved.
2. Supabase project/environment setup documented.
3. Supabase schema and RLS drafted.
4. Backend API/error/auth contract drafted.
5. iOS persistence needs mapped.
6. AI cleanup/extraction evals written.
7. Publishing contract for Cloudflare/subdomains drafted.
8. Upload/storage paths defined.
9. QA/security gate created.
10. First restaurant onboarding packet prepared.
11. Integration branch receives reviewed foundation work.
12. Milestone 1 release gate passes.

Deferred until after Milestone 1:

- Full Stripe automation.
- Custom domains.
- Full web dashboard.
- Enterprise/multi-location support.
- Advanced analytics.

## Dependencies

### Dependency Map

```text
CEO scope approval
  -> Product PRD
    -> Data schema / RLS
    -> Backend API contracts
    -> UX production flow
    -> Growth/Ops onboarding promise

Data schema / RLS
  -> Backend load/save routes
  -> iOS persistence integration
  -> QA auth/RLS tests
  -> Publish metadata persistence

Backend API contracts
  -> iOS service clients
  -> AI cleanup/extraction endpoints
  -> Publishing endpoint contracts
  -> QA route smoke tests

AI eval spec
  -> Backend AI endpoints
  -> iOS confidence/missing-field states
  -> QA transcript regression checks

Publishing contract
  -> Backend publish routes
  -> iOS Preview publish status UI
  -> QA publish/republish smoke test

UX flow notes
  -> iOS auth/persistence screens
  -> Account/Settings production behavior
  -> QA manual first-time-user test

QA/Security gate
  -> SiteClaw_Working integration approval
  -> main release approval
```

### System Dependencies

- iOS depends on Backend contracts and Supabase schema before replacing mock/local state.
- Backend depends on Supabase schema/RLS and AI/publishing contracts before production route implementation.
- Supabase depends on Product scope before final tables, RLS, storage, and retention rules.
- AI depends on Product acceptance criteria and Backend response contracts before implementation.
- Publishing depends on renderer contract, publish metadata shape, and backend route contract.
- QA depends on all contracts before writing final release gate cases.

## Blockers

- CEO must confirm founding beta scope and whether Account/Settings is in Milestone 1 or deferred behind the core Talk -> Build -> Preview flow.
- CEO must confirm Supabase project ownership/access pattern. Secret values must never be pasted into chat or committed.
- CEO must confirm whether Cloudflare publishing is required for Milestone 1 or whether local registry remains acceptable until Sprint 2.
- Stripe remains deferred unless CEO reprioritizes paid plan testing before first live restaurants.
- Any schema-breaking change requires PM coordination and CEO awareness.

## Release Gate

Milestone 1 cannot merge to `main` until:

- Product PRD approved by CEO.
- API contract reviewed by iOS, Data, AI, Publishing, and QA agents.
- Supabase schema and RLS policy plan reviewed by QA/Security.
- iOS persistence map completed.
- AI eval spec completed.
- Publishing contract completed.
- Growth/Ops onboarding checklist completed.
- `git diff --check` passes.
- Backend syntax check passes.
- macOS tests pass.
- iOS simulator build passes.
- Secret scan/checklist passes.
- Auth/RLS review passes.
- Manual smoke test script exists for signup, login, Talk, Build, upload or upload placeholder, Preview, Publish, Open live site, Republish, logout/login.

## CEO Decisions Needed

1. Approve founding beta promise:
   - 3 to 5 restaurants.
   - Assisted self-serve.
   - SiteClaw subdomain first.
   - Stripe deferred until willingness-to-pay signal is clearer.
2. Choose hosting path for Milestone 1:
   - Cloudflare production publishing now, or local registry/SiteClaw subdomain proof first.
3. Confirm pricing experiment direction:
   - Founding partners.
   - Starter Launch one-time package.
   - Monthly managed plan later.
4. Confirm Account/Settings priority:
   - Milestone 1 production need, or deferred until after publish flow.
5. Confirm who owns Supabase and Cloudflare accounts, and how agents get safe local/staging access without exposing secrets.

## Agent Reporting Requirement

Every agent must report:

```md
## Completed

## Changed Files

## Verification

## Open Risks

## Next Recommended Task
```

Reports must include:

- What changed.
- Files touched.
- Verification commands/results.
- Risks/blockers.
- Dependencies created for other agents.
- What not to touch next.
