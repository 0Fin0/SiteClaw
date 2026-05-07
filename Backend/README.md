# SiteClaw Backend

This tiny Node backend mints short-lived OpenAI Realtime client secrets for the SiteClaw app.

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

The response includes a short-lived `client_secret` that the app can use to authenticate a Realtime connection.

## Notes

- `Backend/.env` is ignored by Git.
- The default model is `gpt-realtime`.
- The default voice is `marin`.
- The default token TTL is 600 seconds.
