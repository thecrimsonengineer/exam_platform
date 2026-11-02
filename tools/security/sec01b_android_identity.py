#!/usr/bin/env python3
"""SEC-01B: verify CSP11 Android/Firebase identity before a Play build.

This checker is read-only. It never registers Firebase or Play apps.
Two modes:
  baseline : existing debug installation/configuration must remain consistent.
  release  : selected Play package and Firebase registration must agree.

Example:
  python tools/security/sec01b_android_identity.py --mode baseline
  python tools/security/sec01b_android_identity.py --mode release
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

FIREBASE_PROJECT = "csp11-exam-platform"
BASELINE_ID = "com.example.exam_platform"
PLAY_ID = "com.csp11.examplatform"
PACKAGE_PATTERN = re.compile(r"^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*){1,}$")


def _read(root: Path, relative: str) -> str:
    return (root / relative).read_text(encoding="utf-8")


def _json(root: Path, relative: str) -> dict:
    data = json.loads(_read(root, relative))
    if not isinstance(data, dict):
        raise ValueError(f"{relative}: expected JSON object")
    return data


def inspect(root: Path, mode: str) -> list[str]:
    errors: list[str] = []
    expected = PLAY_ID if mode == "release" else BASELINE_ID
    if not PACKAGE_PATTERN.fullmatch(PLAY_ID):
        errors.append(f"Proposed Play application ID has invalid syntax: {PLAY_ID}")

    gradle = _read(root, "android/app/build.gradle.kts")
    namespaces = re.findall(r'^\s*namespace\s*=\s*"([^"]+)"', gradle, re.M)
    ids = re.findall(r'^\s*applicationId\s*=\s*"([^"]+)"', gradle, re.M)
    if len(namespaces) != 1 or len(ids) != 1:
        errors.append("Gradle must declare exactly one literal namespace and applicationId")
        return errors

    namespace, app_id = namespaces[0], ids[0]
    if app_id != expected:
        errors.append(f"Gradle applicationId={app_id}, expected {expected}")
    if namespace != expected:
        errors.append(f"Gradle namespace={namespace}, expected {expected}")

    kotlin_path = root / "android/app/src/main/kotlin" / Path(*namespace.split(".")) / "MainActivity.kt"
    if not kotlin_path.is_file():
        errors.append(f"MainActivity.kt missing at namespace path {kotlin_path.relative_to(root)}")
    else:
        kotlin = kotlin_path.read_text(encoding="utf-8")
        if not re.search(r"^package\s+" + re.escape(namespace) + r"\s*$", kotlin, re.M):
            errors.append("MainActivity Kotlin package does not match Gradle namespace")

    manifest = _read(root, "android/app/src/main/AndroidManifest.xml")
    if 'android:name=".MainActivity"' not in manifest:
        errors.append("AndroidManifest.xml no longer references .MainActivity")

    google = _json(root, "android/app/google-services.json")
    project = google.get("project_info", {}).get("project_id")
    if project != FIREBASE_PROJECT:
        errors.append("google-services.json Firebase project ID mismatch")

    clients = google.get("client", [])
    if not isinstance(clients, list):
        clients = []
    matches = [
        x for x in clients
        if isinstance(x, dict)
        and x.get("client_info", {}).get("android_client_info", {}).get("package_name") == app_id
    ]
    if len(matches) != 1:
        errors.append(f"google-services.json must contain exactly one Android client for {app_id}")
        firebase_app_id = None
    else:
        firebase_app_id = matches[0].get("client_info", {}).get("mobilesdk_app_id")
        if not firebase_app_id or ":android:" not in firebase_app_id:
            errors.append("Matching Google Services client is missing its Android Firebase app ID")
        oauth = matches[0].get("oauth_client", [])
        if mode == "release":
            if not any(isinstance(c, dict) and c.get("client_type") == 3 for c in oauth):
                errors.append("Google Sign-In web OAuth client (client_type=3) missing")
            if not any(
                isinstance(c, dict) and c.get("client_type") == 1
                and c.get("android_info", {}).get("package_name") == app_id
                and c.get("android_info", {}).get("certificate_hash")
                for c in oauth
            ):
                errors.append("Google Sign-In Android signing SHA-1 registration missing")

    firebase_json = _json(root, "firebase.json")
    android = firebase_json.get("flutter", {}).get("platforms", {}).get("android", {}).get("default", {})
    dart = firebase_json.get("flutter", {}).get("platforms", {}).get("dart", {}).get(
        "lib/firebase_options.dart", {}
    ).get("configurations", {})
    if android.get("projectId") != FIREBASE_PROJECT:
        errors.append("firebase.json Android project ID mismatch")
    if firebase_app_id is not None and android.get("appId") != firebase_app_id:
        errors.append("firebase.json Android app ID differs from google-services.json")
    if firebase_app_id is not None and dart.get("android") != firebase_app_id:
        errors.append("firebase.json Dart Android app ID differs from google-services.json")

    options = _read(root, "lib/firebase_options.dart")
    android_block = re.search(
        r"static const FirebaseOptions android\s*=\s*FirebaseOptions\((.*?)\);",
        options,
        re.S,
    )
    if android_block is None:
        errors.append("FirebaseOptions.android block is missing")
    else:
        block = android_block.group(1)
        app_match = re.search(r"appId:\s*'([^']+)'", block)
        project_match = re.search(r"projectId:\s*'([^']+)'", block)
        if project_match is None or project_match.group(1) != FIREBASE_PROJECT:
            errors.append("FirebaseOptions.android project ID mismatch")
        if firebase_app_id is not None and (
            app_match is None or app_match.group(1) != firebase_app_id
        ):
            errors.append("FirebaseOptions.android app ID differs from google-services.json")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("baseline", "release"), required=True)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    try:
        errors = inspect(args.root, args.mode)
    except (OSError, ValueError, TypeError, KeyError) as exc:
        errors = [f"Unable to inspect Android identity: {exc}"]
    if errors:
        print(f"SEC-01B {args.mode.upper()}: BLOCKED")
        for error in errors:
            print(f"  - {error}")
        return 1
    print(f"SEC-01B {args.mode.upper()}: IDENTITY FILES CONSISTENT")
    print(f"Application ID: {PLAY_ID if args.mode == 'release' else BASELINE_ID}")
    if args.mode == "release":
        print("NOTE: Play Console package reservation and live sign-in must still be verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
