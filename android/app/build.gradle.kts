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
// WTM-464: biến thể cài đặt `.demo` (WTM-341) đã bị KHAI TỬ. Nó giải bài
// keystore-đổi-mà-phải-giữ-dữ-liệu của một thời điểm, nhưng để lại hai app
// Tổng Tài trên máy — Founder nhắc nhiều lần "chỉ MỘT app". Đường demo duy
// nhất là seed `sample-` TRONG app thật (ADR-TON-014). Đừng đem nó trở lại.
if (file("google-services.json").exists()) {
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

        manifestPlaceholders["appLabel"] = "Tổng Tài"
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

    // ⛔ P-33 · WTM-385 — MỌI buildType cài được lên máy phải ký GIỐNG NHAU.
    //
    // Trước WTM-385 chỉ `release` được cấu hình. `debug` và `profile` dùng khoá
    // debug mặc định, nên trên máy Founder — nơi `com.workizen.tongtai` đang
    // cài bằng khoá phát hành — cả hai lệnh dưới đều chết:
    //
    //     flutter run              → INSTALL_FAILED_UPDATE_INCOMPATIBLE
    //     flutter run --profile    → INSTALL_FAILED_UPDATE_INCOMPATIBLE
    //
    // Và lối thoát mọi hướng dẫn đưa ra là *"gỡ app rồi cài lại"* — nghe vô
    // hại, thực chất **xoá sạch dữ liệu kinh doanh thật**, không khôi phục
    // được. WTM-277 (`Ready`) yêu cầu đo scroll jank trên máy thật, tức phải
    // dùng bản **profile** — người nhận vé đó sẽ đi thẳng vào bẫy này.
    //
    // Bài học lớp lỗi: repo đã ghi lý do P-33 rất rõ, nhưng **ghi lý do là
    // chưa đủ nếu bản vá chỉ bịt một cửa**. Sau mỗi bản vá phải hỏi: *còn cửa
    // nào khác cùng lớp?*
    val installSigning = if (keystorePropertiesFile.exists()) {
        // Có khoá thật ⇒ ký bằng khoá thật, để bản dựng cài đè được lên bản
        // đang có trên máy.
        signingConfigs.getByName("release")
    } else {
        // Không có khoá ⇒ khoá debug, để CI và máy chưa có khoá vẫn build
        // được. Bản debug-signed KHÔNG upload lên Play được, nên nhầm lẫn này
        // không im lặng.
        signingConfigs.getByName("debug")
    }

    buildTypes {
        release { signingConfig = installSigning }
        debug { signingConfig = installSigning }
        // `profile` là bản Flutter dùng để ĐO hiệu năng — đúng bản WTM-277
        // cần, và đúng bản trước đây không ai ký.
        getByName("profile") { signingConfig = installSigning }
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
