#!/usr/bin/env bash
# tool/build_release.sh — dựng artefact và ghi lại đúng bản dựng đó (WTM-401).
#
#   tool/build_release.sh apk "smoke-launch trên Nokia"
#   tool/build_release.sh aab "nộp closed beta"
#
# Trình tự: bump → dựng → record (OK hoặc FAILED) → in SHA256 của artefact.
#
# ## ⛔ Dựng hỏng KHÔNG hoàn lại số build
#
# Số đã đốt là một sự kiện đã xảy ra. Hoàn lại nghĩa là bản dựng sau mang một
# số đã từng tồn tại — và nếu bản hỏng lỡ ra khỏi máy thì không ai phân biệt
# được hai artefact nữa. Thủng dãy số vô hại; **dùng lại số là lời nói dối có
# hậu quả**.
#
# ⛔ Script này KHÔNG tag, KHÔNG tạo release, KHÔNG upload. Release · tag ·
# deploy production vẫn Founder-only (CLAUDE.md).
set -uo pipefail
ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

kind="${1:-}"; reason="${2:-}"
case "$kind" in apk|aab) ;; *) echo "dùng: tool/build_release.sh <apk|aab> \"lý do\"" >&2; exit 1;; esac
[ -n "$reason" ] || { echo "cần một lý do — bản dựng không có lý do là bản dựng không ai tra lại được" >&2; exit 1; }

./tool/build_version.sh bump "$reason" || exit 1
ver="$(./tool/build_version.sh current)"
echo "▶ dựng $kind cho $ver"

if [ "$kind" = "apk" ]; then
  flutter build apk --release; rc=$?
  art="build/app/outputs/flutter-apk/app-release.apk"
else
  flutter build appbundle --release; rc=$?
  art="build/app/outputs/bundle/release/app-release.aab"
fi

if [ "$rc" = 0 ] && [ -f "$art" ]; then
  sum="$(shasum -a 256 "$art" | cut -d' ' -f1)"
  size="$(du -h "$art" | cut -f1)"
  ./tool/build_version.sh record OK "$art · $size · SHA256 \`${sum:0:16}…\`"
  echo "✓ $art ($size)"
  echo "  SHA256: $sum"
else
  ./tool/build_version.sh record FAILED "flutter build $kind trả rc=$rc"
  echo "✗ dựng hỏng (rc=$rc). Số build đã đốt và ĐƯỢC GIỮ NGUYÊN trong BUILD-LOG." >&2
  exit "$rc"
fi
