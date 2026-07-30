# 04 — Jira Audit | Rà soát & hành động trên Jira

## P0 stories
| Key | Nội dung | Trạng thái | Evidence |
|---|---|---|---|
| WTM-144 | §1 Data consistency — sample seeds vào production DB, one source | Done | PR #66 #67, `8b1e1d8`, 971 tests |
| WTM-145 | §2 Localization — 1 locale, key-based, cấm song ngữ | Done (comment 11188) | PR #68 `67ffb0f` + #70 `2ee7b6c`; CI 30524566502/30524930291 |
| WTM-146 | §3 Test governance + §6 Review Package | In Progress → Done khi package này merge | PR #71 `3c851d2`; CI 30527198729 + 30527199977; 990 tests |

⚠️ Numbering: title của WTM-144/145/146 trên Jira tự tham chiếu lệch 1 (đã ghi
comment làm rõ trên issue từ trước).

## Root-cause comments đã post (Done stories bị ảnh hưởng)
| Key | Bug class | Comment id |
|---|---|---|
| WTM-99 Data Export CSV | Export xuất fixture thay vì user data | 11182 |
| WTM-114 Business Timeline | Timeline đọc sample events | 11183 |
| WTM-82 AI Prompt Routing | Chat AI trả lời từ sample defaults | 11184 |
| WTM-95 Dashboard Layout | 2 dashboard song song lệch nhau | 11185 |
| WTM-119 Localization foundation | hoàn tất bởi WTM-145 (#68/#70) → Done | 11186 |
| WTM-102 Demo Data Loading | SUPERSEDED bởi ADR-TON-014 → Done | 11187 |

## Backlog sweep (status != Done, toàn bộ 2 trang)
- WTM-1..67 + 71..104 + 112: design/planning/AI-future Ideas — không cùng bug
  class, không action.
- WTM-122 Persistence Normalization: GIỮ NGUYÊN (lệnh Founder: KEEP CLOSED /
  không migration) — không đụng.
- Không có story Done nào khác cùng class chưa được xử lý (rà theo: demo/sample
  fallback, counts wiring, Opportunity source, empty-state/create actions,
  localization, mock-only tests).

## Latent risks phát hiện trong audit → ĐÃ xử lý ở §3 (PR #71)
1. `TongtaiReportsScreen` fallback `ReportsService.sample()` → `ReportsService(const [])` + scan lock. ✅
2. `TongtaiCustomerHistoryScreen._service` fallback `.sample()` → `(const [])` + scan lock. ✅
3. Supplier catalog = curated static directory (Phase 2, không có supplier repo) — GIỮ theo thiết kế, allowlist trong `p0/sample_fallback_scan_test.dart` + ghi chú ADR. ✅
4. **Bug mới do suite §3 phát hiện:** removeAll FK 787 (fix trong #71, khoá bằng drift_restart) + Home overflow 320px/1.3× (fix trong #71, khoá bằng overflow suite). ✅
