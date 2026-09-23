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

android {
    namespace = "com.example.exam_platform"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.exam_platform"
        // You can update the following values to match your application needs.
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

    buildTypes {
        release {
            signingConfig =
                if (useExplicitCsp11Signing) {
                    signingConfigs.getByName("csp11Explicit")
                } else {
                    // Local development fallback retained until production store signing is configured.
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
