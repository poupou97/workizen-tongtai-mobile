import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// WTM-108 (ADR-TON-005, D-7): Firebase operational telemetry is wired but the
// Google Services plugin is applied ONLY when the Founder-provided config file
// exists. Without android/app/google-services.json the app still builds and
// telemetry silently no-ops (see lib/core/telemetry/).
// WTM-341 (E5 · Epic WTM-336): bản demo cho Founder chơi cài **song song**,
// không đè lên app thật.
//
// Lý do là một ràng buộc thật, không phải tiện tay: khoá ký đã đổi (WTM-332),
// nên cài đè bất khả thi, mà gỡ app thì mất dữ liệu kinh doanh thật của
// Founder — và Founder đã chốt GIỮ DỮ LIỆU. Một applicationId khác giải đúng
// bài đó: hai app, hai kho dữ liệu, không đụng gì nhau.
//
// Bật bằng biến môi trường chứ không phải flavor: một flavor sẽ nhân đôi mọi
// biến thể build cho một nhu cầu dùng vài lần.
val demoInstall = System.getenv("TONGTAI_DEMO_INSTALL") == "true"

// google-services.json chỉ khai `com.workizen.tongtai`. Bản demo mang id khác
// nên plugin sẽ ném "No matching client found" — bỏ qua Firebase ở bản demo,
// và telemetry tự no-op (lib/core/telemetry/).
if (file("google-services.json").exists() && !demoInstall) {
    apply(plugin = "com.google.gms.google-services")
    // Must accompany google-services whenever firebase_crashlytics is in the
    // dependency tree: the plugin injects the Crashlytics build ID; without
    // it the app crashes at launch inside FirebaseInitProvider.
    apply(plugin = "com.google.firebase.crashlytics")
}

// Khoá ký release đọc từ android/key.properties — file này bị gitignore và
// KHÔNG BAO GIỜ vào repo. Vắng mặt ⇒ rơi về khoá debug, nên `flutter run
// --release` vẫn chạy được trên máy chưa có khoá (và CI cũng vậy).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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

        if (demoInstall) {
            applicationIdSuffix = ".demo"
            versionNameSuffix = "-demo"
            // Nhãn khác trên màn hình chính. Hai biểu tượng giống hệt nhau là
            // cách chắc chắn nhất để Founder mở nhầm app rồi kết luận dữ liệu
            // thật đã mất.
            manifestPlaceholders["appLabel"] = "Tổng Tài DEMO"
        } else {
            manifestPlaceholders["appLabel"] = "Tổng Tài"
        }
    }

    signingConfigs {
        create("release") {
            // Chỉ cấu hình khi thật sự có khoá. Đọc mù rồi để Gradle ném lỗi
            // sẽ làm mọi máy chưa có khoá không build được release.
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Có khoá thật ⇒ ký bằng khoá thật. Không có ⇒ khoá debug, để
            // `flutter run --release` và CI vẫn chạy. Bản debug-signed KHÔNG
            // upload lên Play được, nên nhầm lẫn này không im lặng.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
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
