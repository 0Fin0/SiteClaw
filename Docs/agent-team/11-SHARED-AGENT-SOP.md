# Shared Agent SOP

This SOP applies to every SiteClaw agent.

## Command Structure

The CEO gives strategic direction. The Project Manager Agent turns that direction into task packets. Specialist agents execute only the packets assigned to their lane.

If an agent sees work outside its lane, it should document the need and hand it to the Project Manager Agent instead of taking ownership.

## Before Starting Work

Each agent must read:

1. `00-MASTER-PRODUCT-BUILD-BRIEF.md`
2. Its role-specific file
3. Any task packet assigned by the Project Manager Agent
4. Relevant existing docs under `Docs/engineering/` or `Docs/product/`

Each agent must confirm:

- Goal
- Scope
- Out of scope
- Owned files or systems
- Dependencies
- Required verification

## Work Rules

- Keep `main` releasable.
- Use a working or feature branch for production changes.
- Do not rewrite unrelated systems.
- Do not undo another agent's changes without explicit instruction.
- Prefer small, reviewable commits.
- Keep one source of truth for each behavior.
- Update docs when changing contracts or workflows.
- Protect secrets, raw transcripts, and customer data.

## Coordination Rules

Use these ownership lanes:

- Product Strategist: product requirements and scope
- Project Manager: task sequencing and status
- iOS Engineer: SwiftUI app
- Backend Engineer: Node/API service layer
- AI Voice Engineer: cleanup, extraction, prompts, evals
- Data Architect: Supabase, RLS, storage, schema
- Publishing Engineer: generated sites and Cloudflare
- UX Agent: product experience and design system
- QA/Security: release gates and security review
- Growth/Ops: customer onboarding and feedback

When two lanes touch the same feature, the Project Manager Agent defines the handoff contract before implementation starts.

## Standard Work Cycle

1. Understand assigned task.
2. Inspect current code/docs.
3. Identify dependencies.
4. Implement or produce assigned artifact.
5. Run required verification.
6. Document changed files and risks.
7. Hand off next recommended task.

## Standard Final Report

Every agent returns:

```md
## Completed
- ...

## Changed Files
- ...

## Verification
- ...

## Open Risks
- ...

## Handoff
- ...

## Next Recommended Task
- ...
```

## Escalation Triggers

Escalate to CEO if:

- The task changes product positioning
- The task delays founding restaurant publishing
- Customer data risk is found
- A paid plan feature needs repricing
- A schema-breaking change is needed
- A model/provider change is proposed
- A security release blocker is found

## Definition Of Done

A task is done only when:

- The requested artifact or implementation exists
- Acceptance criteria are satisfied
- Verification is complete or blocked with a clear reason
- Handoff notes are written
- No unrelated changes were made
