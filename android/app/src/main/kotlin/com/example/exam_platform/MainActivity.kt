package com.example.exam_platform

import android.content.pm.PackageManager
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        private const val SCREENSHOT_PROTECTION_META_DATA =
            "com.csp11.SCREENSHOT_PROTECTION"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val metadata = packageManager
            .getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            .metaData
        val screenshotProtectionEnabled =
            metadata?.getBoolean(SCREENSHOT_PROTECTION_META_DATA, false) ?: false

        if (screenshotProtectionEnabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
