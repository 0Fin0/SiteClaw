# SiteClaw — Dashboard Service Specification

## Service Overview

The Dashboard is the owner-facing web application where restaurant owners sign up, authenticate, chat with the AI to build their website, manage their site, and handle billing. It is a Next.js 14 App Router application deployed on Vercel.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Next.js (App Router) | 14.x |
| Language | TypeScript | 5.x |
| Styling | Tailwind CSS | 3.x |
| UI Components | shadcn/ui | latest |
| Auth | Supabase Auth (`@supabase/ssr`) | latest |
| Database | Supabase (PostgreSQL) | — |
| Payments | Stripe (`stripe`, `@stripe/stripe-js`) | latest |
| Voice | OpenAI Whisper API (via API route) | — |
| State | React Server Components + `useState` for chat | — |
| Deployment | Vercel | — |

## Project Structure

```
siteclaw-dashboard/
├── src/
│   ├── app/
│   │   ├── layout.tsx                    # Root layout with Supabase provider
│   │   ├── page.tsx                      # Landing/marketing page (public)
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx            # Login form (email/password + Google OAuth)
│   │   │   ├── signup/page.tsx           # Signup form
│   │   │   ├── callback/route.ts         # OAuth callback handler
│   │   │   └── forgot-password/page.tsx
│   │   ├── (dashboard)/
│   │   │   ├── layout.tsx                # Authenticated layout with sidebar nav
│   │   │   ├── chat/page.tsx             # Main chat interface (AI conversation)
│   │   │   ├── site/page.tsx             # Site preview & publish controls
│   │   │   ├── site/settings/page.tsx    # Site settings (subdomain, custom domain)
│   │   │   ├── billing/page.tsx          # Subscription management
│   │   │   └── account/page.tsx          # Account settings
│   │   └── api/
│   │       ├── chat/route.ts             # Proxy to Pipeline API
│   │       ├── voice/route.ts            # Audio → Whisper → transcript
│   │       ├── publish/route.ts          # Trigger Cloudflare Pages build
│   │       └── stripe/
│   │           ├── checkout/route.ts     # Create Stripe Checkout session
│   │           ├── portal/route.ts       # Create Stripe Customer Portal session
│   │           └── webhook/route.ts      # Handle Stripe webhook events
│   ├── components/
│   │   ├── chat/
│   │   │   ├── ChatWindow.tsx            # Main chat container
│   │   │   ├── MessageBubble.tsx         # Individual message display
│   │   │   ├── ChatInput.tsx             # Text input + voice record button
│   │   │   ├── VoiceRecorder.tsx         # MediaRecorder wrapper
│   │   │   └── ProgressTracker.tsx       # Shows which restaurant.json sections are complete
│   │   ├── site/
│   │   │   ├── SitePreview.tsx           # iframe preview of the restaurant site
│   │   │   ├── PublishButton.tsx         # Trigger deploy
│   │   │   └── DomainSettings.tsx        # Subdomain / custom domain config
│   │   ├── billing/
│   │   │   ├── PlanSelector.tsx          # Plan comparison cards
│   │   │   ├── UsageMeter.tsx            # Edits used this period
│   │   │   └── SubscriptionStatus.tsx    # Current plan + renewal date
│   │   ├── ui/                           # shadcn/ui components (auto-generated)
│   │   └── layout/
│   │       ├── Sidebar.tsx
│   │       ├── TopBar.tsx
│   │       └── MobileNav.tsx
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts                 # Browser Supabase client
│   │   │   ├── server.ts                 # Server Supabase client (uses cookies)
│   │   │   └── middleware.ts             # Auth middleware for protected routes
│   │   ├── stripe/
│   │   │   ├── client.ts                 # Stripe instance
│   │   │   ├── plans.ts                  # Plan definitions and price IDs
│   │   │   └── webhooks.ts              # Webhook event handlers
│   │   ├── pipeline/
│   │   │   └── client.ts                 # HTTP client for Pipeline API
│   │   └── utils/
│   │       ├── validation.ts             # restaurant.json schema validation (shared)
│   │       └── format.ts                 # Date, currency formatters
│   └── types/
│       ├── restaurant.ts                 # TypeScript types generated from JSON Schema
│       ├── chat.ts                       # Chat message types
│       └── billing.ts                    # Subscription/plan types
├── middleware.ts                          # Next.js middleware (auth redirect)
├── .env.local                            # Local env vars (not committed)
├── .env.example                          # Template for env vars
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Environment Variables

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Stripe
STRIPE_SECRET_KEY=sk_live_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_STARTER=price_...
STRIPE_PRICE_PRO=price_...

# Pipeline
PIPELINE_API_URL=https://api.siteclaw.com
PIPELINE_API_KEY=sk-siteclaw-...

# OpenAI (Whisper)
OPENAI_API_KEY=sk-...

# Cloudflare (deploy trigger)
CLOUDFLARE_ACCOUNT_ID=...
CLOUDFLARE_API_TOKEN=...
CLOUDFLARE_PROJECT_NAME=siteclaw-sites

# App
NEXT_PUBLIC_APP_URL=https://app.siteclaw.com
NEXT_PUBLIC_SITES_DOMAIN=siteclaw.com
```

## Page Specifications

### `/chat` — Main Chat Interface

This is the core of the product. The chat interface is where restaurant owners interact with the AI to build and edit their website.

**Behavior:**
1. On mount, fetch the conversation history for this restaurant from Pipeline API (`GET /api/conversations/{restaurant_id}`)
2. Display messages in a scrollable chat window (newest at bottom)
3. Owner types a message or records voice → sends to Pipeline
4. Pipeline responds with AI message + optionally updates restaurant.json
5. The ProgressTracker component shows completion status (which sections of restaurant.json have data)
6. When all required fields are populated, show a "Ready to publish" indicator

**Chat Input:**
- Text input with send button
- Microphone button that toggles VoiceRecorder
- VoiceRecorder: uses `navigator.mediaDevices.getUserMedia()` → `MediaRecorder` → sends audio blob to `/api/voice` → gets transcript back → sends transcript as a chat message

**API route `/api/chat`:**
```typescript
// POST /api/chat
// Body: { restaurant_id: string, message: string }
// Response: { reply: string, restaurant_updated: boolean, progress: object }

export async function POST(req: Request) {
  const supabase = createServerClient(cookies());
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { restaurant_id, message } = await req.json();

  // Verify user owns this restaurant
  const { data: restaurant } = await supabase
    .from('restaurants')
    .select('id')
    .eq('id', restaurant_id)
    .eq('owner_id', user.id)
    .single();

  if (!restaurant) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // Check edit limit for non-founding subscribers
  // (only count if restaurant.json already has a published version)
  const { data: sub } = await supabase
    .from('subscriptions')
    .select('plan, edits_this_period, edit_limit')
    .eq('restaurant_id', restaurant_id)
    .single();

  if (sub && sub.plan !== 'founding' && sub.edits_this_period >= sub.edit_limit) {
    return NextResponse.json({
      reply: "You've reached your edit limit for this billing period. Upgrade your plan for more edits.",
      restaurant_updated: false
    });
  }

  // Forward to Pipeline
  const pipelineRes = await fetch(`${process.env.PIPELINE_API_URL}/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.PIPELINE_API_KEY}`
    },
    body: JSON.stringify({ restaurant_id, message, user_id: user.id })
  });

  const result = await pipelineRes.json();

  // If restaurant.json was updated, increment edit counter
  if (result.restaurant_updated && sub) {
    await supabase
      .from('subscriptions')
      .update({ edits_this_period: sub.edits_this_period + 1 })
      .eq('restaurant_id', restaurant_id);
  }

  return NextResponse.json(result);
}
```

**API route `/api/voice`:**
```typescript
// POST /api/voice
// Body: FormData with audio blob
// Response: { transcript: string }

export async function POST(req: Request) {
  const formData = await req.formData();
  const audio = formData.get('audio') as Blob;

  const whisperForm = new FormData();
  whisperForm.append('file', audio, 'recording.webm');
  whisperForm.append('model', 'whisper-1');
  whisperForm.append('language', 'en');

  const res = await fetch('https://api.openai.com/v1/audio/transcriptions', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${process.env.OPENAI_API_KEY}` },
    body: whisperForm
  });

  const { text } = await res.json();
  return NextResponse.json({ transcript: text });
}
```

### `/site` — Site Preview & Publish

**Behavior:**
1. Fetch current restaurant.json from Supabase Storage
2. If restaurant site is already deployed, show iframe preview at `https://{slug}.siteclaw.com`
3. If not yet deployed, show a "Preview not available yet" state with progress indicator
4. "Publish" button triggers `/api/publish` which calls Cloudflare Pages deploy hook
5. After publish, show the live URL with a "Copy link" button
6. "Republish" button for pushing updates after edits

**API route `/api/publish`:**
```typescript
// POST /api/publish
// Body: { restaurant_id: string }
// Triggers Cloudflare Pages build

export async function POST(req: Request) {
  // Auth check + ownership check (same pattern as /api/chat)

  const { restaurant_id } = await req.json();

  // Fetch restaurant.json and validate before deploying
  const supabase = createServerClient(cookies());
  const { data } = await supabase.storage
    .from('restaurant-data')
    .download(`${restaurant_id}/restaurant.json`);

  const json = JSON.parse(await data.text());

  // Validate against schema
  const valid = validateRestaurantJson(json);
  if (!valid) {
    return NextResponse.json({ error: 'Invalid restaurant data', details: valid.errors }, { status: 400 });
  }

  // Trigger Cloudflare Pages deploy hook
  const cfRes = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${process.env.CLOUDFLARE_ACCOUNT_ID}/pages/projects/${process.env.CLOUDFLARE_PROJECT_NAME}/deployments`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.CLOUDFLARE_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        branch: 'main',
        environment_variables: {
          RESTAURANT_ID: restaurant_id
        }
      })
    }
  );

  // Update restaurant record with deployment status
  await supabase
    .from('restaurants')
    .update({ last_deployed: new Date().toISOString(), deploy_status: 'building' })
    .eq('id', restaurant_id);

  return NextResponse.json({ status: 'deploying' });
}
```

### `/billing` — Subscription Management

**Behavior:**
1. Show current plan, usage (edits this period), and next billing date
2. If no subscription: show plan comparison cards with "Subscribe" buttons
3. "Subscribe" → creates Stripe Checkout session → redirects to Stripe
4. "Manage subscription" → creates Stripe Customer Portal session → redirects
5. Founding partners see a special "Founding Partner" badge with unlimited access

## Stripe Webhook Handling

The webhook at `/api/stripe/webhook` handles these events:

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Create subscription record in Supabase, link Stripe customer ID to user |
| `customer.subscription.updated` | Update plan, edit_limit, billing period in Supabase |
| `customer.subscription.deleted` | Mark subscription as cancelled, set grace period |
| `invoice.paid` | Reset `edits_this_period` to 0 (new billing cycle) |
| `invoice.payment_failed` | Flag account, send notification via Supabase Edge Function |

## Middleware (Auth Protection)

```typescript
// middleware.ts
import { createMiddlewareClient } from '@supabase/ssr';
import { NextResponse } from 'next/server';

export async function middleware(req) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req, res });
  const { data: { session } } = await supabase.auth.getSession();

  // Protected routes
  if (req.nextUrl.pathname.startsWith('/chat') ||
      req.nextUrl.pathname.startsWith('/site') ||
      req.nextUrl.pathname.startsWith('/billing') ||
      req.nextUrl.pathname.startsWith('/account')) {
    if (!session) {
      return NextResponse.redirect(new URL('/login', req.url));
    }
  }

  // Auth routes — redirect to chat if already logged in
  if (req.nextUrl.pathname.startsWith('/login') ||
      req.nextUrl.pathname.startsWith('/signup')) {
    if (session) {
      return NextResponse.redirect(new URL('/chat', req.url));
    }
  }

  return res;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api/stripe/webhook).*)']
};
```

## Key Implementation Notes for Codex

1. **Use App Router exclusively** — no Pages Router. All routes use `src/app/` directory.
2. **Server Components by default** — only add `'use client'` where interactivity is needed (chat input, voice recorder, plan selector).
3. **Supabase SSR pattern** — use `@supabase/ssr` with `createServerClient(cookies())` in Server Components and API routes. Use `createBrowserClient()` only in Client Components.
4. **shadcn/ui** — install via `npx shadcn-ui@latest init` and add components as needed. Do not install a full component library.
5. **No global state management library** — React Server Components + props + minimal useState is sufficient for this app.
6. **Streaming chat responses** — if Pipeline supports streaming, use ReadableStream in the chat API route and EventSource or fetch with reader on the client. Otherwise, simple request/response is acceptable for MVP.
7. **Edit counting** — an "edit" is defined as a Pipeline interaction that results in a `restaurant_updated: true` response. Conversations that don't change the restaurant.json (e.g., asking questions) don't count.
