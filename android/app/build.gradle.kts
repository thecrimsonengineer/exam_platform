plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val csp11AndroidKeystorePath = System.getenv("CSP11_ANDROID_KEYSTORE_PATH")
val csp11AndroidKeystorePassword = System.getenv("CSP11_ANDROID_KEYSTORE_PASSWORD")
val csp11AndroidKeyAlias = System.getenv("CSP11_ANDROID_KEY_ALIAS")
val csp11AndroidKeyPassword = System.getenv("CSP11_ANDROID_KEY_PASSWORD")
val useExplicitCsp11Signing = !csp11AndroidKeystorePath.isNullOrBlank()

// SEC-01C: Play App Bundle builds may never silently use historical debug signing.
// Existing APK development/release-candidate workflows remain unchanged.
val csp11PlayRelease = System.getenv("CSP11_PLAY_RELEASE") == "true"
val csp11ReleaseBundleRequested = gradle.startParameter.taskNames.any {
    it.substringAfterLast(":").equals("bundleRelease", ignoreCase = true)
}
if (csp11ReleaseBundleRequested && !csp11PlayRelease) {
    throw GradleException(
        "SEC-01C: Android App Bundle release requires CSP11_PLAY_RELEASE=true."
    )
}
if (csp11PlayRelease) {
    require(useExplicitCsp11Signing) {
        "SEC-01C: Play signing keystore path is missing."
    }
    require(!csp11AndroidKeystorePassword.isNullOrBlank()) {
        "SEC-01C: Play signing store password is missing."
    }
    require(!csp11AndroidKeyAlias.isNullOrBlank()) {
        "SEC-01C: Play signing alias is missing."
    }
    require(!csp11AndroidKeyPassword.isNullOrBlank()) {
        "SEC-01C: Play signing key password is missing."
    }
    require(!csp11AndroidKeyAlias.equals("androiddebugkey", ignoreCase = true)) {
        "SEC-01C: Android debug signing alias is forbidden for Google Play."
    }
    require(file(csp11AndroidKeystorePath!!).isFile) {
        "SEC-01C: Play signing keystore file does not exist."
    }
}

android {
    namespace = "com.csp11.examplatform"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.csp11.examplatform"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (useExplicitCsp11Signing) {
            create("csp11Explicit") {
                storeFile = file(csp11AndroidKeystorePath!!)
                storePassword =
                    requireNotNull(csp11AndroidKeystorePassword) {
                        "CSP11_ANDROID_KEYSTORE_PASSWORD is required when explicit signing is enabled."
                    }
                keyAlias =
                    requireNotNull(csp11AndroidKeyAlias) {
                        "CSP11_ANDROID_KEY_ALIAS is required when explicit signing is enabled."
                    }
                keyPassword =
                    requireNotNull(csp11AndroidKeyPassword) {
                        "CSP11_ANDROID_KEY_PASSWORD is required when explicit signing is enabled."
                    }
            }
        }
    }

    if (csp11PlayRelease) {
        require(namespace == "com.csp11.examplatform") {
            "SEC-01B: Play namespace must match the reserved package ID."
        }
        require(defaultConfig.applicationId == "com.csp11.examplatform") {
            "SEC-01B: Play applicationId must match the reserved package ID."
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (csp11PlayRelease || useExplicitCsp11Signing) {
                    // Play intent requires verified explicit signing (checked above).
                    signingConfigs.getByName("csp11Explicit")
                } else {
                    // Historical APK-only release-candidate fallback preserved.
                    signingConfigs.getByName("debug")
                }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
