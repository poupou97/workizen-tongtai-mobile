#!/usr/bin/env bash
# tool/build_version.sh — nâng số build và ghi lại bản dựng đó có gì (WTM-401).
#
# ## Vì sao tồn tại
#
# Trước file này, `pubspec.yaml` nói `0.1.0+11` và **không ai trả lời được** câu
# *"bản vc11 trên máy Founder có gì mà vc10 không có"*. Một số build không kèm
# lịch sử là một cái nhãn, không phải một thông tin.
#
# ## ⛔ Dựng HỎNG vẫn giữ số build, và ghi FAILED
#
# Cách dễ là hoàn lại số build khi dựng hỏng để dãy số không thủng. **Không.**
# Một `versionCode` đã bị đốt là một sự kiện **đã xảy ra**; dùng lại nó nghĩa là
# hai artefact khác nhau mang cùng một số, và nếu bản hỏng lỡ ra khỏi máy thì
# không ai phân biệt được nữa. Thủng dãy số vô hại (Play chỉ đòi tăng dần);
# **dùng lại số là một lời nói dối có hậu quả.**
#
# Dùng:
#   tool/build_version.sh current          # in version đang có
#   tool/build_version.sh bump "lý do"     # tăng +N và mở một mục BUILD-LOG
#   tool/build_version.sh record <trạng thái> [ghi chú]   # đóng mục vừa mở
#   tool/build_version.sh check            # cổng: số build phải tăng nghiêm ngặt
set -uo pipefail
ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
PUBSPEC="$ROOT/pubspec.yaml"
LOG="$ROOT/docs/04-DELIVERY/BUILD-LOG.md"

die(){ printf '\033[31m⛔ %s\033[0m\n' "$*" >&2; exit 1; }
say(){ printf '\033[1m%s\033[0m\n' "$*"; }

version_line(){ grep -m1 '^version:' "$PUBSPEC" | sed 's/^version:[[:space:]]*//'; }
name_of(){ version_line | cut -d+ -f1; }
build_of(){ version_line | cut -d+ -f2; }

# Số build cao nhất đã ghi trong log (0 nếu log chưa có).
logged_max(){
  [ -f "$LOG" ] || { echo 0; return; }
  grep -oE '^## build \+([0-9]+)' "$LOG" | grep -oE '[0-9]+' | sort -n | tail -1 || echo 0
}

case "${1:-}" in

current)
  echo "$(version_line)  (name=$(name_of) build=$(build_of))"
  ;;

bump)
  reason="${2:-}"
  [ -n "$reason" ] || die "bump cần một lý do: tool/build_version.sh bump \"dựng thử trên Nokia\""
  cur="$(build_of)"; next=$((cur + 1))
  prev_sha="$(grep -oE '^- SHA: `[0-9a-f]+`' "$LOG" 2>/dev/null | head -1 | grep -oE '[0-9a-f]{7,}' || true)"

  # Các commit kể từ bản dựng trước. Không có mốc trước ⇒ khai thẳng là không
  # có dữ liệu, KHÔNG bịa hồi tố một lịch sử mình không đo được.
  if [ -n "$prev_sha" ] && git -C "$ROOT" cat-file -e "$prev_sha" 2>/dev/null; then
    changes="$(git -C "$ROOT" log --oneline --no-merges "$prev_sha"..HEAD 2>/dev/null)"
    range="kể từ \`$prev_sha\`"
  else
    changes=""
    range="**không có mốc dựng trước để so** — bản dựng đầu tiên được ghi lại"
  fi

  sed -i '' "s/^version: .*/version: $(name_of)+$next/" "$PUBSPEC" \
    || die "không sửa được pubspec.yaml"

  mkdir -p "$(dirname "$LOG")"
  [ -f "$LOG" ] || cat > "$LOG" <<'HEADER'
# BUILD LOG — Tổng Tài

Một mục cho **mỗi bản dựng đã thực sự xảy ra**, mới nhất ở trên.

> ⚠️ Các bản trước `+11` **không có dữ liệu** — chúng được dựng trước khi có file
> này. Không bịa hồi tố: một mục trống trung thực hơn một mục dựng lại từ trí nhớ.

HEADER

  tmp="$(mktemp)"
  {
    head -n "$(grep -n '^$' "$LOG" | head -1 | cut -d: -f1)" "$LOG" 2>/dev/null || cat "$LOG"
  } > /dev/null 2>&1 || true

  entry="$(mktemp)"
  {
    echo "## build +$next — $(date -u +%FT%TZ)"
    echo
    echo "- Version: \`$(name_of)+$next\` (trước: \`$(name_of)+$cur\`)"
    echo "- Lý do: $reason"
    echo "- SHA: \`$(git -C "$ROOT" rev-parse HEAD)\`"
    echo "- Nhánh: \`$(git -C "$ROOT" branch --show-current)\`"
    echo "- Trạng thái: ⏳ ĐANG DỰNG (chưa đóng bằng \`record\`)"
    echo
    echo "### Thay đổi $range"
    echo
    if [ -n "$changes" ]; then
      printf '%s\n' "$changes" | sed 's/^/- /'
    else
      echo "- _không có dữ liệu_"
    fi
    echo
  } > "$entry"

  # Chèn ngay sau phần đầu (dòng trống đầu tiên sau khối chú thích).
  awk -v f="$entry" '
    BEGIN { ins=0 }
    /^## build \+/ && !ins { while ((getline l < f) > 0) print l; ins=1 }
    { print }
    END { if (!ins) { while ((getline l < f) > 0) print l } }
  ' "$LOG" > "$tmp" && mv "$tmp" "$LOG"
  rm -f "$entry"

  say "✓ build +$cur → +$next · đã mở mục trong $(basename "$LOG")"
  ;;

record)
  status="${2:-}"; note="${3:-}"
  [ -n "$status" ] || die "record cần trạng thái: OK | FAILED"
  cur="$(build_of)"
  grep -q "^## build +$cur " "$LOG" || die "không thấy mục cho build +$cur — chạy \`bump\` trước"
  case "$status" in
    OK)     mark="✅ THÀNH CÔNG" ;;
    FAILED) mark="❌ HỎNG — số build này ĐÃ BỊ ĐỐT, không dùng lại" ;;
    *)      mark="$status" ;;
  esac
  tmp="$(mktemp)"
  awk -v b="$cur" -v m="$mark" -v n="$note" '
    $0 ~ "^## build \\+" b " " { inentry=1 }
    inentry && /^- Trạng thái: / { print "- Trạng thái: " m (n=="" ? "" : " — " n); inentry=0; next }
    { print }
  ' "$LOG" > "$tmp" && mv "$tmp" "$LOG"
  say "✓ build +$cur → $mark"
  ;;

check)
  fail=0
  cur="$(build_of)"; maxlog="$(logged_max)"
  echo "pubspec: +$cur · log cao nhất: +$maxlog"

  [[ "$cur" =~ ^[0-9]+$ ]] || { echo "  ✗ số build không phải số nguyên: '$cur'"; fail=1; }

  # ⭐ Cửa 1 — pubspec không được THẤP HƠN log. Thấp hơn nghĩa là ai đó đã hạ
  # số build, và bản dựng sau sẽ mang một số đã dùng rồi.
  if [ "$cur" -lt "$maxlog" ]; then
    echo "  ✗ pubspec (+$cur) THẤP HƠN log (+$maxlog) — bản dựng sau sẽ trùng số đã dùng"
    fail=1
  else
    echo "  ✓ pubspec không thấp hơn log"
  fi

  # ⭐ Cửa 2 — mỗi số build chỉ được xuất hiện MỘT lần. Trùng nghĩa là hai
  # artefact khác nhau mang cùng một số, và không ai phân biệt được nữa.
  if [ -f "$LOG" ]; then
    dup="$(grep -oE '^## build \+[0-9]+' "$LOG" | sort | uniq -d)"
    if [ -n "$dup" ]; then
      echo "  ✗ số build TRÙNG trong log: $dup"; fail=1
    else
      echo "  ✓ không số build nào trùng"
    fi
    # ⭐ Cửa 3 — thứ tự trong log phải giảm dần (mới nhất trên cùng).
    nums="$(grep -oE '^## build \+[0-9]+' "$LOG" | grep -oE '[0-9]+')"
    if [ -n "$nums" ] && [ "$(printf '%s\n' "$nums")" != "$(printf '%s\n' "$nums" | sort -rn)" ]; then
      echo "  ✗ log không theo thứ tự giảm dần — mục mới phải ở trên"; fail=1
    else
      echo "  ✓ log theo thứ tự giảm dần"
    fi
  fi

  [ "$fail" = 0 ] && say "✓ BUILD VERSION OK" || die "BUILD VERSION KHÔNG ĐẠT"
  ;;

*)
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
  ;;
esac
