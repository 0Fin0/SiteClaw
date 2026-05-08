# SiteClaw — Build Order

## Overview

This document defines the sequence in which the SiteClaw system should be built. Each phase produces a working, testable deliverable. Phases are ordered by dependency — later phases depend on earlier ones.

---

## Phase 0: Project Scaffolding

**Goal:** Create all four repos with correct tech stacks, empty project structures, and environment variable templates.

### Tasks

1. **siteclaw-shared**
   - `npm init` with TypeScript
   - Copy `restaurant.schema.json` from Schema spec
   - Generate TypeScript types from the JSON Schema using `json-schema-to-typescript`
   - Export validation utility using `ajv` + `ajv-formats`
   - Export deep merge utility (lodash `mergeWith`)
   - Export type definitions
   - Publish as npm package or configure as git submodule

2. **siteclaw-dashboard**
   - `npx create-next-app@14 --typescript --tailwind --app --src-dir`
   - Install: `@supabase/ssr`, `stripe`, `@stripe/stripe-js`
   - Init shadcn/ui: `npx shadcn-ui@latest init`
   - Create `.env.example` with all env vars from Dashboard spec
   - Create project structure (empty files for all routes, components, lib modules)

3. **siteclaw-pipeline**
   - `npm init` with TypeScript + Express
   - Install: `@anthropic-ai/sdk`, `openai`, `@supabase/supabase-js`, `ajv`, `ajv-formats`, `lodash`
   - Create Dockerfile and railway.toml from Infrastructure spec
   - Create `.env.example` with all env vars from Pipeline spec
   - Create project structure (empty files for all agents, services, routes)

4. **siteclaw-renderer**
   - `npm create astro@latest` (empty template, TypeScript strict)
   - Install: `@astrojs/tailwind`, `@astrojs/cloudflare`
   - Configure astro.config.mjs for static output + Tailwind + Cloudflare adapter
   - Create wrangler.toml from Infrastructure spec
   - Create `.env.example`
   - Create project structure (empty files for all pages, components, utils)

### Verification
- Each repo runs its dev server without errors (even if pages are empty)
- `npm run build` succeeds in all four repos
- Shared package can be imported by other three repos

---

## Phase 1: Database & Auth

**Goal:** Supabase fully configured with tables, RLS, storage, and auth working end-to-end in the Dashboard.

### Tasks

1. Run all SQL migrations from Database spec in order (tables → RLS → storage → triggers)
2. Implement Dashboard auth pages:
   - `/login` — email/password form + Google OAuth button
   - `/signup` — registration form
   - `/callback` — OAuth callback handler
   - `/forgot-password` — password reset
3. Implement `middleware.ts` for auth route protection
4. Implement Supabase client utilities in `src/lib/supabase/` (server.ts, client.ts, middleware.ts)
5. Verify the `handle_new_user` trigger creates a restaurant + subscription on signup
6. Implement `(dashboard)/layout.tsx` — authenticated layout with sidebar showing: Chat, My Site, Billing, Account

### Verification
- User can sign up with email/password → redirected to /chat
- User can sign up with Google OAuth → redirected to /chat
- Unauthenticated users redirected to /login
- Database has restaurant + subscription records after signup
- Supabase Storage bucket `restaurant-data` exists and is accessible with service role key

---

## Phase 2: Chat Interface (Frontend)

**Goal:** Working chat UI in the Dashboard that sends messages and displays responses. Pipeline integration is mocked at this stage.

### Tasks

1. Build chat components:
   - `ChatWindow.tsx` — scrollable message list, auto-scroll to bottom
   - `MessageBubble.tsx` — user messages (right-aligned) and assistant messages (left-aligned)
   - `ChatInput.tsx` — text input with send button + microphone button
   - `VoiceRecorder.tsx` — MediaRecorder integration, records audio, shows recording state
   - `ProgressTracker.tsx` — shows which sections of restaurant.json are complete (sidebar or top bar)
2. Build `/api/chat` route — for now, mock the Pipeline response:
   ```json
   { "reply": "Thanks! I've noted that. What else can you tell me?", "restaurant_updated": false, "progress": {} }
   ```
3. Build `/api/voice` route — forward audio to Whisper API, return transcript
4. Wire everything together: type message → send → display response → scroll

### Verification
- Chat messages appear in the UI with correct styling (user right, assistant left)
- Voice recording works → transcript appears as a sent message
- Mock responses display correctly
- Message history persists across page refreshes (stored in `messages` table)

---

## Phase 3: Pipeline (Core AI)

**Goal:** Working Pipeline service that receives chat messages, classifies intent, extracts restaurant data, and writes to restaurant.json.

### Tasks

1. Implement Express server with `/chat`, `/conversations/:restaurant_id`, `/health` routes
2. Implement API key authentication middleware
3. Implement Orchestrator agent:
   - GPT-4o Mini intent classification (onboarding, edit, question, off_topic)
   - Route to appropriate handler
4. Implement Intake agent:
   - System prompt with conversation flow (name → phone → address → hours → cuisine → menu → etc.)
   - Data extraction from each message
   - Call Content Generator for menu descriptions and SEO
5. Implement Editor agent:
   - Fetch current restaurant.json
   - Identify which fields to update
   - Deep merge and save
6. Implement Content Generator:
   - Claude Sonnet integration for menu descriptions, about section, SEO metadata, tagline
7. Implement Validator:
   - ajv schema validation after every write
8. Implement restaurant-json service:
   - `readRestaurantJson(restaurantId)` — fetch from Supabase Storage
   - `writeRestaurantJson(restaurantId, updates)` — merge, validate, save
9. Implement message storage — persist all messages to Supabase `messages` table
10. Update Dashboard `/api/chat` route to call real Pipeline instead of mock

### Verification
- Send "My restaurant is called Mario's Trattoria" → Pipeline extracts name, writes to restaurant.json
- Send "We're open Monday to Friday 11 to 9" → Pipeline extracts hours correctly
- Send "Add bruschetta for $12" → Pipeline creates menu entry with AI-generated description
- Invalid data is caught by validator and reported back via chat
- Conversation history loads correctly on page refresh
- Edit counter increments when restaurant.json is updated

---

## Phase 4: Renderer (Static Sites)

**Goal:** Working Astro site that renders from restaurant.json and looks professional.

### Tasks

1. Implement pre-build script (`scripts/fetch-data.ts`) — fetch restaurant.json from Supabase
2. Implement data loading utility (`src/utils/load-data.ts`)
3. Implement `BaseLayout.astro` — HTML shell, meta tags, font loading based on font_style, CSS custom properties from branding colors
4. Implement `SEOHead.astro` — meta tags, Open Graph, JSON-LD Restaurant structured data
5. Implement homepage components:
   - Hero, MenuCategory, MenuItem, HoursTable, ContactInfo, Gallery, Testimonials, Specials, SocialLinks, OrderButton, ReservationButton, Footer
6. Implement pages:
   - `index.astro` — homepage composing all sections (skip empty ones)
   - `menu.astro` — full menu with categories
   - `contact.astro` — contact info + map + hours
7. Implement color theming (CSS custom properties from branding or cuisine defaults)
8. Implement font loading (Google Fonts based on font_style)
9. Mobile-first responsive design for all pages
10. Test with the full example restaurant.json from Schema spec

### Verification
- `npm run build` succeeds with example restaurant.json
- Homepage renders all sections with correct data
- Menu page shows categories and items with proper formatting
- Contact page shows map embed when coordinates exist
- Site looks good on mobile (375px), tablet (768px), desktop (1200px)
- Lighthouse Performance > 95, Accessibility > 90
- Missing optional data (no gallery, no specials) doesn't break the build

---

## Phase 5: Deployment & Publishing

**Goal:** Owner clicks "Publish" in Dashboard → site builds on Cloudflare Pages → live at {slug}.siteclaw.com.

### Tasks

1. Deploy Pipeline to Railway:
   - Push code → Railway auto-builds from Dockerfile
   - Set environment variables
   - Configure custom domain (api.siteclaw.com)
2. Deploy Dashboard to Vercel:
   - Connect repo → Vercel auto-builds
   - Set environment variables
   - Configure custom domain (app.siteclaw.com)
3. Set up Cloudflare Pages project:
   - Connect siteclaw-renderer repo
   - Set build configuration
   - Set environment variables
4. Implement Dashboard `/api/publish` route:
   - Validate restaurant.json
   - Trigger Cloudflare Pages build via API with RESTAURANT_ID
   - Assign subdomain after build
5. Implement Dashboard site preview page:
   - iframe showing {slug}.siteclaw.com
   - Publish/republish button
   - Live URL with copy button
6. Configure DNS records (see Infrastructure spec)

### Verification
- Pipeline responds at api.siteclaw.com/health
- Dashboard loads at app.siteclaw.com
- Owner completes chat → clicks Publish → site appears at {slug}.siteclaw.com within 2 minutes
- Site preview iframe loads in Dashboard

---

## Phase 6: Billing (Stripe)

**Goal:** Working subscription flow — owners can subscribe, manage, and have their edits tracked.

### Tasks

1. Create Stripe Products and Prices (Starter $29/mo, Pro $79/mo)
2. Implement `/api/stripe/checkout` — create Checkout session, redirect
3. Implement `/api/stripe/portal` — create Customer Portal session, redirect
4. Implement `/api/stripe/webhook` — handle all lifecycle events (see Dashboard spec)
5. Implement Billing page in Dashboard:
   - Current plan display
   - Usage meter (edits this period / limit)
   - Plan comparison cards
   - Subscribe / Manage buttons
6. Implement edit limit enforcement in `/api/chat` — block edits when limit reached (Starter plan)
7. Test founding partner flow — first 3 signups get plan='founding' automatically

### Verification
- New user signs up → gets founding plan (if < 3 exist) or trialing/starter
- Owner can subscribe to Starter or Pro via Stripe Checkout
- Owner can manage subscription via Stripe Customer Portal
- Edit counter increments on restaurant.json updates
- Starter plan blocks edits after 5 per period
- Edit counter resets on new billing cycle (invoice.paid webhook)

---

## Phase 7: Polish & Launch Prep

**Goal:** Production-ready for founding partners.

### Tasks

1. Error handling: friendly error messages throughout chat, never stack traces
2. Loading states: skeleton loaders on chat page, publish button shows progress
3. Empty states: helpful guidance when no messages, no site published yet
4. Onboarding: first-time user sees a welcome message from the AI explaining what to do
5. Mobile responsive: verify all Dashboard pages work on mobile
6. Security audit: run through the checklist in Infrastructure spec
7. Test end-to-end with 3 test restaurants with different cuisine types and data completeness levels
8. Set up custom error pages (404, 500) on Dashboard

### Verification
- Complete end-to-end flow works: signup → chat → populate all sections → publish → live site
- Flow works with minimal data (just name + phone + hours)
- Flow works with full data (every field populated)
- All Dashboard pages responsive on mobile
- No console errors in production build
