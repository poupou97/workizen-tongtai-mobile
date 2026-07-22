# Architecture Overview

Một app Flutter **local-first, không backend**:

```
┌──────────────── Tổng Tài (Flutter, com.workizen.tongtai) ────────────────┐
│  UI (screens/shell)  →  Controllers/Services  →  Storage                 │
│        │                        │                  ├─ SQLite/Drift (17 bảng, FTS5)
│        │ Riverpod DI            │                  ├─ flutter_secure_storage (BYOK keys, UUID)
│        │                        │                  └─ SharedPreferences (UI state)
│        └── AI Copilot ── tongtai_ai_client ──► xAI Grok API (direct, BYOK)
└──────────────────────────────────────────────────────────────────────────┘
```

- **Không có server của Workizen** trong đường đi dữ liệu. Duy nhất network
  call: device → AI provider (key của user).
- **Offline-first**: mọi tính năng chạy không mạng (trừ gọi AI); sync-queue
  outbox (WTM-54) chuẩn bị cho cloud sync opt-in Phase 3+.
- Chi tiết thật: [CURRENT-STATE-ARCHITECTURE.md](CURRENT-STATE-ARCHITECTURE.md) ·
  Domain: [DOMAIN-MODEL.md](DOMAIN-MODEL.md) ·
  Capabilities: [CAPABILITY-MAP.md](CAPABILITY-MAP.md) ·
  AI: [AI-CAPABILITY-MATRIX.md](AI-CAPABILITY-MATRIX.md) ·
  Security: [SECURITY-BOUNDARIES.md](SECURITY-BOUNDARIES.md)
