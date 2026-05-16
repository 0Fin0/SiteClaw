# Initial Agent Task Assignments

This is the first dispatch board for the SiteClaw agent team.

## Milestone 1: Production Foundation

Goal: prepare SiteClaw for real authenticated restaurant data without breaking the current iOS product flow.

### Agent 1: Product Strategist

Task: write the Founding Beta PRD.

Deliverables:

- Customer profile
- Required V1 flows
- Plan and pricing hypothesis
- Founding beta promise
- Non-goals
- Product acceptance criteria

Acceptance:

- Engineering can use the PRD without asking what V1 means.
- CEO can approve or edit pricing and scope from the document.

### Agent 2: Project Manager

Task: create Sprint 0 and Sprint 1 task packets.

Deliverables:

- Branching plan
- Dependency map
- Sprint backlog
- Agent ownership table
- Release checklist for Milestone 1

Acceptance:

- No two agents are assigned conflicting ownership.
- Every task has clear verification.

### Agent 3: iOS Product Engineer

Task: map current mock/local app state to production persistence needs.

Deliverables:

- List of app models that must persist
- List of mock-only states to replace
- Proposed service-client interfaces
- Risks in Talk, Build, Preview, Settings, Upload, Publish

Acceptance:

- Backend and Data agents know what the app needs to save/load.

### Agent 4: Backend Platform Engineer

Task: define production backend API contracts.

Deliverables:

- Endpoint list
- Request/response shapes
- Auth expectations
- Error contract
- Local versus production behavior notes

Acceptance:

- iOS, AI, Data, and Publishing agents can integrate against the contract.

### Agent 5: AI Voice Pipeline Engineer

Task: build the first AI cleanup/extraction eval specification.

Deliverables:

- Test cases for known voice bugs
- Expected cleaned answers
- Expected extracted fields
- Confidence behavior
- Follow-up behavior

Acceptance:

- Backend agent can implement AI endpoints against these evals.

### Agent 6: Data And Supabase Architect

Task: design Supabase foundation.

Deliverables:

- Table list
- RLS policy plan
- Storage bucket plan
- Migration order
- `restaurant.json` versioning notes

Acceptance:

- Backend can write data safely.
- QA/Security can audit ownership boundaries.

### Agent 7: Web Renderer And Publishing Engineer

Task: define Cloudflare publishing plan.

Deliverables:

- SiteClaw subdomain rules
- Publish artifact model
- Publish status states
- Retry/error behavior
- Preview/publish parity plan

Acceptance:

- Backend can build publish endpoints.
- iOS can show clear publish status.

### Agent 8: UX And Design Systems

Task: design the production owner flow.

Deliverables:

- Login/signup UX notes
- Build section state model
- Preview/publish UX notes
- Account/settings production notes
- Accessibility and mobile checklist

Acceptance:

- iOS agent can update the app without inventing UX decisions.

### Agent 9: QA And Security

Task: create the Milestone 1 quality gate.

Deliverables:

- Test checklist
- Security checklist
- Secret scanning checklist
- Auth/RLS test cases
- Manual smoke test script

Acceptance:

- Every agent knows the checks required before merging milestone work.

### Agent 10: Growth And Customer Ops

Task: prepare founding restaurant onboarding materials.

Deliverables:

- Outreach script
- Intake checklist
- Onboarding call script
- Live site approval checklist
- Feedback interview questions

Acceptance:

- CEO can begin recruiting restaurants while engineering builds.

## Milestone 1 Exit Criteria

Milestone 1 is complete when:

- Product scope is approved
- API contracts are drafted
- Supabase data plan is drafted
- iOS persistence needs are mapped
- AI evals exist
- Publish plan is drafted
- UX flow notes exist
- QA/security gate exists
- Customer onboarding materials exist
