# SiteClaw Backend

This tiny Node backend mints short-lived OpenAI Realtime client secrets, generates website draft copy, and locally publishes generated SiteClaw websites for the app.

The important rule: keep `OPENAI_API_KEY` on the backend only. The SwiftUI app should request a temporary client secret from this server, then use that temporary secret to connect to OpenAI Realtime.

## Setup

```bash
cd Backend
cp .env.example .env
```

Edit `Backend/.env` and set:

```bash
OPENAI_API_KEY=your-openai-api-key-here
```

## Run

From the repo root:

```bash
node Backend/server.mjs
```

The server starts at:

```text
http://localhost:8787
```

## Endpoints

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

The response includes a short-lived `client_secret` that the app can use to authenticate a Realtime connection. The session is preconfigured for 24 kHz PCM microphone input, server voice activity detection, and live input transcription.

Generate website draft copy:

```bash
curl -X POST http://localhost:8787/api/generate/draft \
  -H "Content-Type: application/json" \
  -d '{
    "transcript": "Family-owned Vietnamese restaurant in San Jose with pho, rice bowls, and spring rolls.",
    "restaurant": {
      "name": "Pho Lotus Kitchen",
      "cuisine": "Vietnamese comfort food",
      "neighborhood": "San Jose"
    },
    "draft": {},
    "restaurant_json": {}
  }'
```

The response includes structured draft fields for the app preview: headline, subheadline, call to action, pages, SEO keywords, and a summary.

Publish a generated site locally:

```bash
curl -X POST http://localhost:8787/api/publish/local \
  -H "Content-Type: application/json" \
  -d '{
    "slug": "sunset-grill",
    "html": "<!doctype html><html><body><h1>Sunset Grill</h1></body></html>",
    "restaurant_json": {
      "basics": {
        "name": "Sunset Grill"
      }
    }
  }'
```

The endpoint writes:

```text
Backend/generated-sites/{slug}/index.html
Backend/generated-sites/{slug}/restaurant.json
```

Then it serves the generated website at:

```text
http://localhost:8787/sites/{slug}/
```

This is the local MVP bridge toward the Astro/Cloudflare renderer: the Swift app already generates the HTML and `restaurant.json`, and the backend makes them behave like a real published site.

List generated sites:

```bash
curl http://localhost:8787/api/sites
```

Inspect one generated site:

```bash
curl http://localhost:8787/api/sites/sunset-grill
```

The list and detail endpoints read the generated site folders back as a tiny local registry, which gives the demo a persistence story before Supabase storage is wired in.

## Notes

- `Backend/.env` is ignored by Git.
- `Backend/generated-sites/` is ignored by Git.
- The default model is `gpt-realtime`.
- The default Realtime transcription model is `gpt-realtime-whisper`; override it with `OPENAI_REALTIME_TRANSCRIPTION_MODEL`.
- The default voice is `marin`.
- The default token TTL is 600 seconds.
- The default generation model is `gpt-5.4-mini`; override it with `OPENAI_GENERATION_MODEL`.
