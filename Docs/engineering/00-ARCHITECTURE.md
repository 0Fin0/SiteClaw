# SiteClaw — System Architecture

## What This Is

SiteClaw is an AI-powered website builder for local restaurants and small food businesses. Restaurant owners sign up, have a conversation with an AI assistant, and get a professional static website deployed automatically — no technical skill required.

## Core Concept

The entire system revolves around one data contract: `restaurant.json`. Every piece of restaurant data (name, menu, hours, branding, etc.) lives in this single JSON file. The AI conversation populates it, the renderer reads it, and the deployment pipeline ships it.

```
Owner signs up → Chats with AI → restaurant.json populated → Astro builds site → Cloudflare deploys
```

## Service Map

SiteClaw is composed of 4 independent services:

| Service | Tech | Hosted On | Repo Name | Purpose |
|---------|------|-----------|-----------|---------|
| **Dashboard** | Next.js 14 (App Router) | Vercel | `siteclaw-dashboard` | Owner-facing app: auth, chat UI, site management, billing |
| **Pipeline** | OpenClaw + Claude Sonnet | Railway | `siteclaw-pipeline` | AI conversation engine that generates restaurant.json |
| **Renderer** | Astro 4.x | Cloudflare Pages | `siteclaw-renderer` | Static site generator that reads restaurant.json and outputs HTML |
| **Shared** | TypeScript types + JSON Schema | npm package / git submodule | `siteclaw-shared` | restaurant.json schema, validation utils, shared types |

## Data Flow (Happy Path)

```
1. Owner signs up via Dashboard (Supabase Auth)
2. Owner starts a conversation in the chat UI
3. Dashboard sends messages to Pipeline API (REST)
4. Pipeline (OpenClaw + Claude Sonnet) extracts restaurant data from conversation
5. Pipeline writes/updates restaurant.json to Supabase Storage (bucket: restaurant-data/{restaurant_id}/restaurant.json)
6. Pipeline validates restaurant.json against the shared JSON Schema
7. When owner clicks "Publish" (or auto-publish on sufficient data):
   a. Dashboard triggers a build webhook on Cloudflare Pages
   b. Cloudflare Pages build step fetches restaurant.json from Supabase Storage
   c. Astro renders static HTML from the JSON
   d. Cloudflare deploys to {subdomain}.siteclaw.com
8. Owner sees their live site URL in the Dashboard

```

## Edit Flow (Monthly Updates)

```
1. Owner returns to Dashboard, opens chat
2. Owner says "Update my hours" or "Add a new menu item"
3. Pipeline fetches current restaurant.json from Supabase Storage
4. Pipeline applies partial update (merge, not overwrite)
5. Pipeline validates updated JSON against schema
6. If valid: writes back to Supabase Storage, triggers re-deploy
7. If invalid: asks owner for clarification via chat
```

## Authentication & Authorization

- **Auth provider**: Supabase Auth (email/password + Google OAuth)
- **Session management**: Supabase handles JWT tokens, Dashboard uses `@supabase/ssr` for server-side session
- **Authorization**: Supabase Row Level Security (RLS) ensures owners can only access their own restaurant data
- **API auth between services**: Dashboard → Pipeline uses a shared API key in the `Authorization` header (stored as env var)

## Billing

- **Provider**: Stripe
- **Plans**:
  - `founding` — Free forever (first 3 customers, manually assigned)
  - `starter` — $29/month (5 edits/month, 1 site, siteclaw.com subdomain)
  - `pro` — $79/month (unlimited edits, 1 site, custom domain support)
- **Integration**: Stripe Checkout for signup, Stripe Customer Portal for management, Stripe Webhooks for lifecycle events
- **Edit tracking**: Each successful restaurant.json update increments `edits_this_period` in the `subscriptions` table. Reset on billing cycle via Stripe webhook.

## Voice Input

- **Provider**: OpenAI Whisper API
- **Implementation**: Browser MediaRecorder API captures audio in the Dashboard, sends to a Next.js API route, which forwards to Whisper, returns transcript, then sends transcript to Pipeline as a normal chat message
- **Availability**: All plans (core differentiator, not a premium add-on)

## Model Routing

| Task | Model | Reason |
|------|-------|--------|
| Content generation (menu descriptions, SEO text, about section) | Claude Sonnet | Output quality IS the product |
| Conversation routing, intent classification | GPT-4o Mini | Fast, cheap, good enough for classification |
| Voice transcription | OpenAI Whisper | Best-in-class speech-to-text |
| Local LLM inference | Ollama (deferred) | Not until Mac Studio arrives + 100+ customers |

## Environments

| Environment | Dashboard | Pipeline | Renderer |
|-------------|-----------|----------|----------|
| **Development** | localhost:3000 | localhost:8000 | localhost:4321 |
| **Staging** | staging.siteclaw.com | staging-api.siteclaw.com | staging-sites.siteclaw.com |
| **Production** | app.siteclaw.com | api.siteclaw.com | {subdomain}.siteclaw.com |

## File Storage

- **Supabase Storage** bucket: `restaurant-data`
- Path pattern: `{restaurant_id}/restaurant.json`
- Path pattern for images: `{restaurant_id}/images/{filename}`
- All access gated by RLS policies matching `auth.uid()` to restaurant owner

## Key Design Decisions

1. **Static output, not server-rendered**: Restaurant sites are pure static HTML on Cloudflare Pages. No server costs per-site, instant global CDN, near-zero marginal cost per customer.
2. **Single JSON contract**: All data flows through restaurant.json. This is the only interface between Pipeline and Renderer. If the JSON is valid, the site builds.
3. **Cloud-first**: No local Docker, no local databases. Everything runs on managed services from day one.
4. **Partial updates, not full regeneration**: The edit flow merges changes into existing restaurant.json. The AI never regenerates the entire file — it patches what changed.
5. **Subdomain routing**: Each restaurant site gets `{slug}.siteclaw.com`. Custom domains are a Pro feature handled via Cloudflare DNS API.
