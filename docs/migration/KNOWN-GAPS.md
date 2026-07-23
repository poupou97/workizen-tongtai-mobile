# Known Gaps (trung thực, sau split)

| Gap | Mức | Kế hoạch |
|---|---|---|
| iOS build chưa verify (signing/SPM trong session) | ⚠️ BLOCKED-by-policy | Founder build Xcode khi cần; Android debug là kênh verify |
| App icon/splash = Flutter default | 🟡 | Chờ chốt mascot (open decision WTM-11) |
| ~~App launch chưa smoke-test~~ → ✅ **VERIFIED 2026-07-22**: install + launch thành công trên Samsung thật (`adb install` Success, `MainActivity` started, Founder xem demo trực tiếp) | ✅ đóng | — |
| Finance/Reports/Journey/Opportunity/Copilot-chat screens chưa build | 🟢 backlog | Sprint 3+ (WTM-76…102) |
| ~~CI (GitHub Actions) chưa setup~~ → ✅ **WTM-107**: workflow format+analyze+test trên mỗi PR (`.github/workflows/ci.yml`, Flutter pin đúng revision local) | ✅ đóng | — |
| 17+ story Jira còn ở Code Review | 🟢 admin | Chuyển Done sau khi Founder xác nhận split |
| CHANGELOG.md chưa có | 🟢 | Tạo ở release đầu tiên (theo changelog rule) |
| `dart format` toàn repo chưa chạy như 1 lần chuẩn hoá | 🟢 | Chạy trong validation phase của handoff branch |
