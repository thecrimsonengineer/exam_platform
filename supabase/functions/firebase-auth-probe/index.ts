import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5.9.6";

const firebaseProjectId = "csp11-exam-platform";
const firebaseIssuer =
  `https://securetoken.google.com/${firebaseProjectId}`;
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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, {
      authorized: false,
      error: "method_not_allowed",
    });
  }

  const authorization = req.headers.get("authorization") ?? "";
  const prefix = "Bearer ";

  if (!authorization.startsWith(prefix)) {
    return jsonResponse(401, {
      authorized: false,
      error: "missing_bearer_token",
    });
  }

  const token = authorization.slice(prefix.length).trim();
  if (token.length === 0) {
    return jsonResponse(401, {
      authorized: false,
      error: "missing_bearer_token",
    });
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
      return jsonResponse(401, {
        authorized: false,
        error: "invalid_subject",
      });
    }

    return jsonResponse(200, {
      authorized: true,
      uid,
      projectId: firebaseProjectId,
    });
  } catch (error) {
    console.warn(
      "Firebase token verification rejected:",
      error instanceof Error ? error.name : "unknown_error",
    );

    return jsonResponse(401, {
      authorized: false,
      error: "invalid_firebase_token",
    });
  }
});
