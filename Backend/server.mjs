import http from "node:http";
import { readFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
loadEnv(join(__dirname, ".env"));

const port = numberFromEnv("PORT", 8787);
const allowedOrigin = process.env.SITECLAW_ALLOWED_ORIGIN || "*";

const server = http.createServer(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
        res.writeHead(204);
        res.end();
        return;
    }

    try {
        const url = new URL(req.url ?? "/", `http://${req.headers.host ?? "localhost"}`);

        if (req.method === "GET" && url.pathname === "/health") {
            sendJSON(res, 200, {
                ok: true,
                service: "siteclaw-backend",
                realtime_model: realtimeModel(),
                realtime_transcription_model: realtimeTranscriptionModel(),
                generation_model: generationModel(),
                supabase_auth_configured: Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY),
                stripe_configured: Boolean(process.env.STRIPE_SECRET_KEY),
            });
            return;
        }

        if ((req.method === "POST" || req.method === "GET") && isRealtimeSessionPath(url.pathname)) {
            const body = req.method === "POST" ? await readJSON(req) : {};
            const payload = await createRealtimeClientSecret(body);
            sendJSON(res, 200, payload);
            return;
        }

        if (req.method === "POST" && isDraftGenerationPath(url.pathname)) {
            const body = await readJSON(req);
            const payload = await generateWebsiteDraft(body);
            sendJSON(res, 200, payload);
            return;
        }

        if (req.method === "POST" && url.pathname === "/api/auth/sign-in") {
            const body = await readJSON(req);
            const payload = await startSupabaseEmailSignIn(body);
            sendJSON(res, 200, payload);
            return;
        }

        if (req.method === "POST" && url.pathname === "/api/billing/checkout") {
            const body = await readJSON(req);
            const payload = await createStripeCheckoutSession(body);
            sendJSON(res, 200, payload);
            return;
        }

        if (req.method === "POST" && url.pathname === "/api/billing/portal") {
            const body = await readJSON(req);
            const payload = await createStripePortalSession(body);
            sendJSON(res, 200, payload);
            return;
        }

        sendJSON(res, 404, { error: "Not found" });
    } catch (error) {
        console.error(error);
        sendJSON(res, error.statusCode ?? 500, {
            error: error.publicMessage ?? "Internal server error",
        });
    }
});

server.listen(port, () => {
    console.log(`SiteClaw backend listening on http://localhost:${port}`);
});

async function createRealtimeClientSecret(body) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
        throw publicError(
            500,
            "Missing OPENAI_API_KEY. Copy Backend/.env.example to Backend/.env and add your key."
        );
    }

    const restaurantName = sanitizeText(body.restaurantName) || "the restaurant";
    const ttlSeconds = Math.min(
        Math.max(numberFromEnv("OPENAI_REALTIME_TOKEN_TTL_SECONDS", 600), 60),
        600
    );

    const sessionConfig = {
        expires_after: {
            anchor: "created_at",
            seconds: ttlSeconds,
        },
        session: {
            type: "realtime",
            model: realtimeModel(),
            instructions: siteClawInstructions(restaurantName),
            output_modalities: ["audio"],
            audio: {
                input: {
                    format: {
                        type: "audio/pcm",
                        rate: 24000,
                    },
                    noise_reduction: {
                        type: "near_field",
                    },
                    transcription: {
                        model: realtimeTranscriptionModel(),
                        language: "en",
                    },
                    turn_detection: {
                        type: "server_vad",
                        threshold: 0.5,
                        prefix_padding_ms: 300,
                        silence_duration_ms: 700,
                        create_response: true,
                        interrupt_response: true,
                    },
                },
                output: {
                    voice: process.env.OPENAI_REALTIME_VOICE || "marin",
                },
            },
        },
    };

    const response = await fetch("https://api.openai.com/v1/realtime/client_secrets", {
        method: "POST",
        headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify(sessionConfig),
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
        const message = data?.error?.message || "OpenAI Realtime client secret request failed.";
        throw publicError(response.status, message);
    }

    return {
        client_secret: data.value ?? data.client_secret?.value ?? data.session?.client_secret?.value,
        expires_at: data.expires_at ?? data.client_secret?.expires_at ?? data.session?.client_secret?.expires_at,
        session: data.session,
        model: realtimeModel(),
        transcription_model: realtimeTranscriptionModel(),
        voice: process.env.OPENAI_REALTIME_VOICE || "marin",
    };
}

async function generateWebsiteDraft(body) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
        throw publicError(
            500,
            "Missing OPENAI_API_KEY. Copy Backend/.env.example to Backend/.env and add your key."
        );
    }

    if (!body || typeof body !== "object" || Array.isArray(body)) {
        throw publicError(400, "Request body must be a JSON object.");
    }

    const restaurantJSON = body.restaurant_json ?? body.restaurantJSON ?? {};
    const currentDraft = body.draft ?? {};
    const restaurant = body.restaurant ?? {};
    const transcript = sanitizeTextWithLimit(body.transcript, 5000);

    const response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            model: generationModel(),
            input: [
                {
                    role: "system",
                    content: [
                        "You are SiteClaw's website copy generator for local restaurants.",
                        "Generate concise, credible website copy from owner-provided restaurant data.",
                        "Do not invent addresses, phone numbers, prices, awards, or delivery partners.",
                        "If a fact is missing, omit it or use neutral copy; never use placeholder facts like 123 Main Street, 555 phone numbers, fake hours, or made-up menu prices.",
                        "Keep the tone polished and useful for a busy local restaurant owner.",
                    ].join(" "),
                },
                {
                    role: "user",
                    content: JSON.stringify(
                        {
                            transcript,
                            restaurant,
                            restaurant_json: restaurantJSON,
                            current_draft: currentDraft,
                            task: "Return improved website draft copy for the native app preview and static export.",
                        },
                        null,
                        2
                    ),
                },
            ],
            text: {
                format: {
                    type: "json_schema",
                    name: "siteclaw_generated_draft",
                    schema: draftGenerationSchema(),
                    strict: true,
                },
            },
        }),
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
        const message = data?.error?.message || "OpenAI website draft generation failed.";
        throw publicError(response.status, message);
    }

    const outputText = extractOutputText(data);
    if (!outputText) {
        throw publicError(502, "OpenAI did not return website draft text.");
    }

    let generated;
    try {
        generated = JSON.parse(outputText);
    } catch {
        throw publicError(502, "OpenAI returned draft text that was not valid JSON.");
    }

    return {
        ...generated,
        model: generationModel(),
        source: "openai_responses",
    };
}

async function startSupabaseEmailSignIn(body) {
    const supabaseURL = process.env.SUPABASE_URL;
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
    if (!supabaseURL || !supabaseAnonKey) {
        throw publicError(
            501,
            "Missing SUPABASE_URL or SUPABASE_ANON_KEY. Add Supabase public auth config to Backend/.env."
        );
    }

    const email = sanitizeEmail(body.email);
    const restaurantName = sanitizeText(body.restaurant_name ?? body.restaurantName);
    if (!email) {
        throw publicError(400, "Email is required.");
    }
    if (!restaurantName) {
        throw publicError(400, "Restaurant name is required.");
    }

    const response = await fetch(`${supabaseURL.replace(/\/$/, "")}/auth/v1/otp`, {
        method: "POST",
        headers: {
            apikey: supabaseAnonKey,
            Authorization: `Bearer ${supabaseAnonKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            email,
            create_user: true,
            data: {
                restaurant_name: restaurantName,
                restaurant_slug: slugFor(restaurantName),
            },
        }),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
        throw publicError(response.status, data?.msg || data?.error_description || "Supabase sign-in failed.");
    }

    return {
        account: {
            owner_name: titleFromEmail(email),
            email,
            restaurant_id: "pending-supabase-restaurant",
            restaurant_slug: slugFor(restaurantName),
            auth_provider: "Supabase Email OTP",
            role: "Owner",
            last_signed_in_at: new Date().toISOString(),
            is_authenticated: false,
        },
        delivery: "email_otp",
        message: "Supabase accepted the sign-in request. Check email to complete authentication.",
    };
}

async function createStripeCheckoutSession(body) {
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
        throw publicError(501, "Missing STRIPE_SECRET_KEY. Add Stripe backend config to Backend/.env.");
    }

    const plan = sanitizePlan(body.plan);
    if (plan === "founding") {
        throw publicError(400, "Founding plans are assigned manually and do not use Stripe Checkout.");
    }

    const price = stripePriceForPlan(plan);
    if (!price) {
        throw publicError(501, `Missing Stripe price env var for ${plan}.`);
    }

    const successURL = sanitizeURL(body.success_url ?? body.successURL) || defaultAppURL("/billing/success");
    const cancelURL = sanitizeURL(body.cancel_url ?? body.cancelURL) || defaultAppURL("/billing");
    const email = sanitizeEmail(body.email);

    const params = {
        mode: "subscription",
        success_url: successURL,
        cancel_url: cancelURL,
        "line_items[0][price]": price,
        "line_items[0][quantity]": "1",
        "metadata[plan]": plan,
    };

    if (email) {
        params.customer_email = email;
    }

    const data = await postStripeForm("/v1/checkout/sessions", params, stripeKey);

    return {
        url: data.url,
        id: data.id,
        subscription: {
            plan,
            status: "trialing",
            edits_this_period: 0,
            current_period_end: null,
            stripe_customer_id: typeof data.customer === "string" ? data.customer : null,
            stripe_subscription_id: typeof data.subscription === "string" ? data.subscription : null,
        },
    };
}

async function createStripePortalSession(body) {
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
        throw publicError(501, "Missing STRIPE_SECRET_KEY. Add Stripe backend config to Backend/.env.");
    }

    let customerID = sanitizeText(body.customer_id ?? body.customerID);
    const email = sanitizeEmail(body.email);
    if (!customerID && email) {
        customerID = await findStripeCustomerIDByEmail(email, stripeKey);
    }

    if (!customerID) {
        throw publicError(400, "Stripe customer_id or a matching customer email is required for the customer portal.");
    }

    const returnURL = sanitizeURL(body.return_url ?? body.returnURL) || defaultAppURL("/billing");
    const data = await postStripeForm(
        "/v1/billing_portal/sessions",
        {
            customer: customerID,
            return_url: returnURL,
        },
        stripeKey
    );

    return {
        url: data.url,
        id: data.id,
    };
}

function siteClawInstructions(restaurantName) {
    return [
        "You are SiteClaw, a friendly voice onboarding assistant for local restaurant owners.",
        `You are helping create a website draft for ${restaurantName}.`,
        "Ask one short question at a time.",
        "Capture these fields: restaurant name, cuisine, city or neighborhood, hours, menu highlights with prices, owner story, phone number if provided, and local SEO phrases.",
        "Keep responses warm, concise, and practical for a busy restaurant owner.",
        "When enough information is captured, summarize the structured website brief and say it is ready to generate a preview.",
    ].join(" ");
}

function isRealtimeSessionPath(pathname) {
    return pathname === "/api/realtime/session" || pathname === "/token";
}

function isDraftGenerationPath(pathname) {
    return pathname === "/api/generate/draft" || pathname === "/api/ai/draft";
}

function draftGenerationSchema() {
    return {
        type: "object",
        properties: {
            reply: {
                type: "string",
                description: "Short assistant message explaining what was generated.",
            },
            draft: {
                type: "object",
                properties: {
                    headline: {
                        type: "string",
                        description: "Homepage hero headline.",
                    },
                    subheadline: {
                        type: "string",
                        description: "Homepage supporting copy.",
                    },
                    call_to_action: {
                        type: "string",
                        description: "Short button label.",
                    },
                    pages: {
                        type: "array",
                        items: { type: "string" },
                    },
                    seo_keywords: {
                        type: "array",
                        items: { type: "string" },
                    },
                    last_generated_summary: {
                        type: "string",
                        description: "One-sentence summary of what changed.",
                    },
                },
                required: [
                    "headline",
                    "subheadline",
                    "call_to_action",
                    "pages",
                    "seo_keywords",
                    "last_generated_summary",
                ],
                additionalProperties: false,
            },
        },
        required: ["reply", "draft"],
        additionalProperties: false,
    };
}

async function readJSON(req) {
    const chunks = [];
    for await (const chunk of req) {
        chunks.push(chunk);
    }

    const raw = Buffer.concat(chunks).toString("utf8").trim();
    if (!raw) {
        return {};
    }

    try {
        return JSON.parse(raw);
    } catch {
        throw publicError(400, "Request body must be valid JSON.");
    }
}

function sendJSON(res, statusCode, data) {
    res.writeHead(statusCode, {
        "Content-Type": "application/json",
    });
    res.end(JSON.stringify(data, null, 2));
}

function setCorsHeaders(res) {
    res.setHeader("Access-Control-Allow-Origin", allowedOrigin);
    res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type,Authorization");
}

function loadEnv(path) {
    if (!existsSync(path)) {
        return;
    }

    const lines = readFileSync(path, "utf8").split(/\r?\n/);
    for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("#")) {
            continue;
        }

        const separatorIndex = trimmed.indexOf("=");
        if (separatorIndex === -1) {
            continue;
        }

        const key = trimmed.slice(0, separatorIndex).trim();
        const value = trimmed.slice(separatorIndex + 1).trim();
        if (key && !process.env[key]) {
            process.env[key] = stripQuotes(value);
        }
    }
}

function stripQuotes(value) {
    if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
    ) {
        return value.slice(1, -1);
    }

    return value;
}

function sanitizeText(value) {
    return sanitizeTextWithLimit(value, 120);
}

function sanitizeTextWithLimit(value, maxLength) {
    return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function realtimeModel() {
    return process.env.OPENAI_REALTIME_MODEL || "gpt-realtime";
}

function realtimeTranscriptionModel() {
    return process.env.OPENAI_REALTIME_TRANSCRIPTION_MODEL || "gpt-realtime-whisper";
}

function generationModel() {
    return process.env.OPENAI_GENERATION_MODEL || "gpt-5.4-mini";
}

function stripePriceForPlan(plan) {
    switch (plan) {
        case "starter":
            return process.env.STRIPE_PRICE_STARTER;
        case "pro":
            return process.env.STRIPE_PRICE_PRO;
        default:
            return "";
    }
}

async function postStripeForm(path, params, stripeKey) {
    const response = await fetch(`https://api.stripe.com${path}`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${stripeKey}`,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams(params).toString(),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
        throw publicError(response.status, data?.error?.message || "Stripe request failed.");
    }

    return data;
}

async function getStripeJSON(path, params, stripeKey) {
    const query = new URLSearchParams(params).toString();
    const response = await fetch(`https://api.stripe.com${path}?${query}`, {
        method: "GET",
        headers: {
            Authorization: `Bearer ${stripeKey}`,
        },
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
        throw publicError(response.status, data?.error?.message || "Stripe request failed.");
    }

    return data;
}

async function findStripeCustomerIDByEmail(email, stripeKey) {
    const data = await getStripeJSON(
        "/v1/customers",
        {
            email,
            limit: "1",
        },
        stripeKey
    );

    return typeof data?.data?.[0]?.id === "string" ? data.data[0].id : "";
}

function extractOutputText(data) {
    if (typeof data?.output_text === "string") {
        return data.output_text;
    }

    const parts = [];

    for (const item of data?.output ?? []) {
        for (const content of item?.content ?? []) {
            if (content?.type === "output_text" && typeof content.text === "string") {
                parts.push(content.text);
            }
        }
    }

    return parts.join("").trim();
}

function numberFromEnv(name, fallback) {
    const parsed = Number.parseInt(process.env[name] ?? "", 10);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function sanitizeEmail(value) {
    const email = sanitizeTextWithLimit(value, 254).toLowerCase();
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ? email : "";
}

function sanitizePlan(value) {
    const plan = sanitizeText(value).toLowerCase();
    return ["founding", "starter", "pro"].includes(plan) ? plan : "starter";
}

function sanitizeURL(value) {
    const text = sanitizeTextWithLimit(value, 2048);
    if (!text) {
        return "";
    }

    try {
        const url = new URL(text);
        return ["http:", "https:"].includes(url.protocol) ? url.toString() : "";
    } catch {
        return "";
    }
}

function defaultAppURL(path) {
    const appURL = process.env.SITECLAW_APP_URL || "http://localhost:3000";
    return `${appURL.replace(/\/$/, "")}${path}`;
}

function slugFor(value) {
    return sanitizeText(value)
        .toLowerCase()
        .split(/[^a-z0-9]+/)
        .filter(Boolean)
        .join("-");
}

function titleFromEmail(email) {
    return email
        .split("@")[0]
        .split(/[._-]+/)
        .filter(Boolean)
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(" ") || "Restaurant Owner";
}

function publicError(statusCode, publicMessage) {
    const error = new Error(publicMessage);
    error.statusCode = statusCode;
    error.publicMessage = publicMessage;
    return error;
}
