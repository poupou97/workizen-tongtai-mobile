# Known Gaps (trung thực, sau split)

| Gap | Mức | Kế hoạch |
|---|---|---|
| iOS build chưa verify (signing/SPM trong session) | ⚠️ BLOCKED-by-policy | Founder build Xcode khi cần; Android debug là kênh verify |
| App icon/splash = Flutter default | 🟡 | Chờ chốt mascot (open decision WTM-11) |
| `flutter run` launch chưa smoke-test trên emulator trong phiên split | 🟡 | Verify ở lần dev kế; 519 widget/unit/integration tests là lưới an toàn |
| Finance/Reports/Journey/Opportunity/Copilot-chat screens chưa build | 🟢 backlog | Sprint 3+ (WTM-76…102) |
| CI (GitHub Actions) chưa setup | 🟡 | Đề xuất: workflow analyze+test trên PR — task riêng |
| 17+ story Jira còn ở Code Review | 🟢 admin | Chuyển Done sau khi Founder xác nhận split |
| CHANGELOG.md chưa có | 🟢 | Tạo ở release đầu tiên (theo changelog rule) |
| `dart format` toàn repo chưa chạy như 1 lần chuẩn hoá | 🟢 | Chạy trong validation phase của handoff branch |
