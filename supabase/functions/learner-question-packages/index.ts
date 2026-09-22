import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.95.0";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5.9.6";

const firebaseProjectId = "csp11-exam-platform";
const firebaseIssuer =
  `https://securetoken.google.com/${firebaseProjectId}`;
const firebaseJwks = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

const packageBucket = "csp11-published-packages";
const signedUrlTtlSeconds = 60;
const ultraHardTag = "ultra-hard-dqg300";
const competencyPattern = /^d\d{2}_c\d{2}$/;
const checksumPattern = /^[0-9a-f]{64}$/;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type CatalogRow = {
  competency_id: string;
  question_version: number;
  question_checksum_sha256: string;
  question_object_path: string;
  question_size_bytes: number;
  published_question_count: number;
};

type CatalogDescriptor = {
  competencyId: string;
  questionVersion: number;
  questionChecksumSha256: string;
  questionSizeBytes: number;
  publishedQuestionCount: number;
  ultraHardCount?: number;
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
  const prefix = "Bearer ";

  if (!authorization.startsWith(prefix)) {
    return null;
  }

  const token = authorization.slice(prefix.length).trim();

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
      "Learner package Firebase token rejected:",
      error instanceof Error ? error.name : "unknown_error",
    );
    return null;
  }
}

function parseCompetencyId(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  return competencyPattern.test(normalized) ? normalized : null;
}

function parseKnownPackage(body: Record<string, unknown>) {
  const rawVersion = body.knownQuestionVersion;
  const rawChecksum = body.knownQuestionChecksumSha256;

  if (rawVersion == null && rawChecksum == null) {
    return null;
  }

  if (
    typeof rawVersion !== "number" ||
    !Number.isInteger(rawVersion) ||
    rawVersion <= 0 ||
    typeof rawChecksum !== "string"
  ) {
    throw new Error("invalid_known_package");
  }

  const checksum = rawChecksum.trim().toLowerCase();

  if (!checksumPattern.test(checksum)) {
    throw new Error("invalid_known_package");
  }

  return {
    version: rawVersion,
    checksum,
  };
}

function descriptorFromRow(row: CatalogRow): CatalogDescriptor {
  const competencyId = parseCompetencyId(row.competency_id);
  const version = Number(row.question_version);
  const checksum = row.question_checksum_sha256?.trim().toLowerCase();
  const sizeBytes = Number(row.question_size_bytes);
  const count = Number(row.published_question_count);

  if (
    competencyId == null ||
    !Number.isInteger(version) ||
    version <= 0 ||
    !checksumPattern.test(checksum) ||
    !Number.isInteger(sizeBytes) ||
    sizeBytes < 0 ||
    !Number.isInteger(count) ||
    count < 0
  ) {
    throw new Error("catalog_integrity_error");
  }

  const expectedPath =
    `questions/${competencyId}/v${version}.json.gz`;

  if (row.question_object_path !== expectedPath) {
    throw new Error("catalog_integrity_error");
  }

  return {
    competencyId,
    questionVersion: version,
    questionChecksumSha256: checksum,
    questionSizeBytes: sizeBytes,
    publishedQuestionCount: count,
  };
}

function withUltraHardCount(
  descriptor: CatalogDescriptor,
  ultraHardCount: number,
): CatalogDescriptor {
  if (!Number.isInteger(ultraHardCount) || ultraHardCount < 0) {
    throw new Error("catalog_integrity_error");
  }

  return {
    ...descriptor,
    ultraHardCount,
  };
}

async function handleCompetency(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const competencyId = parseCompetencyId(body.competencyId);

  if (competencyId == null) {
    return jsonResponse(400, { error: "invalid_competency_id" });
  }

  let knownPackage: { version: number; checksum: string } | null;

  try {
    knownPackage = parseKnownPackage(body);
  } catch {
    return jsonResponse(400, { error: "invalid_known_package" });
  }

  const { data, error } = await supabase
    .from("published_catalog")
    .select(
      "competency_id,question_version,question_checksum_sha256,question_object_path,question_size_bytes,published_question_count",
    )
    .eq("competency_id", competencyId)
    .eq("active", true)
    .maybeSingle();

  if (error) {
    console.warn("Learner package catalogue lookup failed:", error.code);
    return jsonResponse(503, { error: "catalog_unavailable" });
  }

  if (data == null) {
    return jsonResponse(404, { error: "package_not_found" });
  }

  let descriptor: CatalogDescriptor;

  try {
    descriptor = descriptorFromRow(data as CatalogRow);
  } catch {
    return jsonResponse(503, { error: "catalog_integrity_error" });
  }

  const current =
    knownPackage != null &&
    knownPackage.version === descriptor.questionVersion &&
    knownPackage.checksum === descriptor.questionChecksumSha256;

  if (current) {
    return jsonResponse(200, {
      ...descriptor,
      current: true,
    });
  }

  const { data: signed, error: signedError } = await supabase.storage
    .from(packageBucket)
    .createSignedUrl(
      `questions/${descriptor.competencyId}/v${descriptor.questionVersion}.json.gz`,
      signedUrlTtlSeconds,
    );

  if (signedError || !signed?.signedUrl) {
    console.warn(
      "Learner package signed URL creation failed:",
      signedError?.name ?? "unknown_error",
    );
    return jsonResponse(503, { error: "package_url_unavailable" });
  }

  return jsonResponse(200, {
    ...descriptor,
    current: false,
    signedUrl: signed.signedUrl,
    signedUrlTtlSeconds,
  });
}

async function handleCatalog(
  supabase: ReturnType<typeof createClient>,
) {
  const { data: rows, error } = await supabase
    .from("published_catalog")
    .select(
      "competency_id,question_version,question_checksum_sha256,question_object_path,question_size_bytes,published_question_count",
    )
    .eq("active", true)
    .order("competency_id");

  if (error) {
    console.warn("Learner package catalogue list failed:", error.code);
    return jsonResponse(503, { error: "catalog_unavailable" });
  }

  const { data: ultraRows, error: ultraError } = await supabase
    .from("questions")
    .select("competency_id")
    .eq("status", "published")
    .contains("tags", [ultraHardTag]);

  if (ultraError) {
    console.warn("Ultra Hard discovery lookup failed:", ultraError.code);
    return jsonResponse(503, { error: "catalog_unavailable" });
  }

  const ultraCounts = new Map<string, number>();

  for (const row of ultraRows ?? []) {
    const competencyId = parseCompetencyId(row.competency_id);

    if (competencyId == null) {
      return jsonResponse(503, { error: "catalog_integrity_error" });
    }

    ultraCounts.set(
      competencyId,
      (ultraCounts.get(competencyId) ?? 0) + 1,
    );
  }

  try {
    const catalog = (rows ?? []).map((row) => {
      const descriptor = descriptorFromRow(row as CatalogRow);
      return withUltraHardCount(
        descriptor,
        ultraCounts.get(descriptor.competencyId) ?? 0,
      );
    });

    return jsonResponse(200, { catalog });
  } catch {
    return jsonResponse(503, { error: "catalog_integrity_error" });
  }
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

  let supabase: ReturnType<typeof createClient>;

  try {
    supabase = serverClient();
  } catch {
    return jsonResponse(503, { error: "server_configuration_error" });
  }

  const operation = body.operation;

  if (operation === "competency") {
    return await handleCompetency(supabase, body);
  }

  if (operation === "catalog") {
    return await handleCatalog(supabase);
  }

  return jsonResponse(400, { error: "invalid_operation" });
});
