#!/usr/bin/env bash
# Cổng chất lượng chạy TẠI CHỖ — bản sao đúng những gì CI làm.
#
#   ./tool/verify.sh
#
# Vì sao tồn tại: GitHub Actions bị chặn vì thanh toán (2026-08-07), nên mọi PR
# không còn check nào. Repo này có một luật đã học đắt: *thứ gì không có cổng
# cơ học thì không ai phát hiện khi nó hỏng* — bảng Jira đứng im, migration
# hỏng lọt qua 1744 test xanh, và gần nhất là một lần merge khi check đang đỏ
# vì vòng chờ CI thoát ra ở trạng thái "kết thúc" chứ không phải "thành công".
#
# Script này chạy ĐÚNG ba bước CI chạy, theo đúng thứ tự, và trả mã thoát khác 0
# ngay bước đầu tiên hỏng. Không có bước nào bị bỏ qua cho nhanh.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { printf '\n\033[31m✗ %s\033[0m\n' "$*"; exit 1; }
step() { printf '\n\033[1m── %s ──\033[0m\n' "$*"; }

START=$SECONDS

step "1/3  dart format (chỉ KIỂM, không sửa — CI cũng vậy)"
if ! dart format --output=none --set-exit-if-changed lib test; then
  fail "format lệch. Chạy: dart format lib test"
fi
echo "  ✓ đã đúng định dạng"

step "2/3  flutter analyze"
if ! flutter analyze; then
  fail "analyze có lỗi"
fi

step "3/3  flutter test (toàn bộ suite)"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
if ! flutter test --reporter=compact > "$OUT" 2>&1; then
  tail -30 "$OUT"
  fail "test đỏ"
fi
grep -q "All tests passed!" "$OUT" || fail "suite không báo 'All tests passed!'"

# Con số này đi vào Jira/PR làm bằng chứng, nên nó phải đọc được từ đầu ra thật
# chứ không phải do người viết báo cáo nhớ lại.
COUNT="$(grep -oE '\+[0-9]+' "$OUT" | tail -1 | tr -d '+')"

printf '\n\033[32m✓ XANH — %s test, %ds\033[0m\n' "${COUNT:-?}" "$((SECONDS - START))"
printf '  Dán vào PR/Jira: "%s test PASS · analyze sạch · format đúng (verify.sh tại chỗ)"\n' "${COUNT:-?}"
