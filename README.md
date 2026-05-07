# SiteClaw

SiteClaw is a SwiftUI prototype for an AI-powered website builder for local restaurants.

The product concept comes from the ISYS 556 SiteClaw project: restaurant owners can describe their business by voice or text, then SiteClaw generates a professional restaurant website with menu, hours, local SEO, preview, updates, and publishing status.

## Current Prototype

This first version is a SwiftUI app with Mac and iOS targets. It has five main tabs:

- Talk: voice-onboarding prototype for capturing the owner conversation
- Build: restaurant intake and AI-style onboarding conversation
- Dashboard: launch readiness, MVP checklist, recent activity, and publish status
- Preview: generated restaurant website mockup
- Updates: voice-style quick updates for hours, menus, and announcements

The AI, voice, and deployment behavior is currently simulated so the project runs immediately in Xcode. The Talk tab is designed to be replaced by OpenAI Realtime once a backend can mint short-lived Realtime session tokens.

## Tech Direction

Planned production stack:

- SwiftUI for the app
- OpenAI or Claude for AI-generated website content
- OpenAI Realtime or transcription models for voice input
- Supabase for restaurant/user data
- Astro for generated static restaurant sites
- Cloudflare Pages for hosting published websites

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

## Next Steps

- Add real restaurant intake fields for menu editing
- Wire `RealtimeSessionService` into the Talk tab
- Add real OpenAI Realtime microphone flow using the backend session-token endpoint
- Add a backend endpoint for AI generation
- Add generated-site export or Cloudflare Pages publishing
- Add collaborators through GitHub after the remote repository is published
