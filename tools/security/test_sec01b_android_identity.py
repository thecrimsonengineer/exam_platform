"""Unit tests for SEC-01B Android/Firebase identity preflight."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from sec01b_android_identity import BASELINE_ID, FIREBASE_PROJECT, PLAY_ID, inspect


def write(root: Path, name: str, content: str) -> None:
    dest = root / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content, encoding="utf-8")


def fixture(root: Path, package: str, *, oauth: bool = True) -> None:
    app_id = "1:123456789:android:abcdef"
    write(root, "android/app/build.gradle.kts", (
        'android {\n'
        f'    namespace = "{package}"\n'
        f'    defaultConfig {{ applicationId = "{package}" }}\n'
        '}\n'
    ))
    # Use a literal app ID line as the actual repo does; no alternate Gradle syntax.
    write(root, "android/app/build.gradle.kts", (
        f'    namespace = "{package}"\n'
        '    defaultConfig {\n'
        f'        applicationId = "{package}"\n'
        '    }\n'
    ))
    write(root, "android/app/src/main/kotlin/" + "/".join(package.split(".")) + "/MainActivity.kt",
          f"package {package}\nclass MainActivity\n")
    write(root, "android/app/src/main/AndroidManifest.xml",
          '<manifest><application><activity android:name=".MainActivity" /></application></manifest>\n')
    client = {
        "client_info": {
            "mobilesdk_app_id": app_id,
            "android_client_info": {"package_name": package},
        },
        "oauth_client": [
            {"client_type": 3, "client_id": "example"},
            {"client_type": 1, "android_info": {
                "package_name": package, "certificate_hash": "aa" * 20
            }}
        ] if oauth else [],
    }
    write(root, "android/app/google-services.json", json.dumps({
        "project_info": {"project_id": FIREBASE_PROJECT}, "client": [client]
    }))
    write(root, "firebase.json", json.dumps({"flutter": {"platforms": {
        "android": {"default": {"projectId": FIREBASE_PROJECT, "appId": app_id}},
        "dart": {"lib/firebase_options.dart": {
            "configurations": {"android": app_id}
        }},
    }}}))
    write(root, "lib/firebase_options.dart", (
        'class DefaultFirebaseOptions {\n'
        '  static const FirebaseOptions android = FirebaseOptions(\n'
        f"    appId: '{app_id}',\n"
        f"    projectId: '{FIREBASE_PROJECT}',\n"
        '  );\n'
        '}\n'
    ))


class IdentityTests(unittest.TestCase):
    def test_baseline_still_supported(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root, BASELINE_ID)
            self.assertEqual(inspect(root, "baseline"), [])

    def test_release_requires_new_id(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root, BASELINE_ID)
            self.assertTrue(any("applicationId" in e for e in inspect(root, "release")))

    def test_registered_release_fixture(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root, PLAY_ID)
            self.assertEqual(inspect(root, "release"), [])

    def test_wrong_firebase_project_fails_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root, PLAY_ID)
            file = root / "android/app/google-services.json"
            data = json.loads(file.read_text(encoding="utf-8"))
            data["project_info"]["project_id"] = "wrong-firebase-project"
            file.write_text(json.dumps(data), encoding="utf-8")
            self.assertTrue(any("project ID mismatch" in e for e in inspect(root, "release")))

    def test_google_sign_in_sha_registration_required(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root, PLAY_ID, oauth=False)
            self.assertTrue(any("signing SHA-1" in e for e in inspect(root, "release")))

    def test_main_activity_namespace_mismatch_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root, PLAY_ID)
            (root / "android/app/src/main/kotlin/com/csp11/examplatform/MainActivity.kt").unlink()
            self.assertTrue(any("MainActivity.kt missing" in e for e in inspect(root, "release")))


if __name__ == "__main__":
    unittest.main()
