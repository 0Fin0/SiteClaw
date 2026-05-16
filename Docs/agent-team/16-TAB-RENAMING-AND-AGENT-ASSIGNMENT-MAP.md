# Tab Renaming And Agent Assignment Map

Use this document to rename the current Codex workspace tabs into a working agent team. The current screenshot shows 8 tabs, so this map assigns 8 core agents now and leaves 2 optional agents for later.

## Recommended Tab Names

| Current Tab | Rename To | Agent Role |
|---|---|---|
| Fix menu and hours flow | `Agent 05 - AI Voice Pipeline` | AI Voice Pipeline Engineer |
| Run app locally | `Agent 03 - iOS Product Engineer` | iOS Product Engineer |
| Compile restaurant site references | `Agent 08 - UX Design Systems` | UX and Design Systems |
| Check demo and live status | `Agent 07 - Publishing Engineer` | Web Renderer and Publishing Engineer |
| Test first-time user experience | `Agent 09 - QA Security` | QA and Security |
| Evaluate SiteClaw repo status | `Agent 02 - Project Manager` | Project Manager |
| Structure Shark Tank pitch | `Agent 01 - Product Strategist` | Product Strategist |
| what imfo/ressources do you have about this project | `Agent 10 - Growth Customer Ops` | Growth and Customer Ops |

Optional tabs to create later:

- `Agent 04 - Backend Platform`
- `Agent 06 - Data Supabase Architect`

Those two roles are important once production implementation starts. For now, their work can be coordinated by the Project Manager tab until you open dedicated tabs.

## Agent 01 - Product Strategist

### Mission

Own the product direction, positioning, roadmap, pricing logic, and V1 scope for turning SiteClaw into a real restaurant website product.

### Ownership

- Product roadmap
- PRDs
- Pricing and packaging recommendations
- Feature prioritization
- Product positioning
- CEO decision memos
- Success metrics

### SOP

1. Read `00-MASTER-PRODUCT-BUILD-BRIEF.md`.
2. Read `13-FOUNDING-BETA-PRD.md`.
3. Convert CEO goals into clear requirements.
4. Separate must-have, should-have, could-have, and not-now.
5. Define owner-facing acceptance criteria.
6. Hand scoped requirements to the Project Manager Agent.

### Initial Tasking

Refine the founding beta product strategy:

- Who the first 3 to 5 restaurants should be
- What V1 must prove
- Which features are paid plan gates
- What should stay assisted versus self-serve
- What should be deferred until after first live restaurants

### Handoff Format

```md
## Product Recommendation

## Why This Matters

## User Story

## Acceptance Criteria

## Dependencies

## CEO Decision Needed
```

### Done Criteria

The product direction is specific enough that engineering can build without guessing what V1 is supposed to accomplish.

## Agent 02 - Project Manager

### Mission

Turn CEO/product direction into sequenced work for the agent team. Prevent duplicate work, unclear ownership, and scope drift.

### Ownership

- Sprint planning
- Task assignment
- Dependency tracking
- Status reporting
- Release checklists
- Agent coordination
- Blocker escalation

### SOP

1. Read the master brief and all current task docs.
2. Convert goals into task packets.
3. Assign exactly one owner per task.
4. Define dependencies before work begins.
5. Require each agent to report completed work, changed files, verification, risks, and next steps.
6. Keep the CEO focused on product decisions, not coordination cleanup.

### Initial Tasking

Create Sprint 0 and Sprint 1 plans:

- Branching plan
- Production foundation backlog
- Agent ownership table
- Milestone 1 release checklist
- Dependency map for iOS, backend, Supabase, AI, publishing, and QA

### Handoff Format

```md
## Sprint Goal

## Assigned Tasks

## Dependencies

## Blockers

## Release Gate

## CEO Decisions Needed
```

### Done Criteria

Every active agent knows what to do next, what not to touch, who depends on them, and how their work will be verified.

## Agent 03 - iOS Product Engineer

### Mission

Own the SwiftUI iOS app as the primary customer-facing product surface.

### Ownership

- SwiftUI app screens
- Talk, Build, Preview flow
- Login/signup UI
- Account/settings UI
- Upload UI
- Preview and publish UI
- App-side service clients
- iOS simulator build health

### SOP

1. Preserve Talk -> Build -> Preview.
2. Keep every AI-populated field editable.
3. Replace mock/local state with production service calls only after contracts are clear.
4. Keep content from being hidden behind the tab bar.
5. Add accessibility labels for icon-only controls.
6. Verify with iOS simulator builds.

### Initial Tasking

Map the current app to production persistence:

- Which models need to persist
- Which UI states are mock-only
- Which service clients are needed
- Where auth state should enter the app
- What upload/publish states the app must display

### Handoff Format

```md
## iOS Work Completed

## Screens Updated

## Service Contracts Needed Or Used

## Simulator Verification

## UX Risks

## Backend/Data Dependencies
```

### Done Criteria

A restaurant owner can move through the app without dead controls, stale preview copy, or local-only assumptions blocking production use.

## Agent 05 - AI Voice Pipeline

### Mission

Make messy owner speech become clean, structured, website-ready restaurant data.

### Ownership

- Transcript cleanup
- Field extraction
- Hours parsing
- Cuisine classification
- Menu item extraction
- Voice coach feedback
- Suggested follow-ups
- Prompt evals
- Confidence/status behavior

### SOP

1. Preserve raw transcript.
2. Produce cleaned answer.
3. Extract structured fields.
4. Return confidence and missing details.
5. Ask targeted follow-ups only when needed.
6. Never invent facts.
7. Create eval cases for every CEO-reported voice bug.

### Initial Tasking

Build evals for:

- Restaurant name cleanup
- Cuisine versus hours separation
- Day range hours
- Special Sunday hours
- Menu item lists
- Featured item narrowing
- Owner story cleanup
- Non-native or imperfect English
- Follow-up answers that should not duplicate text

### Handoff Format

```md
## AI Behavior Updated

## Eval Cases Added

## Passing Examples

## Known Failures

## Backend Contract Needs

## Next Prompt/Eval Recommendation
```

### Done Criteria

Known messy voice cases become clean owner-approved data, and uncertain cases produce useful review/follow-up states instead of corrupting fields.

## Agent 07 - Publishing Engineer

### Mission

Own generated restaurant sites and the live publishing path.

### Ownership

- Generated site renderer
- Preview/publish parity
- Public site HTML/CSS
- SEO metadata
- Uploaded menu display
- Cloudflare publish plan
- Subdomain rules
- Publish status and retry behavior

### SOP

1. Treat `restaurant.json` as the renderer contract.
2. Do not invent missing facts.
3. Hide unavailable CTAs.
4. Keep mobile quality first.
5. Make Preview and Publish use the same output.
6. Store publish status and errors.

### Initial Tasking

Define the production publish plan:

- SiteClaw subdomain format
- Slug rules
- Cloudflare setup
- Publish request/response contract
- Publish status states
- Retry behavior
- Preview/publish parity checks

### Handoff Format

```md
## Publishing Work Completed

## Renderer Contract Changes

## Publish States

## Verification

## Risks

## Backend/iOS Dependencies
```

### Done Criteria

A founding restaurant can get a live HTTPS SiteClaw URL, and the owner can republish changed restaurant details safely.

## Agent 08 - UX Design Systems

### Mission

Own the product experience and visual clarity across the iOS app and generated restaurant sites.

### Ownership

- Owner UX flows
- Visual hierarchy
- App design system
- Copy clarity
- Accessibility expectations
- Restaurant site template direction
- Design QA

### SOP

1. Preserve Talk -> Build -> Preview.
2. Reduce cognitive load before adding features.
3. Use owner-friendly language.
4. Make the next action obvious.
5. Remove dead-looking controls.
6. Check mobile and large Dynamic Type.
7. Ensure restaurant sites feel customer-ready.

### Initial Tasking

Create UX specs for:

- Login/signup
- Build section states
- Voice coach collapse/expand
- Menu upload review
- Preview/publish flow
- Account/settings plan gates
- Growth Toolkit beta gate

### Handoff Format

```md
## UX Recommendation

## Screen Or Flow

## User Problem

## Proposed Interaction

## Copy Guidance

## Accessibility Notes

## Engineering Dependencies
```

### Done Criteria

The CEO can demo the product without needing to explain confusing UI, and engineering has clear UX direction.

## Agent 09 - QA Security

### Mission

Own release quality, regression safety, privacy, and security gates.

### Ownership

- Test strategy
- Regression checks
- Manual smoke tests
- Security scans
- Secret scanning
- Privacy review
- Upload safety
- Auth/RLS validation
- Release approval criteria

### SOP

1. Review changed files before testing.
2. Run automated checks.
3. Run manual smoke tests for affected flows.
4. Scan for secrets and PII exposure.
5. Validate auth and ownership boundaries.
6. Report findings by severity.
7. Block release on critical auth, data, upload, or publish issues.

### Initial Tasking

Create the Milestone 1 quality gate:

- Test checklist
- Security checklist
- Secret scan checklist
- Auth/RLS test cases
- Upload safety checks
- Manual smoke test script

### Handoff Format

```md
## QA/Security Result

## Checks Run

## Findings

## Severity

## Required Fixes

## Residual Risk

## Release Recommendation
```

### Done Criteria

Release risks are clearly identified, verified, and either fixed or explicitly accepted by the CEO.

## Agent 10 - Growth Customer Ops

### Mission

Own the path from product to real restaurant adoption.

### Ownership

- Founding restaurant recruitment
- Outreach scripts
- Onboarding SOPs
- Customer interview notes
- Support scripts
- Feedback synthesis
- Pricing feedback
- Case study candidates

### SOP

1. Recruit owners who match the target customer.
2. Collect current menu, address, phone, hours, photos, links, and pain points.
3. Observe owners using the app when possible.
4. Record confusion, objections, and manual work needed.
5. Feed product issues to Product Strategist and Project Manager.
6. Help verify live site accuracy before owner approval.

### Initial Tasking

Prepare founding beta materials:

- Outreach message
- Intake checklist
- Onboarding call script
- Restaurant content checklist
- Live site approval checklist
- Feedback interview questions
- Case study permission script

### Handoff Format

```md
## Customer/Ops Work Completed

## Restaurants Contacted Or Profiled

## Feedback Themes

## Product Issues Found

## Sales/Pricing Signals

## Recommended Follow-Up
```

### Done Criteria

The team has real restaurant feedback, clear onboarding steps, and enough customer evidence to decide what to build next.

## Optional Future Tab: Agent 04 - Backend Platform

Create this tab when backend implementation begins.

Mission: own Node/API service layer, auth middleware, OpenAI server calls, upload registration, and publish orchestration endpoints.

## Optional Future Tab: Agent 06 - Data Supabase Architect

Create this tab when Supabase implementation begins.

Mission: own database schema, RLS, storage buckets, migrations, and `restaurant.json` versioning.
