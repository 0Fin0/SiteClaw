# SiteClaw Backend Secrecy Boundary

The native SwiftUI app must never contain long-lived provider secrets.

## Native App May Hold

- Supabase anon/public configuration
- User session tokens issued by Supabase Auth
- Short-lived OpenAI Realtime client secrets minted by the backend
- Public site URLs and restaurant IDs owned by the signed-in user

## Backend Must Hold

- `OPENAI_API_KEY`
- Supabase service role key
- Stripe secret key
- Stripe webhook signing secret
- Cloudflare API token
- Any future provider token that can read, write, bill, deploy, or impersonate users

## Gateway Rule

SwiftUI calls a SiteClaw gateway surface for privileged work. The gateway validates the user, checks restaurant ownership, performs the provider call, and returns only the safe response the app needs.

Examples:

- Auth shell: app starts with Supabase Auth client flow, backend performs privileged restaurant setup if needed.
- Billing: app asks backend to create Stripe Checkout or Customer Portal sessions, then opens the returned URL.
- Storage: app can preview `restaurant.json`, but service-role writes to Supabase Storage happen on the backend.
- Realtime: app receives only short-lived client secrets from `POST /api/realtime/session`.

This boundary lets Carlo own account, billing, schema, and gateway work while Omar continues the voice and Realtime backend without exposing provider keys in the app.
