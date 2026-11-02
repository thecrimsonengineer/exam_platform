#!/usr/bin/env python3
"""SEC-01D: verify the approved CSP11 Nova app name across Android/Flutter/Web.

Branding is independent from Android package identity and Firebase registration.
This tool never alters files, credentials, or the frozen source branch.
"""
from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

PLAY_NAME = "CSP 11 Nova: CSP Exam Prep."
SHORT_NAME = "CSP 11 Nova"
MAX_PLAY_TITLE_CHARS = 30


def inspect_branding(root: Path) -> list[str]:
    errors: list[str] = []
    if len(PLAY_NAME) > MAX_PLAY_TITLE_CHARS:
        errors.append("Google Play title exceeds 30 characters.")

    manifest = (root / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
    if not re.search(r'android:label\s*=\s*"@string/app_name"', manifest):
        errors.append("AndroidManifest must reference @string/app_name.")

    resource = ET.parse(root / "android/app/src/main/res/values/strings.xml").getroot()
    app_names = [
        (node.text or "").strip()
        for node in resource.findall("string")
        if node.attrib.get("name") == "app_name"
    ]
    if app_names != [PLAY_NAME]:
        errors.append("Android string app_name does not match the approved title.")

    dart = (root / "lib/main.dart").read_text(encoding="utf-8")
    if f"title: '{PLAY_NAME}'," not in dart:
        errors.append("MaterialApp title does not match the approved title.")

    web = (root / "web/index.html").read_text(encoding="utf-8")
    if f"<title>{PLAY_NAME}</title>" not in web:
        errors.append("Web document title does not match the approved title.")
    if f'content="{SHORT_NAME}"' not in web:
        errors.append("Web home-screen name does not match the short brand.")

    pwa = json.loads((root / "web/manifest.json").read_text(encoding="utf-8"))
    if pwa.get("name") != PLAY_NAME:
        errors.append("PWA name does not match the approved title.")
    if pwa.get("short_name") != SHORT_NAME:
        errors.append("PWA short_name must be CSP 11 Nova.")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    try:
        errors = inspect_branding(args.root)
    except (OSError, ValueError, TypeError, ET.ParseError) as exc:
        errors = [f"App branding configuration invalid ({type(exc).__name__})."]
    if errors:
        print("SEC-01D BRANDING: BLOCKED")
        for error in errors:
            print(f"  - {error}")
        return 1
    print(f"SEC-01D BRANDING: PASS ({len(PLAY_NAME)}/30 Play title characters)")
    print("Android / Flutter / Web / PWA names are consistent.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
