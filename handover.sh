#!/usr/bin/env bash
# handover.sh — run the Evidence-Driven Autonomous Runtime for the Tổng Tài
# backlog on an always-on host (NUC / server). Lives on feat/tongtai for
# convenience; it drives the sibling `workizen-ai-workforce-runtime` repo.
# Assumes both repos are cloned side by side, e.g. ~/projects/<both>.
#
# USAGE:  ./handover.sh WTM-69 WTM-76 ...     |     ./handover.sh --autonomous 20
#
# SAFE BOUNDARY (hard): never merges/pushes main. Verdict from evidence only.
set -uo pipefail

TARGET_DIR="${TARGET_DIR:-$(cd "$(dirname "$0")" && git rev-parse --show-toplevel)}"
RUNTIME_DIR="${RUNTIME_DIR:-$(dirname "$TARGET_DIR")/workizen-ai-workforce-runtime}"
HUB_BRANCH="${HUB_BRANCH:-main}"
RT_BRANCH="${RT_BRANCH:-feat/evidence-driven-runtime}"
FLUTTER_DIR="${FLUTTER_DIR:-.}"
MAX_RETRIES="${MAX_RETRIES:-1}"
LOG_DIR="${LOG_DIR:-$HOME/.local/state/ai-wf/handover-logs}"; mkdir -p "$LOG_DIR"
MASTER="$LOG_DIR/handover-$(date +%Y%m%d-%H%M%S).log"
log(){ echo "[$(date '+%F %T')] $*" | tee -a "$MASTER"; }
die(){ log "FATAL: $*"; exit 1; }

# ── Single-instance lock ──────────────────────────────────────────────────
#
# Hai vòng autonomous cùng chạy trên một repo sẽ commit chồng lên nhau và
# tranh nhau cùng một nhánh story. Trước đây script này KHÔNG có khoá nào —
# nên câu "single-instance" chỉ là một lời hứa, không phải một cơ chế.
#
# Khoá giữ bằng thư mục: `mkdir` là thao tác nguyên tử trên mọi POSIX, không
# cần `flock` (macOS không có sẵn). Lock ghi kèm PID và mô tả để người sau biết
# ai đang giữ, thay vì chỉ biết là bị chặn.
LOCK_DIR="${LOCK_DIR:-$HOME/.local/state/ai-wf/$(basename "$TARGET_DIR").lock}"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  HOLDER="$(cat "$LOCK_DIR/owner" 2>/dev/null || echo 'không rõ')"
  echo "TỪ CHỐI CHẠY: đã có một vòng autonomous giữ khoá trên repo này."
  echo "  khoá: $LOCK_DIR"
  echo "  chủ:  $HOLDER"
  echo "Nếu chắc chắn vòng kia đã chết: rm -rf \"$LOCK_DIR\""
  exit 3
fi
printf 'pid=%s started=%s script=handover.sh\n' "$$" "$(date '+%F %T')" > "$LOCK_DIR/owner"
trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM

log "=== preflight ==="
command -v node>/dev/null||die "node missing (>=20)"
command -v git>/dev/null||die "git missing"
command -v claude>/dev/null||die "claude CLI missing — run 'claude login' first"
command -v flutter>/dev/null||die "flutter missing (evidence gate runs analyze+test)"
[ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ]||die "Node >=20 required"
[ -d "$RUNTIME_DIR/.git" ]||die "runtime repo not found at $RUNTIME_DIR (clone workizen-ai-workforce-runtime beside the hub repo)"
[ -f "$TARGET_DIR/$FLUTTER_DIR/pubspec.yaml" ]||die "no Flutter app at $TARGET_DIR/$FLUTTER_DIR"

log "=== sync ==="
( cd "$RUNTIME_DIR" && git fetch -q origin && git checkout -q "$RT_BRANCH" && git pull -q --ff-only ) || die "runtime sync failed"
( cd "$TARGET_DIR" && git fetch -q origin && git checkout -q "$HUB_BRANCH" && git pull -q --ff-only ) || die "hub sync failed"
# HUB_BRANCH is only the BASE to branch from (post-split: main). Pre-split this
# script required a checked-out integration branch and refused main here, which
# made it die unconditionally once the split removed that branch (WTM-106).
# Dispatch now happens on a per-story branch created by story_branch() below;
# push_safe keeps refusing main pushes as the second line of defense.
( cd "$RUNTIME_DIR" && npm ci --silent 2>/dev/null || npm install --silent ) || die "npm install failed"

NOSLEEP=(); case "$(uname -s)" in
  Darwin) command -v caffeinate>/dev/null && NOSLEEP=(caffeinate -dimsu);;
  Linux)  command -v systemd-inhibit>/dev/null && NOSLEEP=(systemd-inhibit --what=sleep:idle --why=ai-wf);;
esac
log "sleep-inhibit: ${NOSLEEP[*]:-none}"

export WORKFORCE_REPO="$TARGET_DIR" WORKFORCE_PROJECT=WTM WORKFORCE_SPACE=workizento
export WORKFORCE_FLUTTER_DIR="$FLUTTER_DIR" WORKFORCE_MAX_RETRIES="$MAX_RETRIES"
run_rt(){ ( cd "$RUNTIME_DIR" && "${NOSLEEP[@]}" npx tsx src/index.ts "$@" ); }
push_safe(){ local b; b="$(cd "$TARGET_DIR" && git branch --show-current)"
  { [ "$b" = main ]||[ "$b" = master ]; } && { log "REFUSE push $b"; return; }
  ( cd "$TARGET_DIR" && git push -q origin HEAD ) && log "pushed $b" || log "push skipped"; }
# Agents commit on the CURRENT branch, so give each dispatch its own feature
# branch off the freshly-synced base and never dispatch from main/master
# (WORKING-RULES gate; WTM-106).
story_branch(){ local name="$1"
  ( cd "$TARGET_DIR" && git checkout -q -B "$name" "origin/$HUB_BRANCH" ) || return 1
  local b; b="$(cd "$TARGET_DIR" && git branch --show-current)"
  if [ "$b" = main ] || [ "$b" = master ]; then return 1; fi
  log "working branch: $b (base origin/$HUB_BRANCH)"; }

[ $# -eq 0 ] && { log "usage: $0 WTM-69 WTM-76 ... | $0 --autonomous 20"; exit 2; }
if [ "$1" = --autonomous ]; then
  batch="feat/auto-$(date +%Y%m%d-%H%M%S)"
  story_branch "$batch" || die "cannot create batch branch $batch"
  log "=== AUTONOMOUS max=${2:-25} on $batch ==="; run_rt --autonomous "${2:-25}" 2>&1 | tee -a "$MASTER"; push_safe
else
  log "=== BACKLOG: $* ==="
  for key in "$@"; do
    slug="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')"
    story_branch "feat/${slug}-auto" || { log "SKIP $key: cannot create feat/${slug}-auto"; continue; }
    log "START $key"; run_rt --run-task "$key" "$key" > "$LOG_DIR/$key.log" 2>&1
    v="$(grep -oE 'verdict: (PASS|FAIL|PARTIAL|MANUAL_REVIEW)' "$LOG_DIR/$key.log"|head -1|awk '{print $2}')"
    push_safe; log "DONE $key verdict=${v:-?}"
  done
fi
log "=== complete ==="; run_rt --founder-digest main 2>/dev/null | tee -a "$MASTER" || true
