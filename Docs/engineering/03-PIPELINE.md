# SiteClaw — Pipeline Service Specification

## Service Overview

The Pipeline is the AI conversation engine that powers SiteClaw's chat interface. It receives messages from restaurant owners (via the Dashboard), conducts a guided conversation to extract restaurant information, and writes/updates `restaurant.json` in Supabase Storage. It wraps OpenClaw (an open-source AI agent framework) and uses Claude Sonnet for content generation and GPT-4o Mini for routing/classification.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | OpenClaw | Open-source AI agent framework |
| Runtime | Node.js 20+ | Running on Railway |
| Language | TypeScript | |
| AI (content) | Claude Sonnet (via Anthropic API) | Menu descriptions, SEO, about sections |
| AI (routing) | GPT-4o Mini (via OpenAI API) | Intent classification, conversation routing |
| Storage | Supabase Storage + Supabase DB | restaurant.json + conversation history |
| Validation | ajv | JSON Schema validation |
| Deployment | Railway | |

## Project Structure

```
siteclaw-pipeline/
├── src/
│   ├── index.ts                          # Express server entry point
│   ├── routes/
│   │   ├── chat.ts                       # POST /chat — main conversation endpoint
│   │   ├── conversations.ts              # GET /conversations/:restaurant_id — history
│   │   └── health.ts                     # GET /health
│   ├── agents/
│   │   ├── orchestrator.ts               # Routes incoming messages to the right handler
│   │   ├── intake.ts                     # Guided onboarding conversation flow
│   │   ├── editor.ts                     # Handles edit requests to existing data
│   │   ├── content-generator.ts          # Claude Sonnet — generates descriptions, SEO
│   │   └── validator.ts                  # Validates restaurant.json after every write
│   ├── openclaw/
│   │   ├── config.ts                     # OpenClaw configuration
│   │   └── tools.ts                      # Custom tools registered with OpenClaw
│   ├── services/
│   │   ├── supabase.ts                   # Supabase client for storage + DB
│   │   ├── anthropic.ts                  # Claude Sonnet client wrapper
│   │   ├── openai.ts                     # GPT-4o Mini client wrapper
│   │   └── restaurant-json.ts            # Read/write/merge restaurant.json
│   ├── prompts/
│   │   ├── system.ts                     # Base system prompt for all conversations
│   │   ├── intake-flow.ts               # Onboarding conversation prompt
│   │   ├── edit-flow.ts                  # Edit conversation prompt
│   │   ├── content-generation.ts         # Prompts for menu descriptions, SEO, about
│   │   └── classification.ts             # Intent classification prompt (GPT-4o Mini)
│   ├── schema/
│   │   ├── restaurant.schema.json        # JSON Schema (copied from siteclaw-shared)
│   │   └── validate.ts                   # ajv validation wrapper
│   ├── types/
│   │   └── index.ts                      # Shared types
│   └── utils/
│       ├── merge.ts                      # Deep merge utility for partial updates
│       └── logger.ts                     # Structured logging
├── .env                                  # Environment variables (not committed)
├── .env.example
├── railway.toml                          # Railway deployment config
├── Dockerfile                            # Container definition for Railway
├── package.json
└── tsconfig.json
```

## Environment Variables

```env
# Anthropic (Claude Sonnet)
ANTHROPIC_API_KEY=<anthropic-api-key>

# OpenAI (GPT-4o Mini for routing + Whisper)
OPENAI_API_KEY=<openai-api-key>

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<supabase-service-role-key>

# Pipeline Auth
PIPELINE_API_KEY=<pipeline-api-key>

# Server
PORT=8000
NODE_ENV=production
```

## API Endpoints

### `POST /chat`

Main conversation endpoint. Receives a message, processes it through the agent pipeline, and returns a response.

**Request:**
```json
{
  "restaurant_id": "uuid",
  "user_id": "uuid",
  "message": "We're open Monday through Friday 11am to 9pm, closed weekends"
}
```

**Response:**
```json
{
  "reply": "Got it! I've set your hours to Monday–Friday, 11:00 AM to 9:00 PM, closed Saturday and Sunday. Would you like to add different weekend hours, or is closed on weekends correct?",
  "restaurant_updated": true,
  "fields_updated": ["hours"],
  "progress": {
    "basics": { "complete": true, "fields": ["name", "tagline", "cuisine_type"] },
    "contact": { "complete": true, "fields": ["phone", "address"] },
    "hours": { "complete": true, "fields": ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] },
    "menu": { "complete": false, "fields": [] },
    "branding": { "complete": false, "fields": [] }
  }
}
```

**Auth:** Requires `Authorization: Bearer {PIPELINE_API_KEY}` header. This is a service-to-service call from Dashboard → Pipeline. The Dashboard has already authenticated the user.

### `GET /conversations/:restaurant_id`

Returns conversation history for a restaurant.

**Response:**
```json
{
  "messages": [
    {
      "id": "uuid",
      "role": "assistant",
      "content": "Welcome! Let's build your restaurant website. What's the name of your restaurant?",
      "timestamp": "2026-05-07T10:00:00Z"
    },
    {
      "id": "uuid",
      "role": "user",
      "content": "Mario's Trattoria",
      "timestamp": "2026-05-07T10:00:15Z"
    }
  ]
}
```

### `GET /health`

Returns `{ "status": "ok" }`. Used by Railway health checks.

## Agent Architecture

The Pipeline uses a multi-agent pattern orchestrated by a central router. All agents are TypeScript modules, not separate processes.

### Flow

```
Message arrives
    │
    ▼
┌─────────────┐
│ Orchestrator │  ← Uses GPT-4o Mini to classify intent
└─────┬───────┘
      │
      ├── intent: "onboarding" ──→ Intake Agent
      ├── intent: "edit"       ──→ Editor Agent
      ├── intent: "question"   ──→ Direct response (no JSON update)
      └── intent: "off-topic"  ──→ Gentle redirect to restaurant topics
      │
      ▼
┌─────────────────┐
│ Content Generator│  ← Claude Sonnet, called by Intake/Editor when needed
└─────────────────┘
      │
      ▼
┌───────────┐
│ Validator  │  ← Validates restaurant.json after every write
└───────────┘
```

### Orchestrator (`agents/orchestrator.ts`)

Classifies the incoming message intent and routes to the appropriate handler.

```typescript
// Intent classification using GPT-4o Mini
const CLASSIFICATION_PROMPT = `You are an intent classifier for a restaurant website builder chatbot.

Given the user's message and the current state of their restaurant data, classify the intent as one of:
- "onboarding": User is providing new information about their restaurant (name, hours, menu items, contact info, etc.) during initial setup
- "edit": User wants to change or update existing information that was previously set
- "question": User is asking a question about the service, their site, or how something works
- "off_topic": User is talking about something unrelated to building their restaurant website

Current restaurant.json state:
{currentState}

User message: "{message}"

Respond with ONLY the intent label, nothing else.`;
```

### Intake Agent (`agents/intake.ts`)

Guides new restaurant owners through the onboarding conversation. Follows a structured flow but stays conversational — not a rigid form.

**Conversation flow priority (what to ask for first → last):**

1. Restaurant name
2. Phone number
3. Address
4. Hours of operation
5. Cuisine type
6. Menu (categories → items → prices → descriptions)
7. Social media links
8. Branding preferences (or auto-suggest based on cuisine)
9. Gallery images (upload flow)
10. Special features (ordering, reservations, etc.)

**Key behavior:**
- After each user message, extract any restaurant data mentioned and write it to restaurant.json
- Don't ask for information the user already provided unprompted
- Batch related questions ("What's your address and phone number?") rather than one-at-a-time
- When the user provides menu items, use the Content Generator to enhance descriptions
- Auto-generate SEO metadata once basics + contact + cuisine_type are populated
- Celebrate progress milestones ("Great, your basic info is complete! Let's move on to your menu.")

**System prompt excerpt:**
```
You are SiteClaw's restaurant website assistant. You're helping a restaurant owner build their website through conversation. You are warm, efficient, and knowledgeable about restaurants.

Rules:
- Extract data from every message. If the owner says "We're Mario's Trattoria on East 6th Street", extract BOTH the name and the street.
- Never ask for information already provided.
- Keep responses under 3 sentences unless explaining something complex.
- When the owner provides menu items without descriptions, generate appetizing descriptions using the Content Generator.
- Match the owner's energy — if they're brief, be brief. If they're chatty, engage.
- You understand restaurant operations deeply. If an owner says "we do lunch and dinner service", you know to ask for separate time ranges.
- For menu pricing, accept any format: "$14", "14.00", "fourteen dollars", "market price".
```

### Editor Agent (`agents/editor.ts`)

Handles modification requests to existing restaurant.json data.

**Key behavior:**
- Fetch current restaurant.json before processing any edit
- Identify which fields the edit applies to
- Apply a deep merge (never overwrite unrelated fields)
- Confirm the change back to the owner before saving (for destructive changes like deleting menu items)
- Non-destructive changes (updating hours, fixing a typo) can be saved immediately with a confirmation message

**Deep merge utility (`utils/merge.ts`):**
```typescript
import { mergeWith, isArray } from 'lodash';

/**
 * Deep merges updates into existing restaurant.json.
 * Arrays are replaced entirely (not concatenated) to avoid duplicate menu items.
 * Null values delete the field.
 */
export function mergeRestaurantData(existing: any, updates: any): any {
  return mergeWith({}, existing, updates, (objValue, srcValue) => {
    if (isArray(srcValue)) return srcValue; // Replace arrays entirely
    if (srcValue === null) return undefined; // Remove field
  });
}
```

### Content Generator (`agents/content-generator.ts`)

Uses Claude Sonnet to generate high-quality restaurant content. Called by Intake and Editor agents — never directly by the user.

**Generated content types:**

| Content | Trigger | Model |
|---------|---------|-------|
| Menu item descriptions | Owner provides item name + price without description | Claude Sonnet |
| Restaurant "About" section | Once name + cuisine + any personal story are captured | Claude Sonnet |
| SEO title + meta description | Once name + cuisine + location are captured | Claude Sonnet |
| SEO keywords | Same as above | Claude Sonnet |
| Tagline suggestions | Once name + cuisine are captured (offer 3 options) | Claude Sonnet |

**Example prompt for menu descriptions:**
```
You are a food copywriter for a restaurant website. Write a 1-2 sentence description for this menu item.

Restaurant: {restaurant_name}
Cuisine: {cuisine_type}
Item: {item_name}
Price: {item_price}
Category: {category_name}
Owner's notes: {owner_notes_if_any}

Rules:
- Be appetizing but honest. Do not invent ingredients the owner didn't mention.
- Match the restaurant's price range and style. A $$ Italian place sounds different from a $$$$ tasting menu.
- Include key ingredients or preparation method if known.
- Under 50 words.
- No exclamation marks. No "our" or "we" unless quoting the owner.
```

### Validator (`agents/validator.ts`)

Validates restaurant.json against the JSON Schema after every write operation.

```typescript
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import schema from '../schema/restaurant.schema.json';

const ajv = new Ajv({ allErrors: true });
addFormats(ajv);
const validate = ajv.compile(schema);

export function validateRestaurantJson(data: any): { valid: boolean; errors: string[] } {
  const valid = validate(data);
  if (valid) return { valid: true, errors: [] };

  const errors = validate.errors?.map(err => {
    return `${err.instancePath || 'root'}: ${err.message}`;
  }) || [];

  return { valid: false, errors };
}
```

## restaurant.json Read/Write Service

```typescript
// services/restaurant-json.ts

import { supabase } from './supabase';
import { mergeRestaurantData } from '../utils/merge';
import { validateRestaurantJson } from '../schema/validate';

const BUCKET = 'restaurant-data';

export async function readRestaurantJson(restaurantId: string): Promise<any | null> {
  const { data, error } = await supabase.storage
    .from(BUCKET)
    .download(`${restaurantId}/restaurant.json`);

  if (error || !data) return null;
  return JSON.parse(await data.text());
}

export async function writeRestaurantJson(
  restaurantId: string,
  updates: Partial<any>
): Promise<{ success: boolean; errors?: string[] }> {
  // Fetch existing
  const existing = await readRestaurantJson(restaurantId) || {
    schema_version: '1.0',
    restaurant_id: restaurantId
  };

  // Merge
  const merged = mergeRestaurantData(existing, {
    ...updates,
    last_updated: new Date().toISOString()
  });

  // Validate
  const { valid, errors } = validateRestaurantJson(merged);
  if (!valid) return { success: false, errors };

  // Write
  const blob = new Blob([JSON.stringify(merged, null, 2)], { type: 'application/json' });
  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(`${restaurantId}/restaurant.json`, blob, { upsert: true });

  if (error) return { success: false, errors: [error.message] };
  return { success: true };
}
```

## Conversation Storage

Conversations are stored in the Supabase `messages` table (see Database spec). Each message is persisted immediately so conversation history survives page refreshes and Pipeline restarts.

## Railway Deployment

**`railway.toml`:**
```toml
[build]
builder = "dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 5
```

**`Dockerfile`:**
```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
RUN npm run build
EXPOSE 8000
CMD ["node", "dist/index.js"]
```

## Error Handling

- All agent errors are caught and returned as friendly chat messages (never stack traces)
- If Claude Sonnet API fails, fall back to a generic "I'm having trouble right now, let me try again" message and retry once
- If GPT-4o Mini (classification) fails, default to treating the message as "onboarding" intent
- If Supabase Storage write fails, do NOT tell the user the data was saved — report the error and retry
- All errors are logged with structured JSON logging (restaurant_id, user_id, agent, error message, timestamp)

## Rate Limits & Safeguards

- Max message length: 5,000 characters
- Max messages per minute per restaurant: 10 (prevent abuse)
- Max restaurant.json file size: 500KB (prevents runaway content generation)
- Pipeline API key is validated on every request
