#!/usr/bin/env bash
# homidev-backup.sh - homi-nas: one-command backup of the homidev toolset into git (step 9f-4, v1.0, 1 Oct 2026)
# Lives in ~/ai-inbox/_tools/. Run at the end of a session:   ~/ai-inbox/_tools/homidev-backup.sh ["commit message"]
#
# 1. git pull (so we never push over newer work)
# 2. copy from homidev (your NORMAL ssh login, not the pull key): receiver, clean-up, voice scripts,
#    models.json, MODEL-REGISTER.md, recipes, audit script, the 3 systemd files
# 3. copy homi-nas files: ~/ai-inbox/_tools/*.sh and ~/.claude/homidev.md
# 4. safety checks: no token, no private key, no big files (models)  -> otherwise STOP
# 5. show what changed, ask y/N, then commit + push
# docs/ is NOT copied by this script: put updated docs into ~/homidev_toolset/docs/ yourself first.
# Google Drive stays a separate step (done by Claude at session close).
set -u
REPO="$HOME/homidev_toolset"
HD="homidev@192.168.100.123"
TOKEN_FILE="$HOME/.config/asset-receiver/token"
MAX_KB=1024     # nothing in this repo should be bigger than 1 MB
SOCK="$HOME/.ssh/cm-%C"
SSH=(ssh -o ControlMaster=auto -o ControlPath="$SOCK" -o ControlPersist=60)

stop() { echo "STOPPED: $*"; exit 1; }
cd "$REPO" 2>/dev/null || stop "$REPO not found"
[ -d .git ] || stop "$REPO is not a git repository"

echo "== 1. git pull"
git pull --ff-only || stop "git pull failed - sort that out first (nothing was copied)"

echo "== 2. copy from homidev (you may be asked for homidev's password once)"
out=$("${SSH[@]}" -n "$HD" 'echo login-ok' 2>&1)
[ "$out" = "login-ok" ] || stop "normal ssh login to homidev did not work (got: $out). If it mentions rrsync, ssh is using the read-only pull key."
RS=(rsync -a --relative -e "${SSH[*]}" --exclude='__pycache__/' --exclude='*.pyc' --exclude='venv/' --exclude='*token*')
mkdir -p homidev/systemd
"${RS[@]}" "$HD:./receiver/receiver.py" "$HD:./receiver/cleanup-jobs.sh" \
           "$HD:./voice/say.py" "$HD:./voice/check.py" \
           "$HD:./assets/models.json" "$HD:./assets/MODEL-REGISTER.md" \
           "$HD:./homidev-audit.sh" homidev/ || stop "copy from homidev failed"
rsync -a --delete -e "${SSH[*]}" --exclude='__pycache__/' "$HD:assets/recipes/" homidev/assets/recipes/ \
  || stop "copy of recipes failed"
rsync -a -e "${SSH[*]}" "$HD:/etc/systemd/system/asset-receiver.service" \
      "$HD:/etc/systemd/system/asset-cleanup.service" "$HD:/etc/systemd/system/asset-cleanup.timer" \
      "$HD:/etc/systemd/system/comfyui.service" homidev/systemd/ || stop "copy of systemd files failed"
"${SSH[@]}" -O exit "$HD" 2>/dev/null

echo "== 3. copy homi-nas files"
mkdir -p homi-nas/ai-inbox/_tools homi-nas/claude
cp -p "$HOME"/ai-inbox/_tools/*.sh homi-nas/ai-inbox/_tools/ || stop "copy of _tools failed"
cp -p "$HOME/.claude/homidev.md" homi-nas/claude/homidev.md || stop "copy of homidev.md failed"

echo "== 4. safety checks"
git add -A
staged=$(git diff --cached --name-only)
if [ -z "$staged" ]; then echo "Nothing changed since the last backup. Done."; exit 0; fi
problem=""
if [ -s "$TOKEN_FILE" ] && git grep --cached -l -F "$(cat "$TOKEN_FILE")" >/dev/null 2>&1; then
  problem="the receiver TOKEN is inside: $(git grep --cached -l -F "$(cat "$TOKEN_FILE")" | tr '\n' ' ')"
fi
KEYPAT='-----BEGIN [A-Z ]*PRIVATE KEY'   # written so this script does not match itself
if git grep --cached -l -E -e "$KEYPAT" >/dev/null 2>&1; then
  problem="$problem a private key is inside: $(git grep --cached -l -E -e "$KEYPAT" | tr '\n' ' ')"
fi
while IFS= read -r f; do
  [ -f "$f" ] || continue
  kb=$(( $(stat -c %s "$f") / 1024 ))
  [ "$kb" -gt "$MAX_KB" ] && problem="$problem $f is ${kb} KB (too big - model file?)"
done <<< "$staged"
if [ -n "$problem" ]; then
  git reset -q
  stop "$problem -- nothing committed. Fix it, then run again."
fi
echo "   PASS  no token, no private key, nothing over ${MAX_KB} KB"

echo "== 5. changes"
git status --short
read -r -p "Commit and push these changes? [y/N] " ok
if [ "$ok" != "y" ] && [ "$ok" != "Y" ]; then
  git reset -q; echo "Not committed (files are copied, nothing staged)."; exit 0
fi
msg="${1:-backup $(date '+%Y-%m-%d %H:%M')}"
git commit -q -m "$msg" || stop "git commit failed"
git push || stop "git push failed (commit is saved locally - run 'git push' later)"
echo "DONE: $(git log -1 --format='%h  %s')"
