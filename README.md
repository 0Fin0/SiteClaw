# SiteClaw

SiteClaw is a SwiftUI prototype for an AI-powered website builder for local restaurants.

The product concept comes from the ISYS 556 SiteClaw project: restaurant owners can describe their business by voice or text, then SiteClaw generates a professional restaurant website with menu, hours, local SEO, preview, updates, and publishing status.

## Current Prototype

This first version is a macOS SwiftUI app with four main tabs:

- Build: restaurant intake and AI-style onboarding conversation
- Dashboard: launch readiness, MVP checklist, recent activity, and publish status
- Preview: generated restaurant website mockup
- Updates: voice-style quick updates for hours, menus, and announcements

The AI, voice, and deployment behavior is currently simulated so the project runs immediately in Xcode.

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

Then choose the `SiteClaw` scheme and run on `My Mac`.

## Build Check

The prototype was verified with:

```bash
xcodebuild -project SiteClaw.xcodeproj -scheme SiteClaw -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## Next Steps

- Add real restaurant intake fields for menu editing
- Add real microphone/transcription flow
- Add a backend endpoint for AI generation
- Add generated-site export or Cloudflare Pages publishing
- Add collaborators through GitHub after the remote repository is published
