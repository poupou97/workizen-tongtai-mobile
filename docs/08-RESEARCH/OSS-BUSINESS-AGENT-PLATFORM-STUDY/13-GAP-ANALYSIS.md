# 13 · Gap Analysis — từng sản phẩm Workizen soi qua 5 repo

> WTM-453 · 2026-08-25 · Priority: 🔴 nên làm sớm · 🟡 khi có cớ nghiệp vụ ·
> 🟢 ghi nhận, chưa cần · ⛔ Founder Gate. "OSS ref" = nơi có bài học, KHÔNG
> phải nơi lấy code (license gate ở `15`).

## Tổng Tài — 8 capability

| Capability | Hiện có | OSS ref tốt nhất | Gap | Priority |
|---|---|---|---|---|
| Producer (sourcing) | Supplier + SupplierQuote (quotedAt, provenance — **hơn** ERPNext ở tuổi báo giá) · BusinessInput | ERPNext buying | Không có PO→Receipt→Invoice; **đúng cho SME hiện tại** (ERPNext tự chứng minh chuỗi này là tuỳ chọn: `so_required='No'`) | 🟢 |
| Inventory | totalStock scalar + reorderLevel | ERPNext stock | **① totalStock không sự kiện nguồn, orders không trừ kho** · ② `stockValue` dùng giá bán trái docstring · ③ reorder mới trả lời 1/4 câu trong khi `leadTimeDays`+MOQ nằm sẵn ở supplier_quotes (P-31) | ② 🔴 rẻ · ③ 🔴 rẻ · ① 🟡 cần ADR |
| Consumer (CDP/CRM) | Customer + ExternalIdentity + confidence; gộp khách không bao giờ tự động | Relaticle | Custom field của họ **thiếu** namespace/shadow-core guard — ta đi trước; học `creation_source` badge + re-inject resolved mỗi turn | 🟢 |
| Finance | Single-entry + Settlement/TrueProfit (từ chối trả số) | ERPNext GL | Cột chết `TransactionsTable.orderId/account/isReconciled` · phí sàn có thể tồn tại 2 lần (Finance + Settlement — ADR-024 chấp nhận có ý thức, nhưng chưa có cảnh báo dedupe khi cả hai cùng có) | 🟡 |
| Orders | CustomerOrder một-document + OrderItem snapshot `unitPrice` | ERPNext selling | **Chưa snapshot `costPrice` lúc chốt đơn** — giá vốn đổi sau làm lời thật của đơn CŨ đổi theo (ERPNext: chốt lúc xuất kho). Cùng họ WTM-126 | 🔴 rẻ, giá trị lớn |
| Reports/Journey/Opportunity | Rule Twin + coverage tự khai (ADR-022) | — | Không repo nào có tương đương — **điểm mạnh riêng** | 🟢 |
| Agentic Foundation | Evidence→ProposedChange→BusinessAction một cửa | Relaticle (phản ví dụ) · Plane | ProposedChange chỉ có approve/reject — học **IntakeIssue triage** của Plane: SNOOZED (`snoozed_till`) + DUPLICATE (`duplicate_to`) | 🟡 |
| Connector/File Bridge | Provenance 5 nguồn + import báo cáo đủ | — | Không repo nào có provenance — **điểm mạnh riêng, đầu tư đúng** | 🟢 |

Ngoài bảng: enum cũ (`OrderStatus`, `TransactionType.fromStorage`) mã lạ rơi về
default — trái ADR-TON-018 mà enum mới đã theo; sửa là việc nhỏ nhưng đụng
migration đọc dữ liệu cũ ⇒ 🔴 có kèm cẩn trọng.

## AI Workforce Runtime

| Capability | Hiện có | Trigger.dev | Gap | Priority |
|---|---|---|---|---|
| Queue + visibility | Jira (luật 4 cổng) | Redis vô hình | **Giữ Jira** — queue vô hình phạm luật visibility | 🟢 |
| Verdict | Evidence spine (judge/placebo/codegen) | không có — họ TIN task code | **Ta đi trước** — giữ | 🟢 |
| Single-instance | 2 khoá ở 2 plane **không thấy nhau** | fencing `snapshotId`, không lock | ⛔ FLAG: hợp nhất MỘT plane + một khoá theo work-order | ⛔ Founder |
| Crash visibility | status.json + RECONCILE prompt | snapshot append-only | Execution-state log (JSON, append-only) | ⛔ cùng FLAG |
| Chết im lặng | không ai phát hiện supervisor chết | deadman per-state | Watchdog ngoài tiến trình (cron) | ⛔ cùng FLAG |
| Retry | 1 lần + fix-brief + escalate model | phân loại lỗi, trần 250 | Học duy nhất **phân loại transient** (mạng/API chết ≠ lỗi chất lượng) | 🟡 |
| Device preflight | WH-285 3 nguồn, stamp mọi evidence | không có khái niệm | **Ta đi trước** | 🟢 |

## AI Teams

| Capability | Hiện có | Lago | Gap | Priority |
|---|---|---|---|---|
| Cost/credit ledger | WAT-16 (PROPOSED): append-only + available/**reserved** | wallet 2 nguồn, **không escrow** | WAT-16 đúng hướng hơn Lago ở đúng chỗ cần nhất; bổ sung 5 điểm: granted-tiêu-trước-purchased · expiry · threshold top-up · meter tách pricing · draft/finalize | 🟡 — vào WAT-16, chờ Founder |
| Billing engine | chưa có | 8 charge model | **Chưa cần** — chưa pháp nhân (bức tường 2026-08-22), chưa khách trả tiền | 🟢 |
| Work mgmt | Jira | Plane | NO MIGRATION; học REST-trực-tiếp thay JQL-qua-MCP | 🟡 |
