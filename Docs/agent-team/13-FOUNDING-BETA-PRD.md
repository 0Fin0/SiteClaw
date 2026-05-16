# SiteClaw Founding Beta PRD

## Purpose

The founding beta proves that SiteClaw can help real restaurant owners create and publish useful websites faster than traditional website builders, agencies, or DIY tools.

This PRD defines the minimum real product needed for 3 to 5 founding restaurants.

## Problem

Independent restaurant owners often need a website but lack time, technical confidence, copywriting skill, design judgment, or the ability to keep menus and hours updated. Many already have the raw materials: a physical menu, photos, social links, hours, address, and a story. The hard part is turning that into a clean public website.

## Product Promise

SiteClaw lets a restaurant owner talk through their business, upload their menu, review the result, and publish a professional restaurant website.

## Target User

Primary user:

- Independent restaurant owner or operator
- Busy and non-technical
- May speak casually or imperfectly
- Wants a website that looks credible and is easy to update

Secondary user:

- SiteClaw team member assisting a founding beta restaurant

## Core User Flows

### Flow 1: Account Setup

The owner can:

- Sign up or log in
- See their restaurant workspace
- Open account/settings
- View plan status

Acceptance:

- User session persists across app relaunch.
- User cannot access another owner's restaurant data.

### Flow 2: Talk Intake

The owner can:

- Answer guided questions by voice
- Review what SiteClaw heard
- See AI cleanup and coaching
- Save cleaned answers
- Continue after follow-up questions

Acceptance:

- Filler speech is removed.
- Restaurant name, cuisine, location, hours, menu items, and story do not leak into the wrong fields.
- Low-confidence extraction asks for review instead of corrupting data.

### Flow 3: Build Review

The owner can:

- Edit restaurant basics
- Edit hours and location
- Upload menu PDF/photo
- Edit featured dishes
- Add visibility links
- Change publishing details

Acceptance:

- Every AI-populated field is editable.
- Changes mark preview/publish as needing refresh.
- Uploaded menu appears in preview and publish output.

### Flow 4: Preview

The owner can:

- Open fullscreen preview
- Navigate menu, hours, and location
- Confirm site content before publish
- See SEO and visibility summary

Acceptance:

- Preview uses the same output that will publish.
- Owner story and edited fields override stale demo/generated copy.

### Flow 5: Publish

The owner can:

- Publish to a SiteClaw subdomain
- See publish status
- Open the live site
- Republish updates

Acceptance:

- Live site loads over HTTPS.
- Republish updates changed restaurant data.
- Publish failures show a useful error and retry path.

## Feature Requirements

Must have:

- Supabase Auth
- Restaurant profile persistence
- Voice cleanup and extraction
- Editable Build fields
- Menu upload
- Generated site preview
- Cloudflare subdomain publish
- Publish history/status
- Basic account/settings
- QA/security release gate

Should have:

- Growth Toolkit beta gate
- Plan display and manual founding beta plan assignment
- Team review checklist
- Basic restaurant onboarding materials
- AI eval suite for known voice bugs

Could have:

- Stripe Checkout
- Custom domains
- Full OCR extraction
- Web dashboard
- Analytics dashboard

Not now:

- Multi-location enterprise accounts
- Guaranteed SEO/ranking claims
- Fully automated menu OCR for every image/PDF
- Complex CRM/marketing automation

## Pricing Hypothesis

Founding beta:

- CEO may comp or manually charge first restaurants.
- Plans should be visible in product to test packaging.

Candidate plan structure:

- Starter: one restaurant site, Talk to Build, menu upload, SiteClaw subdomain
- Growth: custom domain setup, active menu updates, Growth Toolkit beta
- Pro: priority support, multi-location roadmap, advanced visibility tools

Do not hard-enforce revenue gates until live publishing is reliable.

## Success Metrics

Founding beta succeeds when:

- 3 to 5 restaurants are live
- Time from intake to first preview is under 30 minutes with assistance
- Owner can update hours or menu without developer help
- At least 2 owners indicate willingness to pay
- No critical data isolation, auth, upload, or publish failures occur

## Risks

- AI extraction corrupts fields
- Owner cannot understand draft versus live state
- Preview and published site diverge
- Uploaded menus are unreadable on mobile
- Publishing fails silently
- Data isolation is incomplete
- The product becomes too broad before proving restaurant demand

## CEO Approval Checklist

Before founding beta launch:

- Product scope approved
- First restaurants identified
- Pricing story approved
- Publish flow tested
- Security gate passed
- Support/onboarding scripts ready
