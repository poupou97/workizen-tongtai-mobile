plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// WTM-108 (ADR-TON-005, D-7): Firebase operational telemetry is wired but the
// Google Services plugin is applied ONLY when the Founder-provided config file
// exists. Without android/app/google-services.json the app still builds and
// telemetry silently no-ops (see lib/core/telemetry/).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    // Must accompany google-services whenever firebase_crashlytics is in the
    // dependency tree: the plugin injects the Crashlytics build ID; without
    // it the app crashes at launch inside FirebaseInitProvider.
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "com.workizen.tongtai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.workizen.tongtai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
