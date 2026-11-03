#!/usr/bin/env python3
"""SEC-01C fail-closed preflight for CSP11 Google Play signing.

This script never prints credential values or creates a keystore.
The first_upload stage skips only the not-yet-generated Play distribution
certificate; upload-key signing and all other release gates are mandatory.
It verifies that the repository is configured for the *new* Android ID,
that only public Supabase client settings are included, and that expected
signing metadata is present. The actual certificate is verified using
keytool, and the signed AAB is verified independently in CI.
"""
from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path
from typing import Mapping

from sec01b_android_identity import inspect as inspect_android_identity

EXPECTED_SUPABASE_URL = "https://esfycnmfywxczfillioj.supabase.co"
EXPECTED_ALIAS_BAN = "androiddebugkey"
FINGERPRINT = re.compile(r"^[a-fA-F0-9]{64}$")


def check(root: Path, env: Mapping[str, str]) -> list[str]:
    errors = inspect_android_identity(root, "release")

    if env.get("CSP11_PLAY_RELEASE") != "true":
        errors.append("CSP11_PLAY_RELEASE must equal true.")
    if env.get("SUPABASE_URL", "").rstrip("/") != EXPECTED_SUPABASE_URL:
        errors.append("SUPABASE_URL is missing or does not match the expected project.")
    publishable_key = env.get("SUPABASE_PUBLISHABLE_KEY", "").strip()
    if not publishable_key.startswith("sb_publishable_") or len(publishable_key) <= 15:
        errors.append("Expected a Supabase publishable key, not a server/secret key.")

    for name in (
        "CSP11_ANDROID_KEYSTORE_PASSWORD",
        "CSP11_ANDROID_KEY_ALIAS",
        "CSP11_ANDROID_KEY_PASSWORD",
    ):
        if not env.get(name, "").strip():
            errors.append(f"{name} must be supplied through CI secrets.")

    alias = env.get("CSP11_ANDROID_KEY_ALIAS", "").strip().lower()
    if alias == EXPECTED_ALIAS_BAN or "debug" in alias:
        errors.append("Debug signing aliases are forbidden for Play.")

    keystore = env.get("CSP11_ANDROID_KEYSTORE_PATH", "").strip()
    if not keystore or not Path(keystore).is_file():
        errors.append("CSP11_ANDROID_KEYSTORE_PATH must refer to an existing keystore.")

    expected_fingerprint = env.get("CSP11_PLAY_UPLOAD_CERT_SHA256", "").replace(":", "")
    if not FINGERPRINT.fullmatch(expected_fingerprint):
        errors.append("Expected SHA-256 upload certificate fingerprint is missing/invalid.")

    # The initial upload key is independently verified in the CI signature step.
    # Google Play generates a separate distribution signing certificate at setup,
    # which cannot be required before the very first bundle upload.
    release_stage = env.get("CSP11_RELEASE_STAGE", "")
    if release_stage not in ("first_upload", "post_play_signing"):
        errors.append("CSP11_RELEASE_STAGE must be first_upload or post_play_signing.")
    elif release_stage == "post_play_signing":
        play_sha1 = env.get("CSP11_PLAY_APP_SIGNING_SHA1", "").replace(":", "").strip().lower()
        if not re.fullmatch(r"[a-f0-9]{40}", play_sha1):
            errors.append("Expected Play app-signing SHA-1 is missing or invalid.")
        else:
            firebase_cfg = json.loads(
                (root / "android/app/google-services.json").read_text(encoding="utf-8")
            )
            nova_clients = [
                client for client in firebase_cfg.get("client", [])
                if client.get("client_info", {}).get("android_client_info", {}).get("package_name")
                == "com.csp11.examplatform"
            ]
            configured = {
                item.get("android_info", {}).get("certificate_hash", "").lower()
                for client in nova_clients
                for item in client.get("oauth_client", [])
                if item.get("client_type") == 1
            }
            if play_sha1 not in configured:
                errors.append("Play app-signing SHA-1 is not registered for Nova in Firebase.")

    gradle = (root / "android/app/build.gradle.kts").read_text(encoding="utf-8")
    for fragment in (
        'System.getenv("CSP11_PLAY_RELEASE") == "true"',
        "csp11ReleaseBundleRequested && !csp11PlayRelease",
        'csp11AndroidKeyAlias.equals("androiddebugkey"',
        'require(defaultConfig.applicationId == "com.csp11.examplatform")',
        'require(namespace == "com.csp11.examplatform")',
        "targetSdk = 36",
    ):
        if fragment not in gradle:
            errors.append("Gradle Play guard is missing an expected release protection.")
            break
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    try:
        errors = check(args.root, os.environ)
    except (OSError, ValueError, TypeError, KeyError) as exc:
        errors = [f"Unable to evaluate release preflight ({type(exc).__name__})."]
    if errors:
        print("SEC-01C PLAY RELEASE: BLOCKED")
        for error in errors:
            print(f"  - {error}")
        return 1
    print("SEC-01C PLAY RELEASE: CONFIGURATION PASS")
    print("The actual signing certificate and AAB must still be verified in CI.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
