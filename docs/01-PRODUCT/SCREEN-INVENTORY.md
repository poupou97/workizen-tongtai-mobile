# Screen Inventory

Spec chi tiết từng màn ở [screens/](screens/) (mỗi file: purpose, IA,
components, mock data, business rules, AI capabilities, API sketch, states,
responsive, a11y). Trạng thái build = code thật trong `lib/features/tongtai/ui/`.

> **Level thật của từng màn: [`../02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`]
> (../02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md)** — ma trận đó được cập nhật
> cùng mỗi PR, bảng dưới đây thì không. Khi hai bên lệch nhau, **ma trận đúng**.
>
> ⚠️ Bảng này từng ghi Finance và Reports là *"chưa"* trong khi cả hai đã ở
> **L4** — đủ để dẫn sai bất kỳ ai (kể cả agent) đọc nó để biết trạng thái.
> Sửa 2026-08-01 (WTM-183).

## Ký hiệu Future Capability

**Future Capability** = năng lực có trong Concept, **giữ nguyên trong Concept**,
nhưng **chưa xây được vì phụ thuộc dữ liệu ngoài thiết bị**.

Founder Decision 2026-08-01: *"Không sửa Concept. Không rút capability khỏi
Concept. Đánh dấu các capability phụ thuộc dữ liệu ngoài là Future Capability."*

| Ký hiệu | Nghĩa |
|---|---|
| ✅ | đã xây, dùng được |
| 🟡 | xây một phần |
| ❌ | chưa xây, **không** bị chặn bởi dữ liệu ngoài |
| **🔮 Future** | **bị chặn bởi dữ liệu ngoài** — điều kiện mở khoá ghi kèm |

**Điều kiện mở khoá chung cho phần lớn 🔮 hiện nay: File Bridge (WTM-181)** —
đọc file người bán tự xuất từ sàn (ADR-TON-020).

### Future Capability đang có

| Capability | Concept | Chặn bởi |
|---|---|---|
| Producer — Research | sc-7 | dữ liệu thị trường ngoài |
| Producer — Trend (thị trường) | sc-7 | dữ liệu thị trường ngoài |
| Producer — Arbitrage | sc-7 | giá từ ≥2 sàn |
| Producer — Cross-border | sc-7 | giá nước ngoài |
| Producer — Discovery | sc-7 | danh mục nhà cung cấp ngoài |
| Opportunity — `arbitrage` | sc-13 | giá từ ≥2 sàn — **Domain giữ, ẩn hiển thị** (WTM-182) |
| Opportunity — `crossBorder` | sc-13 | giá nước ngoài — **Domain giữ, ẩn hiển thị** (WTM-182) |
| Finance — lãi thật sau phí sàn | sc-10 | dữ liệu phí sàn |
| Consumer — omnichannel | sc-9 | đơn hàng từ sàn |

**Không có mục nào ở trên bị rút khỏi Concept.** Chúng là *chưa*, không phải
*không*.

| Màn | Spec | Đã build? |
|---|---|---|
| Home (dashboard shell) | screens/SCREEN-HOME.md | ✅ shell (WTM-55) |
| Producer (sourcing hub) | screens/SCREEN-PRODUCER.md | ✅ shell + search/detail/favorites (63/64/65) |
| Inventory | screens/SCREEN-INVENTORY.md | ✅ list + form + stock alerts (68/69/70) |
| Consumer (CRM) | screens/SCREEN-CONSUMER.md | ✅ customer list (75) + add/edit form (76) + purchase history (77) |
| More / menu | screens/SCREEN-MORE.md | ✅ shell + replay tutorial (59) |
| Unified Search | (WTM-73 spec trong Jira) | ✅ (73/74) |
| AI key (BYOK) | (WTM-61) | ✅ |
| Onboarding | (WTM-59 → **thay bằng hội thoại WTM-178**) | ✅ hội thoại 4 câu hỏi; 6 slide cũ đã **xoá** |
| Component showcase | (WTM-62) | ✅ |
| Finance | screens/SCREEN-FINANCE.md | ✅ **L4** (WTM-120 + Capability Context) |
| Reports | screens/SCREEN-REPORTS.md | ✅ **L4** (WTM-127) |
| Business Journey | screens/SCREEN-BUSINESS-JOURNEY.md | 🟡 goals list + multi-step goal form + progress/pace (87); step-plan AI chờ WTM-88 |
| Opportunity Hub | screens/SCREEN-OPPORTUNITY-HUB.md | 🟡 feed: filter/sort/save/swipe (91); detail + AI scoring chờ WTM-92/93 |
| AI Copilot chat | screens/SCREEN-AI-COPILOT.md | ✅ chat UI (80) + persistence (81) + Workizen AI Router (82) |
| Detail: producer/inventory/consumer | screens/SCREEN-*-DETAIL.md | ✅ supplier detail; ❌ inventory/consumer detail |

Luồng điều hướng: [screens/SCREEN-FLOW.md](screens/SCREEN-FLOW.md) ·
[../02-ARCHITECTURE/NAVIGATION-MAP.md](../02-ARCHITECTURE/NAVIGATION-MAP.md).
