# 14 · Verdict — ADOPT / ADAPT / LEARN ONLY / REJECT

> WTM-453 · 2026-08-25 · Verdict 5 trục cho từng repo, gộp từ 03/05/07/09/11
> (chi tiết + evidence nằm ở đó). License gate (`15`) đứng TRÊN mọi ô Source
> code. Cột cuối là câu anti-overengineering: **"không học repo này thì mất
> gì?"** — trả lời trung thực, kể cả khi câu trả lời làm nghiên cứu bớt oai.

| Repo | Architecture | Domain model | Source code | Infrastructure | UX | Không học thì mất gì? |
|---|---|---|---|---|---|---|
| **ERPNext** | LEARN ONLY | **ADAPT** — chuyển thể invariant (sổ bất biến · đảo bút · derive-không-cộng-dồn · giá vốn theo thời điểm), không bê bảng | ⛔ REJECT (GPL-3.0, cấm cả "dịch sang Dart") | REJECT (server stack, trái D-5) | LEARN ONLY ("status kể nghĩa vụ còn lại") | **Mất nhiều nhất trong 5** — 3 lỗ Inventory/costing chỉ lộ khi soi qua nó; 30 năm domain kế toán không tự nghĩ ra được |
| **Relaticle** | LEARN/ADAPT — luật Tool Runtime tương lai: *mọi write tool compile xuống BusinessAction, không ngoại lệ* | tham khảo nhẹ (CRM B2B lệch domain) | ⛔ REJECT (AGPL-3.0) | SKIP (nghịch Local-First) | LEARN (per-item approve · supersede · re-inject resolved) | Mất **xác nhận bằng phản ví dụ** cho WTM-300 + bộ pattern MCP khi mở Tool Runtime |
| **Trigger.dev** | ⭐ **ADOPT PATTERNS** — state-as-log · fencing thay lock · deadman per-state · cancel-là-trạng-thái · crash-vô-hại | ❌ (không phải domain ta) | ⚠️ MICRO-only — license CHO PHÉP (Apache/MIT), FIT thì không; chỉ nhặt hàm nhỏ nếu có, kèm attribution | ❌ (10 service vs 0 · container-per-run nghịch agent-trên-repo · CRIU cloud-only) | ➖ (không nghiên cứu UI theo spec) | Mất câu trả lời **"không cần tự xây framework"** + 3 cơ chế durability rẻ cho AI-WF |
| **Plane** | LEARN ONLY | LEARN (IntakeIssue triage · 2 tầng history · state-group 2 tầng) | ⛔ REJECT (AGPL-3.0) | REJECT (6 app self-host, NO MIGRATION) | LEARN chọn lọc | Mất ít — pattern triage/history hay nhưng tự nghĩ ra được; giá trị thật là chứng minh **Jira không phải thứ cần thay** |
| **Lago** | LEARN ONLY | **ADAPT vào WAT-16** (5 điểm: granted/purchased · expiry · threshold · meter≠pricing · draft/finalize) | ⛔ REJECT (AGPL-3.0) | REJECT (7 service; và **thiếu escrow** — đúng thứ AI Teams cần) | ➖ | Mất trung bình-thấp — WAT-16 đã tự đến 80% đích; Lago cho 20% chi tiết còn lại |

## Đọc bảng này thế nào

- **Không ô ADOPT nguyên khối nào.** Đó là kết quả, không phải sự rụt rè: cả 5
  repo đều ở tầng khác Workizen (bản đồ ở `12`), và 4/5 license cấm chép.
- Trục **Source code** chỉ có một cửa mở (Trigger.dev) và cửa ấy ta cũng chỉ
  hé — vì FIT, không phải vì license.
- Hai chỗ **Workizen đi trước** cả 5 repo, được xác nhận độc lập: **Provenance**
  (không repo nào có) và **evidence-driven verdict** (Trigger.dev tin task
  code; ta không tin agent report — và đó là lựa chọn đúng cho agent LLM).
