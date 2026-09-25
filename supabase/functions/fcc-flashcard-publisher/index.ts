import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.95.0";

const bucket = "csp11-published-packages";
const competencyPattern = /^d0[12]_c\d{2}$/;
const checksumPattern = /^[0-9a-f]{64}$/;

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function configuredSecretKeys(): Set<string> {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS")?.trim();
  if (!raw) {
    throw new Error("server_configuration_missing");
  }

  const decoded = JSON.parse(raw) as Record<string, unknown>;
  const keys = new Set<string>();
  for (const value of Object.values(decoded)) {
    if (typeof value === "string" && value.startsWith("sb_secret_")) {
      keys.add(value.trim());
    }
  }

  if (keys.size === 0) {
    throw new Error("server_configuration_invalid");
  }
  return keys;
}

function authorizePublisher(req: Request): string | null {
  const apiKey = req.headers.get("apikey")?.trim() ?? "";
  if (!apiKey.startsWith("sb_secret_")) {
    return null;
  }

  try {
    return configuredSecretKeys().has(apiKey) ? apiKey : null;
  } catch {
    return null;
  }
}

function serverClient(secretKey: string) {
  const url = Deno.env.get("SUPABASE_URL")?.trim();
  if (!url) {
    throw new Error("server_configuration_missing");
  }

  return createClient(url, secretKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
}

function decodeBase64(value: unknown): Uint8Array {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error("invalid_payload_bytes");
  }

  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const source = Uint8Array.from(bytes);
  const digest = await crypto.subtle.digest("SHA-256", source.buffer);
  return Array.from(new Uint8Array(digest))
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

function positiveInteger(value: unknown): number | null {
  return typeof value === "number" &&
      Number.isInteger(value) &&
      value > 0
    ? value
    : null;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const secretKey = authorizePublisher(req);
  if (secretKey == null) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json() as Record<string, unknown>;
  } catch {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const competencyId =
    typeof body.competencyId === "string"
      ? body.competencyId.trim().toLowerCase()
      : "";
  const domainId =
    typeof body.domainId === "string"
      ? body.domainId.trim().toLowerCase()
      : "";
  const deckId =
    typeof body.deckId === "string" ? body.deckId.trim() : "";
  const version = positiveInteger(body.version);
  const itemCount = positiveInteger(body.itemCount);
  const compressedBytes = positiveInteger(body.compressedBytes);
  const storagePath =
    typeof body.storagePath === "string" ? body.storagePath.trim() : "";
  const checksum =
    typeof body.checksumSha256 === "string"
      ? body.checksumSha256.trim().toLowerCase()
      : "";
  const uncompressedChecksum =
    typeof body.uncompressedChecksumSha256 === "string"
      ? body.uncompressedChecksumSha256.trim().toLowerCase()
      : "";
  const publishedAt =
    typeof body.publishedAt === "string" ? body.publishedAt.trim() : "";

  if (
    !competencyPattern.test(competencyId) ||
    domainId !== competencyId.substring(0, 3) ||
    deckId !== `${competencyId}_flashcards_v1` ||
    version == null ||
    itemCount == null ||
    compressedBytes == null ||
    storagePath !== `flashcards/${competencyId}/v${version}.json.gz` ||
    !checksumPattern.test(checksum) ||
    !checksumPattern.test(uncompressedChecksum) ||
    Number.isNaN(Date.parse(publishedAt))
  ) {
    return jsonResponse(400, { error: "invalid_publication_metadata" });
  }

  let bytes: Uint8Array;
  try {
    bytes = decodeBase64(body.payloadBase64);
  } catch {
    return jsonResponse(400, { error: "invalid_payload_bytes" });
  }

  if (bytes.length !== compressedBytes) {
    return jsonResponse(400, { error: "compressed_size_mismatch" });
  }

  if (await sha256Hex(bytes) !== checksum) {
    return jsonResponse(400, { error: "payload_checksum_mismatch" });
  }

  const supabase = serverClient(secretKey);
  const storage = supabase.storage.from(bucket);

  const existing = await storage.download(storagePath);
  if (existing.data != null) {
    const existingBytes = new Uint8Array(await existing.data.arrayBuffer());
    if (await sha256Hex(existingBytes) !== checksum) {
      return jsonResponse(409, { error: "immutable_object_collision" });
    }
  } else {
    const message = existing.error?.message?.toLowerCase() ?? "";
    const missing =
      existing.error == null ||
      message.includes("not found") ||
      message.includes("does not exist") ||
      message.includes("object not found");

    if (!missing) {
      console.warn(
        "FCC object preflight failed:",
        existing.error?.name ?? "unknown_error",
      );
      return jsonResponse(503, { error: "storage_preflight_failed" });
    }

    const uploaded = await storage.upload(storagePath, bytes, {
      contentType: "application/gzip",
      upsert: false,
    });

    if (uploaded.error != null) {
      console.warn("FCC upload failed:", uploaded.error.name);
      return jsonResponse(503, { error: "storage_upload_failed" });
    }
  }

  const verified = await storage.download(storagePath);
  if (verified.data == null || verified.error != null) {
    return jsonResponse(503, { error: "storage_verification_failed" });
  }

  const verifiedBytes = new Uint8Array(await verified.data.arrayBuffer());
  if (
    verifiedBytes.length !== compressedBytes ||
    await sha256Hex(verifiedBytes) !== checksum
  ) {
    return jsonResponse(503, { error: "storage_checksum_verification_failed" });
  }

  const committed = await supabase.rpc("fcc_commit_flashcard_publication", {
    p_payload: {
      competencyId,
      publishedAt,
      flashcards: {
        kind: "flashcards",
        version,
        domainId,
        storageBucket: bucket,
        storagePath,
        checksumSha256: checksum,
        compressedBytes,
        itemCount,
        metadata: {
          phase: "FCC-1",
          deckId,
          sourceFcp1Sha:
            "45d00a95dc6d8cb9e7c06db6df57bb71c5e17fe2",
          sourceFcp2Sha:
            "8719defd9759d65e491170aa8331462869dcfe4f",
          uncompressedChecksumSha256: uncompressedChecksum,
        },
      },
    },
  });

  if (committed.error != null) {
    console.warn("FCC RPC failed:", committed.error.code);
    return jsonResponse(503, { error: "publication_commit_failed" });
  }

  return jsonResponse(200, {
    complete: true,
    competencyId,
    version,
    itemCount,
    checksumSha256: checksum,
    storagePath,
  });
});
