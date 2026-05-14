# SiteClaw — Infrastructure & Deployment

## Service Hosting Map

| Service | Platform | URL Pattern | Deploy Method |
|---------|----------|-------------|---------------|
| Dashboard | Vercel | `app.siteclaw.com` | Git push to `main` branch |
| Pipeline | Railway | `api.siteclaw.com` | Git push to `main` branch |
| Renderer | Cloudflare Pages | `{slug}.siteclaw.com` | API-triggered build |
| Database | Supabase | `xxxxx.supabase.co` | Managed (migrations via CLI) |
| DNS | Cloudflare | `siteclaw.com` | Cloudflare Dashboard / API |

## Domain & DNS Setup

**Registrar:** Any (transfer DNS to Cloudflare for management)

**DNS Records:**

| Record | Name | Value | Proxy |
|--------|------|-------|-------|
| A | `siteclaw.com` | Vercel IP | Off (Vercel manages SSL) |
| CNAME | `app` | `cname.vercel-dns.com` | Off |
| CNAME | `api` | Railway-provided CNAME | Off |
| CNAME | `*.siteclaw.com` | Cloudflare Pages CNAME | On |

The wildcard CNAME (`*.siteclaw.com`) routes all restaurant subdomains to Cloudflare Pages. Each restaurant's subdomain is configured as a custom domain on the Cloudflare Pages project.

## Vercel Configuration (Dashboard)

**`vercel.json`:**
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["iad1"],
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-anon-key",
    "SUPABASE_SERVICE_ROLE_KEY": "@supabase-service-role-key",
    "STRIPE_SECRET_KEY": "@stripe-secret-key",
    "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY": "@stripe-publishable-key",
    "STRIPE_WEBHOOK_SECRET": "@stripe-webhook-secret",
    "STRIPE_PRICE_STARTER": "@stripe-price-starter",
    "STRIPE_PRICE_PRO": "@stripe-price-pro",
    "PIPELINE_API_URL": "@pipeline-api-url",
    "PIPELINE_API_KEY": "@pipeline-api-key",
    "OPENAI_API_KEY": "@openai-api-key",
    "CLOUDFLARE_ACCOUNT_ID": "@cloudflare-account-id",
    "CLOUDFLARE_API_TOKEN": "@cloudflare-api-token",
    "CLOUDFLARE_PROJECT_NAME": "siteclaw-sites"
  }
}
```

**Environment variables:** Set via Vercel Dashboard → Project → Settings → Environment Variables. Use the `@` reference syntax to link to Vercel secrets.

## Railway Configuration (Pipeline)

**`railway.toml`:**
```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 5
numReplicas = 1

[service]
internalPort = 8000
```

**Environment variables:** Set via Railway Dashboard → Service → Variables:

```
ANTHROPIC_API_KEY=<anthropic-api-key>
OPENAI_API_KEY=<openai-api-key>
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<supabase-service-role-key>
PIPELINE_API_KEY=<pipeline-api-key>
PORT=8000
NODE_ENV=production
```

**Custom domain:** Add `api.siteclaw.com` via Railway Dashboard → Service → Settings → Custom Domain. Railway provides a CNAME to point your DNS to.

## Cloudflare Pages Configuration (Renderer)

**Project setup:**
1. Create a Cloudflare Pages project named `siteclaw-sites`
2. Connect to the `siteclaw-renderer` git repo
3. Build settings:
   - Build command: `npm run build`
   - Build output directory: `dist`
   - Root directory: `/`

**Environment variables (set in Cloudflare Pages Dashboard):**
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<supabase-service-role-key>
RESTAURANT_ID=  (set per-deploy via API)
```

**Deploy hook:** The Dashboard's `/api/publish` endpoint triggers builds via the Cloudflare API. The `RESTAURANT_ID` is passed as a build-time environment variable so the pre-build script knows which restaurant.json to fetch.

**Subdomain assignment:** After a successful build, the Dashboard calls the Cloudflare API to assign a custom domain:

```typescript
// Assign subdomain after successful deploy
async function assignSubdomain(slug: string, projectName: string) {
  await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects/${projectName}/domains`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CLOUDFLARE_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name: `${slug}.siteclaw.com` })
    }
  );
}
```

## Supabase Setup

**Project creation:**
1. Create project at supabase.com
2. Region: US East (to minimize latency to Vercel and Railway)
3. Run migrations in order (see Database spec, section: Migration Order)
4. Create storage bucket `restaurant-data`

**Supabase CLI (for migrations):**
```bash
# Install
npm install -g supabase

# Login
supabase login

# Link to project
supabase link --project-ref xxxxx

# Push migrations
supabase db push

# Generate types (for Dashboard TypeScript)
supabase gen types typescript --project-id xxxxx > src/types/supabase.ts
```

## Stripe Setup

1. Create Stripe account
2. Create two Products:
   - **SiteClaw Starter** — $29/month recurring
   - **SiteClaw Pro** — $79/month recurring
3. Note the Price IDs (`price_xxx`) for each → set as env vars
4. Configure webhook endpoint: `https://app.siteclaw.com/api/stripe/webhook`
5. Subscribe to events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`, `invoice.payment_failed`
6. Note webhook signing secret → set as `STRIPE_WEBHOOK_SECRET`

## API Key Generation

The Pipeline API key (`PIPELINE_API_KEY`) is a shared secret between Dashboard and Pipeline. Generate it:

```bash
openssl rand -hex 32
# Output: <generated-pipeline-api-key>
```

Set the same value in both Vercel (Dashboard) and Railway (Pipeline) environment variables.

## Local Development

### Dashboard
```bash
cd siteclaw-dashboard
cp .env.example .env.local
# Fill in env vars (use Supabase dev project + Stripe test keys)
npm install
npm run dev
# → http://localhost:3000
```

### Pipeline
```bash
cd siteclaw-pipeline
cp .env.example .env
# Fill in env vars
npm install
npm run dev
# → http://localhost:8000
```

### Renderer
```bash
cd siteclaw-renderer
cp .env.example .env
# Set RESTAURANT_ID to a test restaurant UUID
# Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
npm install
npm run build  # Fetches data + builds
npm run preview
# → http://localhost:4321
```

## Monitoring & Logging

**MVP approach (no extra services):**

| What | Where |
|------|-------|
| Dashboard errors | Vercel Dashboard → Logs |
| Pipeline errors | Railway Dashboard → Logs |
| Build failures | Cloudflare Pages → Deployments |
| Database queries | Supabase Dashboard → Logs |
| Stripe events | Stripe Dashboard → Events |

**Future (post-MVP):** Add Sentry for error tracking, Axiom or Logflare for centralized logging.

## Cost Estimates (MVP / Low Volume)

| Service | Free Tier | Expected Monthly Cost |
|---------|-----------|----------------------|
| Vercel | 100GB bandwidth, serverless functions | $0 (free tier) |
| Railway | $5 credit/month | ~$5–10 |
| Cloudflare Pages | 500 builds/month, unlimited bandwidth | $0 (free tier) |
| Supabase | 500MB DB, 1GB storage, 50K auth users | $0 (free tier) |
| Stripe | 2.9% + 30¢ per transaction | Variable |
| Anthropic API (Claude Sonnet) | Pay-per-token | ~$50–100/month at founding scale |
| OpenAI API (GPT-4o Mini + Whisper) | Pay-per-token | ~$10–20/month at founding scale |
| **Total** | | **~$65–135/month** |

## Security Checklist

- [ ] All API keys stored as environment variables, never in code
- [ ] Supabase RLS enabled on all tables
- [ ] Stripe webhook signature verification enabled
- [ ] Pipeline API key validated on every request
- [ ] CORS configured on Pipeline to only accept requests from `app.siteclaw.com`
- [ ] Supabase service role key never exposed to browser
- [ ] Rate limiting on Pipeline chat endpoint (10 messages/min/restaurant)
- [ ] Input sanitization on all user-provided text before writing to restaurant.json
- [ ] No secrets in git repos (`.env` files in `.gitignore`)
