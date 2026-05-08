# SiteClaw Backend

This tiny Node backend mints short-lived OpenAI Realtime client secrets and generates website draft copy for the SiteClaw app.

The important rule: keep `OPENAI_API_KEY` on the backend only. The SwiftUI app should request a temporary client secret from this server, then use that temporary secret to connect to OpenAI Realtime.

## Setup

```bash
cd Backend
cp .env.example .env
```

Edit `Backend/.env` and set:

```bash
OPENAI_API_KEY=sk-...
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

## Notes

- `Backend/.env` is ignored by Git.
- The default model is `gpt-realtime`.
- The default Realtime transcription model is `gpt-realtime-whisper`; override it with `OPENAI_REALTIME_TRANSCRIPTION_MODEL`.
- The default voice is `marin`.
- The default token TTL is 600 seconds.
- The default generation model is `gpt-5.4-mini`; override it with `OPENAI_GENERATION_MODEL`.
