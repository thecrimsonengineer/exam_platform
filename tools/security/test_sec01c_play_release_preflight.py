"""SEC-01C safe Play-release preflight tests. No credentials are generated."""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from sec01b_android_identity import BASELINE_ID, PLAY_ID
from sec01c_play_release_preflight import check
from test_sec01b_android_identity import fixture


GUARD = '''
val csp11PlayRelease = System.getenv("CSP11_PLAY_RELEASE") == "true"
if (csp11ReleaseBundleRequested && !csp11PlayRelease) {}
if (csp11AndroidKeyAlias.equals("androiddebugkey", ignoreCase = true)) {}
require(defaultConfig.applicationId == "com.csp11.examplatform")
require(namespace == "com.csp11.examplatform")
'''


def make_ready(root: Path) -> dict[str, str]:
    fixture(root, PLAY_ID)
    gradle = root / "android/app/build.gradle.kts"
    gradle.write_text(gradle.read_text(encoding="utf-8") + GUARD, encoding="utf-8")
    keyfile = root / "upload.jks"
    keyfile.write_bytes(b"fixture only, not a real signing key")
    return {
        "CSP11_PLAY_RELEASE": "true",
        "SUPABASE_URL": "https://esfycnmfywxczfillioj.supabase.co",
        "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_dummy_client_key",
        "CSP11_ANDROID_KEYSTORE_PATH": str(keyfile),
        "CSP11_ANDROID_KEYSTORE_PASSWORD": "fixture password",
        "CSP11_ANDROID_KEY_ALIAS": "csp11-upload",
        "CSP11_ANDROID_KEY_PASSWORD": "fixture password",
        "CSP11_PLAY_UPLOAD_CERT_SHA256": "1" * 64,
        "CSP11_PLAY_APP_SIGNING_SHA1": "aa" * 20,
    }


class ReleasePreflightTests(unittest.TestCase):
    def test_matching_test_fixture_passes_metadata_preflight(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            self.assertEqual(check(root, env), [])

    def test_old_android_identity_blocks_store_build(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            fixture(root, BASELINE_ID)
            self.assertTrue(any("applicationId" in x for x in check(root, env)))

    def test_missing_play_flag_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env.pop("CSP11_PLAY_RELEASE")
            self.assertTrue(any("CSP11_PLAY_RELEASE" in x for x in check(root, env)))

    def test_debug_signing_alias_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env["CSP11_ANDROID_KEY_ALIAS"] = "androiddebugkey"
            self.assertTrue(any("Debug signing" in x for x in check(root, env)))

    def test_missing_keystore_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env["CSP11_ANDROID_KEYSTORE_PATH"] = str(root / "missing.jks")
            self.assertTrue(any("KEYSTORE_PATH" in x for x in check(root, env)))

    def test_missing_signing_secret_blocks_without_disclosing_value(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            secret = env["CSP11_ANDROID_KEY_PASSWORD"]
            env["CSP11_ANDROID_KEY_PASSWORD"] = ""
            errors = check(root, env)
            self.assertTrue(any("KEY_PASSWORD" in x for x in errors))
            self.assertNotIn(secret, "\n".join(errors))

    def test_server_key_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env["SUPABASE_PUBLISHABLE_KEY"] = "sb_secret_do_not_embed"
            self.assertTrue(any("publishable key" in x for x in check(root, env)))

    def test_fingerprint_missing_or_invalid_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env["CSP11_PLAY_UPLOAD_CERT_SHA256"] = "abc"
            self.assertTrue(any("fingerprint" in x for x in check(root, env)))

    def test_missing_play_signing_sha1_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env.pop("CSP11_PLAY_APP_SIGNING_SHA1")
            self.assertTrue(any("Play app-signing SHA-1" in x for x in check(root, env)))

    def test_unregistered_play_sha1_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            env["CSP11_PLAY_APP_SIGNING_SHA1"] = "bb" * 20
            self.assertTrue(any("not registered for Nova" in x for x in check(root, env)))

    def test_absent_gradle_guard_blocks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = make_ready(root)
            gradle = root / "android/app/build.gradle.kts"
            gradle.write_text(gradle.read_text(encoding="utf-8").replace(GUARD, ""), encoding="utf-8")
            self.assertTrue(any("Gradle Play guard" in x for x in check(root, env)))


if __name__ == "__main__":
    unittest.main()
