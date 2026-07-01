#!/usr/bin/env bash
#
# bin/ai-session の簡易テスト。
# 一時ディレクトリに .ai/templates を用意し、CLI の挙動を検証する。
# 依存なし(bash のみ)。使い方: test/ai-session.test.sh
#
set -uo pipefail

# --- 対象CLIとテンプレートの場所 -------------------------------------------
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CLI="$REPO_ROOT/bin/ai-session"

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok   - %s\n' "$1"; }
ng()   { FAIL=$((FAIL+1)); printf '  FAIL - %s\n' "$1"; }

# assert_status <expected-exit> <desc> -- <command...>
assert_status() {
  local want="$1" desc="$2"; shift 2; shift # drop the "--"
  "$@" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then ok "$desc"; else ng "$desc (exit $got, want $want)"; fi
}

# --- 隔離した作業ディレクトリを用意 ----------------------------------------
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/.ai/templates/session"
cp "$REPO_ROOT/.ai/templates/session/"*.md "$WORK/.ai/templates/session/"
cd "$WORK" || exit 1

echo "TAP-ish results:"

# 1. start がセッションを作成する
"$CLI" start feat-a >/dev/null 2>&1
if [ -d "$WORK/.ai/sessions/feat-a" ]; then ok "start creates session dir"; else ng "start creates session dir"; fi

# 2. テンプレートの6ファイルがコピーされる
count=$(find "$WORK/.ai/sessions/feat-a" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
if [ "$count" -eq 6 ]; then ok "start copies 6 template files"; else ng "start copies 6 files (got $count)"; fi

# 3. 個々のファイルが存在する
missing=""
for f in requirements questions design tasks test summary; do
  [ -f "$WORK/.ai/sessions/feat-a/$f.md" ] || missing="$missing $f"
done
if [ -z "$missing" ]; then ok "all expected files present"; else ng "missing:$missing"; fi

# 4. list に作成済みセッションが出る
if "$CLI" list 2>/dev/null | grep -q "feat-a"; then ok "list shows created session"; else ng "list shows created session"; fi

# 5. 既存セッションへの再 start は失敗する
assert_status 1 "start on existing session fails" -- "$CLI" start feat-a

# 6. セッション名なしの start は失敗する
assert_status 1 "start without name fails" -- "$CLI" start

# 7. 不正な名前(スラッシュ)は失敗する
assert_status 1 "start rejects name with slash" -- "$CLI" start "a/b"

# 8. 不正な名前(先頭ドット/親参照)は失敗する
assert_status 1 "start rejects dot-leading name" -- "$CLI" start ".."

# 9. help は正常終了する
assert_status 0 "help exits 0" -- "$CLI" help

# 10. 未知のコマンドは失敗する
assert_status 1 "unknown command fails" -- "$CLI" bogus

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
