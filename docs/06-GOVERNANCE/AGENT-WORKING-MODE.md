# Agent Working Mode — Evidence-Driven Runtime

Sản phẩm này được phát triển chủ yếu bởi **AI Workforce Runtime**
(repo `workizen-ai-workforce-runtime`, branch evidence-driven):

```
Jira WTM → Developer agent → EvidenceCollector → Judge → Supervisor → Jira/PR
                (code+test)     (tự chạy analyze     (PASS/FAIL     (transition,
                                 + test + placebo     từ evidence)   không tin lời agent)
                                 scan + git facts)
```

## Luật cốt lõi (đúc từ sự cố thật)

1. **Không tin self-report** — WTM-51 từng "clean build, 7/7 passed" trong khi
   34 lỗi compile + test giả. Chỉ evidence được tính.
2. **Placebo scan**: test không assertion bị reject tự động.
3. **Smart Retry**: FAIL lần 1 → retry với brief sửa lỗi cụ thể từ evidence;
   model tự nâng Opus 4.8 → Fable 5 cho attempt khó.
4. **Timeout kill process-group**: agent treo bị SIGKILL cả cây, batch không idle.
5. **Máy phải thức**: sleep = suspend toàn bộ (chạy dài dùng host always-on).
6. Lỗi hạ tầng (mạng/sqlite3 download) ≠ lỗi code — phân biệt trước khi kết luận.

## Model policy (Founder)

Mặc định **Opus 4.8**; task khó / retry → **Fable 5** (`claude-fable-5`).
Env: `WORKFORCE_MODEL` / `WORKFORCE_HARD_MODEL`.

## Chạy

`./handover.sh WTM-XX [WTM-YY ...]` — preflight, sync, sleep-inhibit,
per-story logs, push-safe (chặn main), founder-digest cuối phiên.
Báo cáo batch: `docs/04-DELIVERY/reports/SPRINT-AUTONOMOUS-*.md` (chuẩn mẫu).
