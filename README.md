# SiteClaw

SiteClaw is a SwiftUI prototype for an AI-powered website builder for local restaurants.

The product concept comes from the ISYS 556 SiteClaw project: restaurant owners can describe their business by voice or text, then SiteClaw generates a professional restaurant website with menu, hours, local SEO, preview, JSON, and local publishing/export controls.

## Current Prototype

This version is a SwiftUI app with Mac and iOS targets. The current judge-facing shell keeps the bottom tab bar focused on the main demo path:

- Talk: voice-onboarding prototype for capturing the owner conversation
- Build: correction and generation surface for the captured restaurant details
- Preview: generated restaurant website mockup with a compact Review & Export path for owner checklist, local website publishing, static `index.html` export, and proof tools

Dashboard and generated `restaurant.json` are still available from Preview under Review & Export > Proof Tools, but they no longer compete with the live demo flow as top-level tabs.

The AI, voice, and deployment behavior still has demo fallbacks so the project runs immediately in Xcode. The Talk tab can request a short-lived OpenAI Realtime session token from the local backend, stream native microphone audio to OpenAI Realtime over WebSocket, capture live transcript turns, and call the backend to generate structured website draft copy.

The strongest current MVP proof is:

```text
Talk -> Build -> Preview -> Review & Export -> Open Site
```

Open Site publishes the generated HTML to the local backend and opens the real restaurant website in Safari. After publishing, the app shows a Published Site success state with the local URL, Copy Site Link, Open Again, and a QR code for presentation. The current generated site template includes customer-facing Home/Menu/Hours/Location navigation, tighter menu cards, full week hours, location, and a Plan your visit CTA. Internal proof wording such as missing phone placeholders, owner-only menu notes, and draft-review copy is intentionally hidden from the public site.

## Tech Direction

Planned production stack:

- SwiftUI for the app
- OpenAI or Claude for AI-generated website content
- OpenAI Realtime or transcription models for voice input
- Supabase for restaurant/user data
- Astro for generated static restaurant sites
- Cloudflare Pages for hosting published websites

## Engineering Docs

Carlo's build files are checked in under:

```text
Docs/engineering/
```

They define the longer-term architecture around `restaurant.json`, Supabase, pipeline services, Astro rendering, and deployment order. The current SwiftUI prototype is intentionally smaller, but future work should align with those docs, especially the `restaurant.json` contract.

## Open In Xcode

Open:

```bash
open SiteClaw.xcodeproj
```

Then choose one of these schemes:

- `SiteClaw` to run on `My Mac`
- `SiteClaw iOS` to run on an iPhone Simulator

## Build Check

The prototype was verified with:

```bash
xcodebuild -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SiteClaw.xcodeproj -scheme 'SiteClaw iOS' -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Realtime Backend

The repo includes a local backend that creates short-lived OpenAI Realtime client secrets:

```bash
cd Backend
cp .env.example .env
```

Add your `OPENAI_API_KEY` to `Backend/.env`, then from the repo root run:

```bash
node Backend/server.mjs
```

If Terminal cannot find `node`, use the bundled Codex runtime from the repo root:

```bash
/Applications/Codex.app/Contents/Resources/node Backend/server.mjs
```

Health check:

```bash
curl http://localhost:8787/health
```

Create a Realtime client secret:

```bash
curl -X POST http://localhost:8787/api/realtime/session \
  -H "Content-Type: application/json" \
  -d '{"restaurantName":"Sunset Grill"}'
```

Once the backend is running, press Start in Talk to request a Realtime session token and begin streaming microphone audio. The app converts native mic input to 24 kHz PCM16 chunks, sends them with `input_audio_buffer.append`, and fills the transcript as Realtime transcription turns complete. If the backend is missing or `OPENAI_API_KEY` is not configured, the app shows the backend error in Talk.

Generate website draft copy:

```bash
curl -X POST http://localhost:8787/api/generate/draft \
  -H "Content-Type: application/json" \
  -d '{"transcript":"My restaurant is called Sunset Grill. We serve American burgers and sandwiches in San Jose. We are open Monday through Saturday from 10 AM to 8 PM, and Sunday from 11 AM to 6 PM. Our menu items are cheeseburgers for $12.99, chicken sandwiches for $11.49, fries for $4.99, and lemonade for $3.49. What makes us special is fresh ingredients, fast service, and a friendly neighborhood atmosphere.","restaurant":{},"draft":{},"restaurant_json":{}}'
```

The app's Generate Website Draft button calls this endpoint first, then falls back to the local demo generator if the backend is unavailable.

Publish the generated site locally:

```bash
curl -X POST http://localhost:8787/api/publish/local \
  -H "Content-Type: application/json" \
  -d '{"slug":"sunset-grill","html":"<!doctype html><html><body><h1>Sunset Grill</h1></body></html>","restaurant_json":{"basics":{"name":"Sunset Grill"}}}'
```

The app's Review & Export screen uses this endpoint from the Open Site button. It writes `Backend/generated-sites/{slug}/index.html` and `restaurant.json`, then serves the real generated page at `http://localhost:8787/sites/{slug}/`.

List locally generated sites:

```bash
curl http://localhost:8787/api/sites
```

Inspect one locally generated site:

```bash
curl http://localhost:8787/api/sites/sunset-grill
```

These registry endpoints read from `Backend/generated-sites/` and are the current backend-lite proof that published pages are persisted by slug before full Supabase storage is added.

## Next Steps

- Rehearse the Talk -> Build -> Preview -> Review & Export -> Open Site flow on an iPhone Simulator with the Sunset Grill script
- Use Review & Export -> Open Site when you want to prove SiteClaw produced a real local website from the generated HTML and `restaurant.json`
- Show the Published Site success state after Open Site: local URL, Copy Site Link, Open Again, and QR code
- Use `GET /api/sites` and `GET /api/sites/sunset-grill` if judges ask where the generated website is persisted before Supabase
- Keep owner-review language inside the app; the public generated website should stay customer-facing
- Park the minor first-start audio transcription stall as a known follow-up unless it becomes repeatable during rehearsal
- Keep Supabase/OAuth/Stripe behind the website creation story unless the core publish flow is already presentation-ready
- Later: replace the single-file static export with the full Astro renderer and add Cloudflare Pages publishing
