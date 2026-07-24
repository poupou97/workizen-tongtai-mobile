# ADR-TON-008: Drift Persistence — User Data First, Repository seam, Local Business

**Status:** ✅ ACCEPTED (Founder-directed, 2026-07-24 — option A APPROVED, P0.3)
**Related:** ADR-TON-001 (Platform/Product seam, extractable), ADR-TON-002
(Riverpod), ADR-TON-004 (chat local-only), WTM-117 (data-flow review), WTM-120.

## Decision / Quyết định (nguyên văn kiến trúc Founder)

```
UI → Controller → Repository → Store → Drift
```

- **Repository quyết định nguồn dữ liệu.** UI KHÔNG biết Demo / Drift / Cloud.
- **User Data First:** database thật của user **KHÔNG** seed dữ liệu mẫu; user mới
  bắt đầu **RỖNG**. Sample data chỉ phục vụ **Demo/Preview Mode** (Sample/Demo
  Repository), **không** ghi xuống Drift của user, **không** trộn demo + thật.
- **Local Business (root aggregate):** cho phép bootstrap một Local Business mặc
  định cho local-first. Thiết kế để sau này mở rộng **nhiều doanh nghiệp / cloud
  sync / account login** mà không refactor lớn — callers phụ thuộc
  `LocalWorkspace.ensureBusinessId`, không phụ thuộc id hằng.

## Implementation (WTM-120, Finance-first)

- **`core/local_workspace.dart`** — `LocalWorkspace.ensureBusinessId(db)`:
  idempotently seed 1 local User + 1 local Business (FK parents), tách biệt với
  demo owner/business của WTM-73. Fixed ids + `InsertMode.insertOrIgnore`.
- **`finance/finance_repository.dart`** — `FinanceRepository` (seam) +
  `DriftFinanceRepository` (real, scoped tới local business — start empty) +
  `SampleFinanceRepository` (demo, read-only, không persist) +
  `InMemoryFinanceRepository` (tests).
- **`FinanceController`** đọc/ghi qua Repository — `hydrate()` async load,
  `add()` persist qua repo.
- **`financeRepositoryProvider`** = `DriftFinanceRepository(tongtaiDatabaseProvider)`.
  Finance screen (real app) dùng provider → **rỗng cho user mới, persist entry**.

## Consequences

- ✅ Finance là module đầu tiên bền vững thật; user thật thấy sổ RỖNG cho tới khi
  tự nhập (đúng nguyên tắc "không giả dữ liệu như thật").
- ✅ Seam sạch: đổi nguồn (Drift/Sample/Cloud) không đụng UI (thỏa WTM-117).
- ⚠️ Demo Mode chưa có toggle UI — `SampleFinanceRepository` sẵn sàng cho khi cần.
- 🔜 Mở rộng cùng pattern sang Orders/Consumer/Inventory/Opportunity/Journey/
  Timeline khi phù hợp (P0.3 tiếp tục). Reports/Home hiện còn đọc sample orders —
  sẽ chuyển theo cùng seam.

## Principles honored

Event-driven · Service/Repository seam · Domain-first · Local-first · Repository
pattern · Test-first (in-memory AppDatabase roundtrip) · Clean Architecture —
không đánh đổi kiến trúc lấy tốc độ.
