package com.example.exam_platform

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // CSP11 SECURITY S1
        // Protect the entire Android app window from screenshots,
        // screen recording / MediaProjection capture, and non-secure displays.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
