import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.95.0";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5.9.6";

const firebaseProjectId = "csp11-exam-platform";
const firebaseIssuer = `https://securetoken.google.com/${firebaseProjectId}`;
const firebaseJwks = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type SearchRow = {
  domain_id: string;
  domain_title: string;
  competency_id: string;
  competency_title: string;
  topic_id: string;
  topic_title: string;
  subtopic_id: string;
  subtopic_title: string;
  match_section: string;
  matched_text: string;
  score: number;
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function serverClient() {
  const url = Deno.env.get("SUPABASE_URL")?.trim();
  const rawSecretKeys = Deno.env.get("SUPABASE_SECRET_KEYS")?.trim();

  if (!url || !rawSecretKeys) {
    throw new Error("server_configuration_missing");
  }

  let secretKey = "";
  try {
    const keys = JSON.parse(rawSecretKeys) as Record<string, unknown>;
    if (typeof keys.default === "string") {
      secretKey = keys.default.trim();
    }
  } catch {
    throw new Error("server_configuration_invalid");
  }

  if (!secretKey.startsWith("sb_secret_")) {
    throw new Error("server_configuration_invalid");
  }

  return createClient(url, secretKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
}

async function verifyFirebaseUid(req: Request): Promise<string | null> {
  const authorization = req.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return null;
  }

  const token = authorization.slice("Bearer ".length).trim();
  if (token.length === 0) {
    return null;
  }

  try {
    const { payload } = await jwtVerify(token, firebaseJwks, {
      issuer: firebaseIssuer,
      audience: firebaseProjectId,
      algorithms: ["RS256"],
      clockTolerance: 5,
    });

    const uid = payload.sub?.trim();
    if (uid == null || uid.length === 0 || uid.length > 128) {
      return null;
    }

    return uid;
  } catch (error) {
    console.warn(
      "Learner content search Firebase token rejected:",
      error instanceof Error ? error.name : "unknown_error",
    );
    return null;
  }
}

function parseLimit(value: unknown): number | null {
  if (value == null) return 8;
  if (typeof value !== "number" || !Number.isInteger(value)) return null;
  if (value < 1 || value > 20) return null;
  return value;
}

function parseQuery(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const query = value.trim();
  if (query.length < 2 || query.length > 160) return null;
  return query;
}

function requiredText(value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error("search_result_integrity_error");
  }
  return value.trim();
}

function snippet(value: string, query: string): string {
  const compact = value.replace(/\s+/g, " ").trim();
  if (compact.length <= 170) return compact;

  const lower = compact.toLowerCase();
  const queryLower = query.toLowerCase();
  let index = lower.indexOf(queryLower);

  if (index < 0) {
    for (const token of queryLower.split(/\s+/).filter((item) => item.length >= 2)) {
      index = lower.indexOf(token);
      if (index >= 0) break;
    }
  }

  if (index < 0) {
    return `${compact.slice(0, 167).trimEnd()}…`;
  }

  const start = Math.max(0, index - 55);
  const end = Math.min(compact.length, index + query.length + 105);
  let result = compact.slice(start, end).trim();
  if (start > 0) result = `…${result}`;
  if (end < compact.length) result = `${result}…`;
  return result;
}

function mapRow(row: SearchRow, query: string) {
  const score = Number(row.score);
  if (!Number.isInteger(score) || score < 0) {
    throw new Error("search_result_integrity_error");
  }

  const matchedText = requiredText(row.matched_text);
  return {
    domainId: requiredText(row.domain_id),
    domainTitle: requiredText(row.domain_title),
    competencyId: requiredText(row.competency_id),
    competencyTitle: requiredText(row.competency_title),
    topicId: requiredText(row.topic_id),
    topicTitle: requiredText(row.topic_title),
    subtopicId: requiredText(row.subtopic_id),
    subtopicTitle: requiredText(row.subtopic_title),
    matchSection: requiredText(row.match_section),
    snippet: snippet(matchedText, query),
    score,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const uid = await verifyFirebaseUid(req);
  if (uid == null) {
    return jsonResponse(401, { error: "invalid_firebase_token" });
  }

  let body: Record<string, unknown>;
  try {
    const decoded = await req.json();
    if (decoded == null || typeof decoded !== "object" || Array.isArray(decoded)) {
      return jsonResponse(400, { error: "invalid_request" });
    }
    body = decoded as Record<string, unknown>;
  } catch {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const query = parseQuery(body.query);
  const limit = parseLimit(body.limit);
  if (query == null || limit == null) {
    return jsonResponse(400, { error: "invalid_search_request" });
  }

  let supabase: ReturnType<typeof createClient>;
  try {
    supabase = serverClient();
  } catch {
    return jsonResponse(503, { error: "server_configuration_error" });
  }

  const { data, error } = await supabase.rpc(
    "search_published_study_content",
    { p_query: query, p_limit: limit },
  );

  if (error) {
    console.warn("Published learner content search failed:", error.code);
    return jsonResponse(503, { error: "search_unavailable" });
  }

  try {
    const rows = (data ?? []) as SearchRow[];
    if (rows.length > limit) {
      throw new Error("search_result_integrity_error");
    }

    const results = rows.map((row) => mapRow(row, query));
    return jsonResponse(200, { results });
  } catch {
    return jsonResponse(503, { error: "search_result_integrity_error" });
  }
});
