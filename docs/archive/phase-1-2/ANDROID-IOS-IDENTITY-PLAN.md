# Android & iOS App Identity Plan

## Kế Hoạch Định Danh Ứng Dụng Android & iOS

> **Define package names, bundle IDs, app icons, and branding for Tổng Tài.**

**Status:** 📋 DRAFT for Review  
**Phase:** 1B — Technology Planning  
**Owner:** Platform Team  
**Date:** 2026-07-13

---

## English — Android & iOS App Identity Plan

### Executive Summary

Tổng Tài is a separate app (distinct from Hub) on Android and iOS platforms. This document defines:

1. **Package name** (Android) — unique identifier for Play Store
2. **Bundle ID** (iOS) — unique identifier for App Store
3. **App name** — user-facing display name
4. **Icons & branding** — visual distinction from Hub
5. **Code signing** — certificate requirements

**Decision:** Tổng Tài is a separate app (not a flavor of Hub).

---

### Android App Identity

#### Package Name

**Recommendation:** `com.workizen.tongtai`

**Rationale:**
- Clear intent: "Workizen" (company) + "tongtai" (product)
- Follows Java naming conventions
- Reserves namespace for future Tổng Tài extensions
- Avoids conflicts with Hub (`ai.workizen.wallet`)
- Short, memorable, valid domain-style name

**Alternatives Considered:**
1. `com.workizen.business` — generic, could conflict with other Workizen business apps
2. `io.workizen.tongtai` — less common TLD
3. `app.tongtai` — too generic, no company branding

**Final Decision:** ✅ `com.workizen.tongtai`

#### Play Store App ID

**Value:** `com.workizen.tongtai`

**Google Play Console Setup:**
1. Create new app in Play Console
2. App name: "Tổng Tài" (Vietnamese) or "I Like a Boss" (English, alternative)
3. Package name: `com.workizen.tongtai`
4. App type: Business
5. Category: Business, Productivity, or Finance (TBD based on positioning)

#### App Signing

**Google Play App Signing (Recommended):**
- Google manages release signing certificate
- Developer upload signing certificate (separate)
- Reduces key loss risk

**Debug Signing:**
```bash
# Generate debug keystore (if not present)
keytool -genkey -v -keystore ~/.android/debug.keystore \
  -storepass android -alias androiddebugkey -keypass android \
  -keyalg RSA -keysize 2048 -validity 10000
```

**Release Signing:**
```bash
# Request from Platform Team
# Key: tongtai-release.keystore
# Alias: tongtai-release
# Validity: 25 years (Sept 2049)
```

---

### iOS App Identity

#### Bundle ID

**Recommendation:** `com.workizen.tongtai`

**Rationale:**
- Matches Android package name (for consistency)
- Follows reverse domain convention
- Clear intent: Workizen + Tổng Tài
- Avoids Hub's bundle ID (`ai.workizen.wallet`)

**Alternative Considered:**
1. `com.workizen.business` — generic
2. `io.workizen.tongtai` — less common
3. `app.tongtai` — too generic

**Final Decision:** ✅ `com.workizen.tongtai`

#### App Store Setup

**Apple App Store Connect:**
1. Request team member to create app in App Store Connect
2. App name: "Tổng Tài" (Vietnamese) or "I Like a Boss" (English)
3. Bundle ID: `com.workizen.tongtai`
4. Primary language: Vietnamese or English (TBD)
5. Category: Business
6. Content rating: Filled (automated)

#### Code Signing Certificate

**Development Certificate:**
- Team member: Generate on Mac (Xcode auto-manage)
- Valid for 1 year, auto-renews

**Distribution Certificate:**
- Valid for 3 years
- Used for App Store builds
- Requires Team Agent role in Apple Developer

**Provisioning Profiles:**
- Development Provisioning Profile (local testing)
- Ad Hoc Provisioning Profile (internal testing)
- App Store Provisioning Profile (release to App Store)

**Xcode Configuration:**
```
ios/Runner.xcodeproj/
  └── project.pbxproj
      PRODUCT_BUNDLE_IDENTIFIER = com.workizen.tongtai
      CODE_SIGN_IDENTITY = "Apple Distribution"
      PROVISIONING_PROFILE = "Tổng Tài App Store"
```

---

### App Icons & Branding

#### Icon Strategy

**Hub:** Gray/blue icon with document symbol  
**Tổng Tài:** Distinct icon, different color scheme (recommend: orange/green for business growth)

#### Icon Specifications

**Android Icon Sizes:**
- 192×192 px (hdpi)
- 144×144 px (mdpi)
- 96×96 px (xhdpi)
- 72×72 px (ldpi)
- 48×48 px (small)

**Location:**
```
mobile/tongtai/android/app/src/main/res/
  ├── mipmap-hdpi/ic_launcher.png
  ├── mipmap-mdpi/ic_launcher.png
  ├── mipmap-xhdpi/ic_launcher.png
  ├── mipmap-ldpi/ic_launcher.png
  └── mipmap-xxxhdpi/ic_launcher_foreground.png
```

**iOS Icon Sizes:**
- 1024×1024 px (App Store)
- 180×180 px (iPhone)
- 167×167 px (iPad)
- 120×120 px (iPhone Spotlight)
- 80×80 px (iPad Spotlight)
- 40×40 px (Small)
- 29×29 px (Settings)

**Location:**
```
mobile/tongtai/ios/Runner/Assets.xcassets/
  └── AppIcon.appiconset/
      ├── AppIcon-1024.png (App Store)
      ├── AppIcon-180.png (iPhone)
      ├── AppIcon-167.png (iPad)
      └── ... (other sizes)
```

#### Splash Screen

**Hub:** Hub branding (document + chat)  
**Tổng Tài:** Tổng Tài branding (business compass or briefcase icon)

**Splash Configuration:**
```yaml
# pubspec.yaml
flutter_native_splash:
  android: true
  ios: true
  web: false
  color: "#FFFFFF"
  background_image: "assets/tongtai/splash.png"
```

#### App Name

**Primary (Vietnamese):** Tổng Tài  
**Alternative (English):** I Like a Boss  
**Market (US):** Boss (Short form, if "I Like a Boss" is too long)

**Store Listing Names:**
- Google Play: "Tổng Tài — Business Operating System"
- App Store: "Tổng Tài for Entrepreneurs"

---

### Platform Configuration Files

#### Android: AndroidManifest.xml

```xml
<!-- mobile/tongtai/android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.workizen.tongtai">

    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:theme="@style/AppTheme">

        <activity
            android:name=".MainActivity"
            android:configChanges="..."
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
```

**Strings File:**
```xml
<!-- mobile/tongtai/android/app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Tổng Tài</string>
    <string name="app_name_short">Tổng Tài</string>
</resources>
```

#### Android: build.gradle

```gradle
# mobile/tongtai/android/app/build.gradle

android {
    compileSdk 34
    ndkVersion "25.1.8937393"

    defaultConfig {
        applicationId = "com.workizen.tongtai"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    signingConfigs {
        debug {
            keyAlias "androiddebugkey"
            keyPassword "android"
            storeFile file("~/.android/debug.keystore")
            storePassword "android"
        }
        release {
            keyAlias "tongtai-release"
            keyPassword "[STORED SECURELY]"
            storeFile file("tongtai-release.keystore")
            storePassword "[STORED SECURELY]"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile(
                'proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    flavorDimensions "product"
    productFlavors {
        tongtai {
            dimension "product"
            applicationId "com.workizen.tongtai"
        }
    }
}
```

#### iOS: Info.plist

```xml
<!-- mobile/tongtai/ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Tổng Tài</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>
</dict>
</plist>
```

#### iOS: Xcode Project

**Build Settings:**
```bash
PRODUCT_BUNDLE_IDENTIFIER = com.workizen.tongtai
PRODUCT_NAME = "Tổng Tài"
DEVELOPMENT_TEAM = [Team ID]
CODE_SIGN_STYLE = Automatic
```

---

### Version Numbering

**Format:** `MAJOR.MINOR.PATCH+BUILD`

**Examples:**
- `1.0.0+1` — Initial release
- `1.0.1+2` — Bug fix
- `1.1.0+5` — New feature
- `2.0.0+10` — Major release

**Android (build.gradle):**
```gradle
versionCode = 1      // Incremental build number
versionName = "1.0.0"
```

**iOS (Info.plist):**
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

**Flutter (pubspec.yaml):**
```yaml
version: 1.0.0+1  # Synced with Android/iOS
```

---

### Store Listings & Metadata

#### Google Play Store Listing

**Title:** Tổng Tài  
**Short Description (80 chars):** Business Operating System for entrepreneurs  
**Full Description (4000 chars):**
```
Tổng Tài is an AI-first Business Operating System for entrepreneurs and SMEs.

Combine business goals with AI-guided intelligence:
- Producer: Discover suppliers and arbitrage opportunities
- Inventory: Manage products and warehouse efficiently
- Consumer: Customer intelligence and CRM
- Finance: Understand cash flow and profitability
- Reports: Make data-driven business decisions
- Opportunity Hub: Let AI surface profitable opportunities
- Business Copilot: AI advisor in your pocket

Available in Vietnamese. Privacy-first: data stays on your device.
```

**Category:** Business or Productivity  
**Content Rating:** Everyone  
**Privacy Policy:** [Link to privacy.workizen.net]

#### App Store Listing

**Name:** Tổng Tài  
**Subtitle:** AI-First Business Operating System  
**Description:** [Same as Google Play]  
**Keywords:** business, sme, ai, ceo, entrepreneur, productivity  
**Support URL:** [support.workizen.net]  
**Privacy Policy URL:** [privacy.workizen.net]

---

### Checklist

- [ ] Finalize app name (Tổng Tài vs. I Like a Boss)
- [ ] Design app icon (1024×1024)
- [ ] Create splash screen
- [ ] Request keystore for release signing
- [ ] Set up Google Play Console project
- [ ] Set up App Store Connect project
- [ ] Configure Android build.gradle
- [ ] Configure iOS Info.plist
- [ ] Write store listing copy
- [ ] Add privacy policy URL

---

## Tiếng Việt — Kế Hoạch Định Danh Ứng Dụng Android & iOS

### Tóm Tắt Điều Hành

Tổng Tài là một ứng dụng riêng biệt (khác với Hub) trên các nền tảng Android và iOS. Tài liệu này định nghĩa:

1. **Tên gói** (Android) — định danh duy nhất cho Play Store
2. **Bundle ID** (iOS) — định danh duy nhất cho App Store
3. **Tên ứng dụng** — tên hiển thị cho người dùng
4. **Biểu tượng & thương hiệu** — phân biệt rõ ràng với Hub
5. **Ký mã** — yêu cầu chứng chỉ

**Quyết định:** Tổng Tài là một ứng dụng riêng biệt (không phải hương vị của Hub).

---

### Định Danh Ứng Dụng Android

#### Tên Gói

**Khuyến Nghị:** `com.workizen.tongtai`

**Lý Do:**
- Ý định rõ ràng: "Workizen" (công ty) + "tongtai" (sản phẩm)
- Tuân theo quy ước đặt tên Java
- Dự trữ không gian tên cho các mở rộng Tổng Tài trong tương lai
- Tránh xung đột với Hub (`ai.workizen.wallet`)
- Tên ngắn, dễ nhớ, kiểu tên miền hợp lệ

**Phiên Bản Thay Thế Xem Xét:**
1. `com.workizen.business` — chung chung, có thể xung đột
2. `io.workizen.tongtai` — TLD ít phổ biến hơn
3. `app.tongtai` — quá chung chung

**Quyết Định Cuối Cùng:** ✅ `com.workizen.tongtai`

#### ID Ứng Dụng Play Store

**Giá Trị:** `com.workizen.tongtai`

**Thiết Lập Google Play Console:**
1. Tạo ứng dụng mới trong Play Console
2. Tên ứng dụng: "Tổng Tài"
3. Tên gói: `com.workizen.tongtai`
4. Loại ứng dụng: Kinh doanh
5. Danh mục: Kinh doanh, Năng suất, hoặc Tài chính (TBD)

#### Ký Ứng Dụng

**Ký Ứng Dụng Google Play (Được Khuyến Nghị):**
- Google quản lý chứng chỉ ký phát hành
- Nhà phát triển tải chứng chỉ ký tải lên (riêng biệt)
- Giảm rủi ro mất khóa

---

### Định Danh Ứng Dụng iOS

#### Bundle ID

**Khuyến Nghị:** `com.workizen.tongtai`

**Lý Do:**
- Phù hợp với tên gói Android (để thống nhất)
- Tuân theo quy ước tên miền đảo ngược
- Ý định rõ ràng: Workizen + Tổng Tài
- Tránh Bundle ID của Hub

#### Thiết Lập App Store

**Apple App Store Connect:**
1. Yêu cầu thành viên đội tạo ứng dụng trong App Store Connect
2. Tên ứng dụng: "Tổng Tài"
3. Bundle ID: `com.workizen.tongtai`
4. Ngôn ngữ chính: Tiếng Việt hoặc Tiếng Anh
5. Danh mục: Kinh doanh

---

### Biểu Tượng Ứng Dụng & Thương Hiệu

#### Chiến Lược Biểu Tượng

**Hub:** Biểu tượng xám/xanh với ký hiệu tài liệu  
**Tổng Tài:** Biểu tượng riêng biệt, bảng màu khác (khuyến nghị: cam/xanh lá cho tăng trưởng kinh doanh)

#### Tên Ứng Dụng

**Chính (Tiếng Việt):** Tổng Tài  
**Thay Thế (Tiếng Anh):** I Like a Boss

---

**Version:** 1.0 (Draft)  
**Next Review:** After design system is finalized
