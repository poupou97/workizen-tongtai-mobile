# iOS Build Notes

*Lần build iOS đầu tiên: 2026-08-01 (WTM-175 Release Readiness)*

---

## Tóm tắt

Cho tới 2026-08-01, **iOS chưa từng được build lần nào** — đây là rủi ro R7 ghi
trong `docs/07-PRODUCT-RESET/08-MIGRATION-AND-RISK.md`: *"iOS chưa từng build —
có thể lộ vấn đề native muộn"*.

Lần build đầu tiên **thất bại**. Nguyên nhân và cách sửa ghi dưới đây.

| | |
|---|---|
| Kết quả cuối | ✅ `build/ios/iphoneos/Runner.app` — **31.1 MB** |
| Máy build | macOS 25.5, **Xcode 26.5**, CocoaPods 1.16.2 |
| Lệnh | `flutter build ios --release --no-codesign` |
| **Chưa làm được** | **chưa chạy trên thiết bị iOS thật** — cần tài khoản Apple Developer để ký |

## Lỗi gặp và cách sửa

### Lỗi: firebase_core yêu cầu iOS deployment target cao hơn

```
[!] Automatically assigning platform `iOS` with version `13.0` on target `Runner`
    because no platform was specified.
Error: The plugin "firebase_core" requires a higher minimum iOS deployment
version than your application is targeting.
To build, increase your application's deployment target to at least 15.0
Error running pod install
```

**Nguyên nhân:** dự án dùng template Flutter mặc định — `platform :ios` trong
`Podfile` **bị comment**, và `IPHONEOS_DEPLOYMENT_TARGET` trong Xcode project
là `13.0` ở cả 3 build configuration. Firebase (ADR-TON-005: Analytics +
Crashlytics operational-only) cần tối thiểu **15.0**.

**Sửa:**

| File | Thay đổi |
|---|---|
| `ios/Podfile` | bỏ comment + đặt `platform :ios, '15.0'` |
| `ios/Runner.xcodeproj/project.pbxproj` | `IPHONEOS_DEPLOYMENT_TARGET = 13.0` → `15.0` (**cả 3 configuration**) |
| `ios/Runner.xcworkspace/contents.xcworkspacedata` | thêm tham chiếu `Pods.xcodeproj` (`pod install` tự sinh) |
| `ios/Podfile.lock` | mới — pin phiên bản pod để build tái lập được |

**Hai chỗ phải khớp nhau.** Nếu chỉ sửa `Podfile` mà không sửa `pbxproj`, Xcode
sẽ cảnh báo target không khớp; nếu chỉ sửa `pbxproj`, `pod install` vẫn tự gán
13.0.

### Ảnh hưởng tới người dùng

iOS 15 chạy trên **iPhone 6s (2015) trở lên** — cùng dải thiết bị với iOS 13.
Nên thay đổi này **không loại bỏ dòng máy nào**; nó chỉ yêu cầu người dùng đã
cập nhật hệ điều hành. Và dù sao cũng **không có lựa chọn khác**: Firebase quy
định mức tối thiểu.

## Còn nợ — cần tài khoản Apple Developer

`--no-codesign` chứng minh **project build được**. Nó **không** chứng minh app
chạy được. Còn lại:

- [ ] Tài khoản Apple Developer + certificate + provisioning profile
- [ ] Bundle identifier `com.workizen.tongtai` đăng ký trên Apple
- [ ] **Chạy thật trên iPhone** — smoke test như quy định trong `CLAUDE.md` cho
      story chạm native/Firebase
- [ ] Firebase iOS app + `GoogleService-Info.plist`
      (⚠️ đang bị `.gitignore` bỏ qua — dòng 53 — nên chưa có trong repo)
- [ ] Kiểm quyền trong `Info.plist` khớp thực tế app dùng (chia sẻ file `.ttbk`)
- [ ] App Store Connect: privacy nutrition label khớp
      `docs/05-OPERATIONS/TELEMETRY-EVENTS.md`

## Cách build lại

```bash
flutter build ios --release --no-codesign     # không cần tài khoản Apple
flutter build ipa                             # cần ký, cho App Store
```

Lần đầu `pod install` mất **~80 giây** (tải Firebase pods). Các lần sau nhanh
hơn nhiều nhờ `Podfile.lock`.
