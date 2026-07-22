# Screen Inventory

Spec chi tiết từng màn ở [screens/](screens/) (mỗi file: purpose, IA,
components, mock data, business rules, AI capabilities, API sketch, states,
responsive, a11y). Trạng thái build = code thật trong `lib/features/tongtai/ui/`.

| Màn | Spec | Đã build? |
|---|---|---|
| Home (dashboard shell) | screens/SCREEN-HOME.md | ✅ shell (WTM-55) |
| Producer (sourcing hub) | screens/SCREEN-PRODUCER.md | ✅ shell + search/detail/favorites (63/64/65) |
| Inventory | screens/SCREEN-INVENTORY.md | ✅ list + form + stock alerts (68/69/70) |
| Consumer (CRM) | screens/SCREEN-CONSUMER.md | ✅ customer list (75) |
| More / menu | screens/SCREEN-MORE.md | ✅ shell + replay tutorial (59) |
| Unified Search | (WTM-73 spec trong Jira) | ✅ (73/74) |
| AI key (BYOK) | (WTM-61) | ✅ |
| Onboarding 6 màn | (WTM-59) | ✅ |
| Component showcase | (WTM-62) | ✅ |
| Finance | screens/SCREEN-FINANCE.md | ❌ chưa |
| Reports | screens/SCREEN-REPORTS.md | ❌ chưa |
| Business Journey | screens/SCREEN-BUSINESS-JOURNEY.md | ❌ chưa |
| Opportunity Hub | screens/SCREEN-OPPORTUNITY-HUB.md | ❌ chưa |
| AI Copilot chat | screens/SCREEN-AI-COPILOT.md | ❌ chưa (client có) |
| Detail: producer/inventory/consumer | screens/SCREEN-*-DETAIL.md | ✅ supplier detail; ❌ inventory/consumer detail |

Luồng điều hướng: [screens/SCREEN-FLOW.md](screens/SCREEN-FLOW.md) ·
[../02-ARCHITECTURE/NAVIGATION-MAP.md](../02-ARCHITECTURE/NAVIGATION-MAP.md).
