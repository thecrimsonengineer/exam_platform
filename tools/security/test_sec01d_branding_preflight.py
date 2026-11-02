"""SEC-01D branding regression tests with self-contained fixtures."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from sec01d_branding_preflight import PLAY_NAME, SHORT_NAME, inspect_branding


def write(root: Path, name: str, contents: str) -> None:
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents, encoding="utf-8")


def setup_branding(root: Path) -> None:
    write(root, "android/app/src/main/AndroidManifest.xml",
          '<manifest><application android:label="@string/app_name" /></manifest>')
    write(root, "android/app/src/main/res/values/strings.xml",
          f'<resources><string name="app_name">{PLAY_NAME}</string></resources>')
    write(root, "lib/main.dart", f"MaterialApp(title: '{PLAY_NAME}',);")
    write(root, "web/index.html",
          f'<meta name="apple-mobile-web-app-title" content="{SHORT_NAME}"><title>{PLAY_NAME}</title>')
    write(root, "web/manifest.json",
          json.dumps({"name": PLAY_NAME, "short_name": SHORT_NAME}))


class BrandingTests(unittest.TestCase):
    def test_approved_title_within_play_limit(self):
        self.assertLessEqual(len(PLAY_NAME), 30)
        self.assertEqual(len(PLAY_NAME), 28)

    def test_consistent_branding_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            setup_branding(root)
            self.assertEqual(inspect_branding(root), [])

    def test_wrong_android_label_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            setup_branding(root)
            write(root, "android/app/src/main/AndroidManifest.xml",
                  '<manifest><application android:label="exam_platform" /></manifest>')
            self.assertTrue(any("AndroidManifest" in e for e in inspect_branding(root)))

    def test_wrong_flutter_title_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            setup_branding(root)
            write(root, "lib/main.dart", "MaterialApp(title: 'exam_platform',);")
            self.assertTrue(any("MaterialApp" in e for e in inspect_branding(root)))

    def test_wrong_pwa_title_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            setup_branding(root)
            write(root, "web/manifest.json",
                  json.dumps({"name": "exam_platform", "short_name": SHORT_NAME}))
            self.assertTrue(any("PWA name" in e for e in inspect_branding(root)))

    def test_missing_android_string_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            setup_branding(root)
            write(root, "android/app/src/main/res/values/strings.xml",
                  '<resources><string name="app_name">wrong</string></resources>')
            self.assertTrue(any("app_name" in e for e in inspect_branding(root)))


if __name__ == "__main__":
    unittest.main()
