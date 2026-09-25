#!/usr/bin/env python3
import json
import os
import socket
import urllib.error
import urllib.request
from pathlib import Path

PROJECT = "csp11-exam-platform"
DATABASE = "(default)"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/{DATABASE}/documents"
COMMIT_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/{DATABASE}/documents:commit"
BUNDLE_PATH = Path("build/batch2_direct_release/release_bundle.json")
REQUEST_TIMEOUT_SECONDS = 300


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


def doc_name(collection, doc_id):
    return f"projects/{PROJECT}/databases/{DATABASE}/documents/{collection}/{doc_id}"


def doc_url(collection, doc_id):
    return BASE + "/" + collection + "/" + doc_id


def load_document(collection, doc_id):
    status, payload = request("GET", doc_url(collection, doc_id))
    if status == 404:
        return None
    fields = payload.get("fields", {})
    return {k: decode_value(v) for k, v in fields.items()}


def document_matches(collection, doc_id, expected):
    actual = load_document(collection, doc_id)
    if actual is None:
        return False
    for key, value in expected.items():
        if actual.get(key) != value:
            return False
    return True


def require_existing_exact_or_missing(collection, doc_id, expected):
    actual = load_document(collection, doc_id)
    if actual is None:
        return False
    for key, value in expected.items():
        if actual.get(key) != value:
            raise SystemExit(
                "Existing Firestore document does not match the validated Batch 2 payload: "
                + collection
                + "/"
                + doc_id
                + " field="
                + key
            )
    print(f"RESUME verified existing {collection}/{doc_id}")
    return True


def write_target(collection, doc_id, data):
    return {
        "update": {
            "name": doc_name(collection, doc_id),
            "fields": encode_fields(data),
        },
        "currentDocument": {"exists": False},
    }


def commit_targets(label, targets):
    missing = []
    for collection, doc_id, data in targets:
        if not require_existing_exact_or_missing(collection, doc_id, data):
            missing.append((collection, doc_id, data))

    if not missing:
        print(f"{label}: already complete and verified.")
        return

    writes = [write_target(c, d, data) for c, d, data in missing]
    print(
        f"{label}: committing {len(writes)} document(s), "
        f"payload_bytes={len(json.dumps({'writes': writes}, separators=(',', ':')).encode('utf-8'))}"
    )

    try:
        status, response = request("POST", COMMIT_URL, {"writes": writes})
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
            (c, d)
            for c, d, data in missing
            if not document_matches(c, d, data)
        ]
        if mismatches:
            raise RuntimeError(
                f"{label}: timeout verification did not confirm the atomic commit: {mismatches}"
            ) from exc
        print(f"{label}: timeout recovered because all target documents were verified.")
        return

    mismatches = [
        (c, d)
        for c, d, data in missing
        if not document_matches(c, d, data)
    ]
    if mismatches:
        raise RuntimeError(f"{label}: post-commit verification failed: {mismatches}")
    print(f"{label}: commit verified.")


def main():
    if not BUNDLE_PATH.exists():
        raise SystemExit(f"Missing generated bundle: {BUNDLE_PATH}")
    bundle = json.loads(BUNDLE_PATH.read_text(encoding="utf-8"))

    if bundle.get("projectId") != PROJECT:
        raise SystemExit("Bundle project mismatch.")
    if bundle.get("labCount") != 10 or bundle.get("totalDecisionCount") != 50:
        raise SystemExit("Bundle count boundary mismatch.")

    release_id = bundle.get("releaseId")
    if release_id != "phase_l_population_batch2_v1_q16_extension_v1":
        raise SystemExit("Unexpected Batch 2 release ID.")

    published = [
        ("labPublishedVersions", item["id"], item["data"])
        for item in bundle["published"]
    ]
    staging = [
        ("labProductionCatalogueStaging", item["id"], item["data"])
        for item in bundle["staging"]
    ]
    q16 = [
        (
            "labProductionReleaseExtensionEvidence",
            bundle["q16Evidence"]["id"],
            bundle["q16Evidence"]["data"],
        ),
        (
            "labProductionReleaseExtensionState",
            bundle["q16State"]["id"],
            bundle["q16State"]["data"],
        ),
    ]
    catalogue = [
        ("labLearnerCatalogue", item["id"], item["data"])
        for item in bundle["learnerCatalogue"]
    ]
    q17 = [
        (
            "labProductionReleaseExtensionAcceptance",
            bundle["q17Acceptance"]["id"],
            bundle["q17Acceptance"]["data"],
        ),
        (
            "labLearnerReleaseExtensionState",
            bundle["q17Visibility"]["id"],
            bundle["q17Visibility"]["data"],
        ),
    ]

    total = len(published) + len(staging) + len(q16) + len(catalogue) + len(q17)
    if total != 34:
        raise SystemExit(f"Expected exactly 34 Batch 2 production documents, got {total}.")

    # Match the app's safe release semantics while avoiding one oversized HTTP body.
    # Published and staged rows are individually immutable and remain learner-hidden.
    for index, target in enumerate(published, start=1):
        commit_targets(f"PUBLISHED {index}/10", [target])

    for index, target in enumerate(staging, start=1):
        commit_targets(f"STAGING {index}/10", [target])

    # Q16 closes only after every published/staged row has been verified.
    commit_targets("Q16 CLOSE", q16)

    # Catalogue rows still remain hidden because Q17 visibility is not accepted yet.
    for index, target in enumerate(catalogue, start=1):
        commit_targets(f"CATALOGUE {index}/10", [target])

    # Q17 acceptance and learner visibility are the final atomic gate.
    commit_targets("Q17 ACCEPT + VISIBILITY", q17)

    all_targets = published + staging + q16 + catalogue + q17
    mismatches = [
        (c, d)
        for c, d, data in all_targets
        if not document_matches(c, d, data)
    ]
    if mismatches:
        raise SystemExit(f"Final Batch 2 verification failed: {mismatches}")

    q16_state = load_document("labProductionReleaseExtensionState", release_id) or {}
    q17_state = load_document("labLearnerReleaseExtensionState", release_id) or {}

    if q16_state.get("released") is not True:
        raise SystemExit("Q16 release marker did not verify.")
    if q17_state.get("accepted") is not True:
        raise SystemExit("Q17 learner visibility marker did not verify.")

    print("BATCH2_DIRECT_RELEASE=SUCCESS")
    print("Q16=CLOSED")
    print("Q17=ACCEPTED")
    print("PUBLISHED=10/10")
    print("STAGED=10/10")
    print("LEARNER_CATALOGUE=10/10")
    print("LEGACY_RELEASE=UNTOUCHED")


if __name__ == "__main__":
    main()
