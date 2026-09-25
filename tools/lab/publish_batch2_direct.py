#!/usr/bin/env python3
import json
import os
import socket
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROJECT = "csp11-exam-platform"
DATABASE = "(default)"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/{DATABASE}/documents"
COMMIT_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/{DATABASE}/documents:commit"
BUNDLE_PATH = Path("build/batch2_direct_release/release_bundle.json")
REQUEST_TIMEOUT_SECONDS = 120
MAX_CHUNKS_PER_COMMIT = 4


def token():
    value = os.environ.get("GOOGLE_OAUTH_ACCESS_TOKEN", "").strip()
    if not value:
        raise SystemExit("Missing GOOGLE_OAUTH_ACCESS_TOKEN.")
    return value


def request(method, url, payload=None):
    data = None if payload is None else json.dumps(payload, separators=(",", ":")).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": "Bearer " + token(),
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT_SECONDS) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", "replace")
        if exc.code == 404:
            return 404, {}
        raise RuntimeError(f"Firestore HTTP {exc.code}: {raw}") from exc


def encode_value(value, key=None):
    if value is None:
        return {"nullValue": None}
    if isinstance(value, bool):
        return {"booleanValue": value}
    if isinstance(value, int):
        return {"integerValue": str(value)}
    if isinstance(value, float):
        return {"doubleValue": value}
    if isinstance(value, str):
        if key == "publishedAt":
            return {"timestampValue": value}
        return {"stringValue": value}
    if isinstance(value, list):
        return {"arrayValue": {"values": [encode_value(v) for v in value]}}
    if isinstance(value, dict):
        return {
            "mapValue": {
                "fields": {k: encode_value(v, k) for k, v in value.items()}
            }
        }
    raise TypeError(f"Unsupported value type for {key}: {type(value)}")


def decode_value(value):
    if "nullValue" in value:
        return None
    if "booleanValue" in value:
        return value["booleanValue"]
    if "integerValue" in value:
        return int(value["integerValue"])
    if "doubleValue" in value:
        return value["doubleValue"]
    if "timestampValue" in value:
        return value["timestampValue"]
    if "stringValue" in value:
        return value["stringValue"]
    if "arrayValue" in value:
        return [decode_value(v) for v in value["arrayValue"].get("values", [])]
    if "mapValue" in value:
        return {
            k: decode_value(v)
            for k, v in value["mapValue"].get("fields", {}).items()
        }
    raise RuntimeError(f"Unsupported Firestore value: {value}")


def encode_fields(data):
    return {k: encode_value(v, k) for k, v in data.items()}


def doc_name(path):
    return f"projects/{PROJECT}/databases/{DATABASE}/documents/{path}"


def doc_url(path):
    return BASE + "/" + path


def load_document(path):
    status, payload = request("GET", doc_url(path))
    if status == 404:
        return None
    return {
        k: decode_value(v)
        for k, v in payload.get("fields", {}).items()
    }


def normalize_timestamp(value):
    if not isinstance(value, str):
        return value
    text = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return value
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def values_match(key, actual, expected):
    if key == "publishedAt":
        return normalize_timestamp(actual) == normalize_timestamp(expected)
    return actual == expected


def document_matches(path, expected):
    actual = load_document(path)
    if actual is None:
        return False
    return all(values_match(key, actual.get(key), value) for key, value in expected.items())


def require_existing_exact_or_missing(path, expected):
    actual = load_document(path)
    if actual is None:
        return False
    for key, value in expected.items():
        if not values_match(key, actual.get(key), value):
            raise SystemExit(
                "Existing Firestore document does not match the validated Batch 2 payload: "
                + path
                + " field="
                + key
            )
    print(f"RESUME verified existing {path}")
    return True


def write_target(path, data):
    return {
        "update": {
            "name": doc_name(path),
            "fields": encode_fields(data),
        },
        "currentDocument": {"exists": False},
    }


def commit_targets(label, targets):
    missing = []
    for path, data in targets:
        if not require_existing_exact_or_missing(path, data):
            missing.append((path, data))

    if not missing:
        print(f"{label}: already complete and verified.")
        return

    writes = [write_target(path, data) for path, data in missing]
    payload = {"writes": writes}
    payload_bytes = len(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    print(
        f"{label}: committing {len(writes)} document(s), "
        f"payload_bytes={payload_bytes}"
    )

    try:
        status, response = request("POST", COMMIT_URL, payload)
        if status != 200:
            raise RuntimeError(f"{label}: commit failed with status {status}.")
        write_results = response.get("writeResults", [])
        if len(write_results) != len(writes):
            raise RuntimeError(
                f"{label}: Firestore returned {len(write_results)} write results "
                f"for {len(writes)} writes."
            )
    except (TimeoutError, socket.timeout, urllib.error.URLError) as exc:
        print(f"{label}: commit response timed out; verifying server state before deciding.")
        mismatches = [
            path for path, data in missing if not document_matches(path, data)
        ]
        if mismatches:
            raise RuntimeError(
                f"{label}: timeout verification did not confirm commit: {mismatches}"
            ) from exc
        print(f"{label}: timeout recovered because all target documents were verified.")
        return

    mismatches = [
        path for path, data in missing if not document_matches(path, data)
    ]
    if mismatches:
        raise RuntimeError(f"{label}: post-commit verification failed: {mismatches}")
    print(f"{label}: commit verified.")


def batch(items, size):
    for start in range(0, len(items), size):
        yield items[start:start + size]


def main():
    if not BUNDLE_PATH.exists():
        raise SystemExit(f"Missing generated bundle: {BUNDLE_PATH}")
    bundle = json.loads(BUNDLE_PATH.read_text(encoding="utf-8"))

    if bundle.get("schemaVersion") != "csp11.lab.batch2.direct_release_bundle.v2":
        raise SystemExit("Unexpected direct release bundle schema.")
    if bundle.get("projectId") != PROJECT:
        raise SystemExit("Bundle project mismatch.")
    if bundle.get("labCount") != 10 or bundle.get("totalDecisionCount") != 50:
        raise SystemExit("Bundle count boundary mismatch.")

    release_id = bundle.get("releaseId")
    if release_id != "phase_l_population_batch2_v1_q16_extension_v1":
        raise SystemExit("Unexpected Batch 2 release ID.")

    parents = bundle.get("publishedParents", [])
    chunks = bundle.get("publishedChunks", [])
    staging = bundle.get("staging", [])
    learners = bundle.get("learnerCatalogue", [])

    if len(parents) != 10 or len(staging) != 10 or len(learners) != 10:
        raise SystemExit("Batch 2 release requires exactly 10 parents, staging rows and learner rows.")
    if not chunks or bundle.get("publishedChunkCount") != len(chunks):
        raise SystemExit("Batch 2 chunk inventory is missing or inconsistent.")

    chunk_targets_by_parent = {}
    for item in chunks:
        parent_id = item["parentId"]
        path = f"labPublishedVersions/{parent_id}/payloadChunks/{item['id']}"
        data = item["data"]
        encoded_bytes = len(json.dumps(data, separators=(",", ":")).encode("utf-8"))
        if encoded_bytes >= 800 * 1024:
            raise SystemExit(f"Chunk {path} exceeds the frozen 800 KiB safety boundary.")
        chunk_targets_by_parent.setdefault(parent_id, []).append((path, data))

    parent_targets = []
    for item in parents:
        parent_id = item["id"]
        expected_count = item["data"].get("payloadChunkCount")
        actual_count = len(chunk_targets_by_parent.get(parent_id, []))
        if not isinstance(expected_count, int) or expected_count != actual_count or actual_count <= 0:
            raise SystemExit(f"Chunk inventory mismatch for parent {parent_id}.")
        parent_targets.append((f"labPublishedVersions/{parent_id}", item["data"]))

    # Publish each heavy payload fail-closed: all immutable chunks first, then its
    # lightweight parent manifest. A partial chunk upload is invisible to runtime
    # because the parent version document does not exist until every chunk verifies.
    for parent_path, parent_data in parent_targets:
        parent_id = parent_path.split("/", 1)[1]
        parent_chunks = sorted(
            chunk_targets_by_parent[parent_id],
            key=lambda item: item[0],
        )
        for group_index, group in enumerate(batch(parent_chunks, MAX_CHUNKS_PER_COMMIT), start=1):
            commit_targets(
                f"CHUNKS {parent_id} group {group_index}",
                group,
            )
        commit_targets(f"PUBLISHED PARENT {parent_id}", [(parent_path, parent_data)])

    staging_targets = [
        (f"labProductionCatalogueStaging/{item['id']}", item["data"])
        for item in staging
    ]
    for index, target in enumerate(staging_targets, start=1):
        commit_targets(f"STAGING {index}/10", [target])

    q16_targets = [
        (
            f"labProductionReleaseExtensionEvidence/{bundle['q16Evidence']['id']}",
            bundle["q16Evidence"]["data"],
        ),
        (
            f"labProductionReleaseExtensionState/{bundle['q16State']['id']}",
            bundle["q16State"]["data"],
        ),
    ]
    commit_targets("Q16 CLOSE", q16_targets)

    learner_targets = [
        (f"labLearnerCatalogue/{item['id']}", item["data"])
        for item in learners
    ]
    for index, target in enumerate(learner_targets, start=1):
        commit_targets(f"CATALOGUE {index}/10", [target])

    q17_targets = [
        (
            f"labProductionReleaseExtensionAcceptance/{bundle['q17Acceptance']['id']}",
            bundle["q17Acceptance"]["data"],
        ),
        (
            f"labLearnerReleaseExtensionState/{bundle['q17Visibility']['id']}",
            bundle["q17Visibility"]["data"],
        ),
    ]
    commit_targets("Q17 ACCEPT + VISIBILITY", q17_targets)

    all_targets = []
    for items in chunk_targets_by_parent.values():
        all_targets.extend(items)
    all_targets.extend(parent_targets)
    all_targets.extend(staging_targets)
    all_targets.extend(q16_targets)
    all_targets.extend(learner_targets)
    all_targets.extend(q17_targets)

    mismatches = [
        path for path, data in all_targets if not document_matches(path, data)
    ]
    if mismatches:
        raise SystemExit(f"Final Batch 2 verification failed: {mismatches[:20]}")

    q16_state = load_document(
        f"labProductionReleaseExtensionState/{release_id}"
    ) or {}
    q17_state = load_document(
        f"labLearnerReleaseExtensionState/{release_id}"
    ) or {}

    if q16_state.get("released") is not True:
        raise SystemExit("Q16 release marker did not verify.")
    if q17_state.get("accepted") is not True:
        raise SystemExit("Q17 learner visibility marker did not verify.")

    print("BATCH2_DIRECT_RELEASE=SUCCESS")
    print("Q16=CLOSED")
    print("Q17=ACCEPTED")
    print("PUBLISHED_PARENTS=10/10")
    print(f"PUBLISHED_CHUNKS={len(chunks)}/{len(chunks)}")
    print("STAGED=10/10")
    print("LEARNER_CATALOGUE=10/10")
    print("LEGACY_RELEASE=UNTOUCHED")


if __name__ == "__main__":
    main()
