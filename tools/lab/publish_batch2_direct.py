#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

PROJECT = "csp11-exam-platform"
DATABASE = "(default)"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/{DATABASE}/documents"
BUNDLE_PATH = Path("build/batch2_direct_release/release_bundle.json")


def token():
    value = os.environ.get("GOOGLE_OAUTH_ACCESS_TOKEN", "").strip()
    if not value:
        raise SystemExit("Missing GOOGLE_OAUTH_ACCESS_TOKEN.")
    return value


def request(method, url, payload=None):
    data = None if payload is None else json.dumps(payload).encode("utf-8")
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
        with urllib.request.urlopen(req, timeout=90) as resp:
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


def encode_fields(data):
    return {k: encode_value(v, k) for k, v in data.items()}


def doc_name(collection, doc_id):
    return f"projects/{PROJECT}/databases/{DATABASE}/documents/{collection}/{doc_id}"


def doc_url(collection, doc_id):
    return BASE + "/" + collection + "/" + doc_id


def exists(collection, doc_id):
    status, _ = request("GET", doc_url(collection, doc_id))
    return status == 200


def build_targets(bundle):
    targets = []
    for item in bundle["published"]:
        targets.append(("labPublishedVersions", item["id"], item["data"]))
    for item in bundle["staging"]:
        targets.append(("labProductionCatalogueStaging", item["id"], item["data"]))
    targets.append((
        "labProductionReleaseExtensionEvidence",
        bundle["q16Evidence"]["id"],
        bundle["q16Evidence"]["data"],
    ))
    targets.append((
        "labProductionReleaseExtensionState",
        bundle["q16State"]["id"],
        bundle["q16State"]["data"],
    ))
    targets.append((
        "labProductionReleaseExtensionAcceptance",
        bundle["q17Acceptance"]["id"],
        bundle["q17Acceptance"]["data"],
    ))
    targets.append((
        "labLearnerReleaseExtensionState",
        bundle["q17Visibility"]["id"],
        bundle["q17Visibility"]["data"],
    ))
    for item in bundle["learnerCatalogue"]:
        targets.append(("labLearnerCatalogue", item["id"], item["data"]))
    return targets


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

    targets = build_targets(bundle)
    if len(targets) != 34:
        raise SystemExit(f"Expected exactly 34 Batch 2 production documents, got {len(targets)}.")

    present = [(c, d) for c, d, _ in targets if exists(c, d)]
    if present:
        print("Direct release refused because target documents already exist:")
        for collection, doc_id in present:
            print(f"  {collection}/{doc_id}")
        raise SystemExit(2)

    writes = []
    for collection, doc_id, data in targets:
        writes.append({
            "update": {
                "name": doc_name(collection, doc_id),
                "fields": encode_fields(data),
            },
            "currentDocument": {"exists": False},
        })

    print(f"Committing {len(writes)} Batch 2 documents atomically...")
    status, response = request(
        "POST",
        f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/{DATABASE}/documents:commit",
        {"writes": writes},
    )
    if status != 200:
        raise SystemExit(f"Commit failed with status {status}.")
    write_results = response.get("writeResults", [])
    if len(write_results) != len(writes):
        raise SystemExit(
            f"Firestore returned {len(write_results)} write results for {len(writes)} writes."
        )

    missing = [(c, d) for c, d, _ in targets if not exists(c, d)]
    if missing:
        print("Post-commit verification found missing documents:")
        for collection, doc_id in missing:
            print(f"  {collection}/{doc_id}")
        raise SystemExit(3)

    _, q16 = request(
        "GET",
        doc_url("labProductionReleaseExtensionState", release_id),
    )
    _, q17 = request(
        "GET",
        doc_url("labLearnerReleaseExtensionState", release_id),
    )
    q16_released = (
        q16.get("fields", {}).get("released", {}).get("booleanValue") is True
    )
    q17_accepted = (
        q17.get("fields", {}).get("accepted", {}).get("booleanValue") is True
    )
    if not q16_released or not q17_accepted:
        raise SystemExit("Post-commit release markers did not verify.")

    print("BATCH2_DIRECT_RELEASE=SUCCESS")
    print("Q16=CLOSED")
    print("Q17=ACCEPTED")
    print("PUBLISHED=10/10")
    print("STAGED=10/10")
    print("LEARNER_CATALOGUE=10/10")
    print("LEGACY_RELEASE=UNTOUCHED")


if __name__ == "__main__":
    main()
