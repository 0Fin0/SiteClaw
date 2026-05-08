# SiteClaw

SiteClaw is a SwiftUI prototype for an AI-powered website builder for local restaurants.

The product concept comes from the ISYS 556 SiteClaw project: restaurant owners can describe their business by voice or text, then SiteClaw generates a professional restaurant website with menu, hours, local SEO, preview, updates, and publishing status.

## Current Prototype

This first version is a SwiftUI app with Mac and iOS targets. It has six main tabs:

- Talk: voice-onboarding prototype for capturing the owner conversation
- Build: restaurant intake and AI-style onboarding conversation
- Dashboard: launch readiness, MVP checklist, recent activity, and publish status
- Preview: generated restaurant website mockup plus static `index.html` export
- JSON: generated `restaurant.json` data contract preview
- Updates: voice-style quick updates for hours, menus, and announcements

The AI, voice, and deployment behavior still has demo fallbacks so the project runs immediately in Xcode. The Talk tab can request a short-lived OpenAI Realtime session token from the local backend, stream native microphone audio to OpenAI Realtime over WebSocket, capture live transcript turns, and call the backend to generate structured website draft copy.

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

Health check:

```bash
curl http://localhost:8787/health
```

Create a Realtime client secret:

```bash
curl -X POST http://localhost:8787/api/realtime/session \
  -H "Content-Type: application/json" \
  -d '{"restaurantName":"Pho Lotus Kitchen"}'
```

Once the backend is running, press Start in the Talk tab to request a Realtime session token and begin streaming microphone audio. The app converts native mic input to 24 kHz PCM16 chunks, sends them with `input_audio_buffer.append`, and fills the transcript as Realtime transcription turns complete. If the backend is missing or `OPENAI_API_KEY` is not configured, the app shows the backend error in the Talk tab.

Generate website draft copy:

```bash
curl -X POST http://localhost:8787/api/generate/draft \
  -H "Content-Type: application/json" \
  -d '{"transcript":"Family-owned Vietnamese restaurant in San Jose with pho and rice bowls.","restaurant":{},"draft":{},"restaurant_json":{}}'
```

The app's Generate Website Draft button calls this endpoint first, then falls back to the local demo generator if the backend is unavailable.

## Next Steps

- Add real restaurant intake fields for menu editing
- Add Realtime assistant audio playback for spoken SiteClaw responses
- Replace the single-file static export with the full Astro renderer
- Add Cloudflare Pages publishing
- Add collaborators through GitHub after the remote repository is published
