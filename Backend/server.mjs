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
                service: "siteclaw-realtime-token-backend",
                model: realtimeModel(),
            });
            return;
        }

        if ((req.method === "POST" || req.method === "GET") && isRealtimeSessionPath(url.pathname)) {
            const body = req.method === "POST" ? await readJSON(req) : {};
            const payload = await createRealtimeClientSecret(body);
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
        voice: process.env.OPENAI_REALTIME_VOICE || "marin",
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
    return typeof value === "string" ? value.trim().slice(0, 120) : "";
}

function realtimeModel() {
    return process.env.OPENAI_REALTIME_MODEL || "gpt-realtime";
}

function numberFromEnv(name, fallback) {
    const parsed = Number.parseInt(process.env[name] ?? "", 10);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function publicError(statusCode, publicMessage) {
    const error = new Error(publicMessage);
    error.statusCode = statusCode;
    error.publicMessage = publicMessage;
    return error;
}
