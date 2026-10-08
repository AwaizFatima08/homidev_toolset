#!/bin/bash
# asset-pull.sh v1.0 (8 Oct 2026) — T1 (pipeline review D1): pull a job that finished on homidev after
# asset-job.sh had already given up (timeout, network drop, ended session). Same pull key, same Stage 1.
# Usage: asset-pull.sh <project> <job-id>
# Last line: RESULT: PASS <folder> | PASS with warnings <folder> | FAIL <reason>
# Exit: 0 pass · 1 Stage 1 failed · 2 job not done / pull failed · 3 receiver unreachable or bad arguments
set -u
H=192.168.100.123; R="${ASSET_RECEIVER:-http://$H:8190}"
TOOLS="$HOME/ai-inbox/_tools"
end() { echo "RESULT: $2"; exit "$1"; }

[ $# -eq 2 ] || { echo "usage: asset-pull.sh <project> <job-id>"; exit 3; }
PROJECT=$1; J=$2
[[ "$J" =~ ^[0-9]{8}-[0-9]{4}-$PROJECT-[a-z]+-[0-9]{2}$ ]] || end 3 "FAIL job-id does not belong to project $PROJECT or is malformed"
TOK=$(cat "$HOME/.config/asset-receiver/token" 2>/dev/null) || end 3 "FAIL token file missing"
HDR="X-Receiver-Token: $TOK"
DEST="$HOME/ai-inbox/$PROJECT/$J"
[ -e "$DEST" ] && end 3 "FAIL $DEST already exists (already pulled?)"
[ -e "$HOME/ai-inbox/_rejected/$J" ] && end 3 "FAIL $J is in _rejected already"

[ "$(curl -s -m 5 -o /dev/null -w '%{http_code}' -H "$HDR" "$R/health")" = 200 ] || end 3 "FAIL receiver unreachable (homidev off or in Windows?)"
ST=$(curl -s -m 10 -H "$HDR" "$R/jobs/$J")
S=$(echo "$ST" | jq -r '.state // "unknown"')
[ "$S" = done ] || end 2 "FAIL job $J state=$S: $(echo "$ST" | jq -r '.error // .detail // "not finished yet"')"
COMM=$(echo "$ST" | jq -r '.manifest.commercial_project // "yes"')

mkdir -p "$DEST" && \
rsync -a -e "ssh -i $HOME/.ssh/homidev_pull -o BatchMode=yes" "homidev@$H:$J/" "$DEST/" || { rmdir "$DEST" 2>/dev/null; end 2 "FAIL pull of $J"; }

OUT=$("$TOOLS/stage1-check.sh" "$DEST" "$COMM"); RC=$?
echo "$OUT"
if [ "$RC" -ne 0 ]; then
  REJ="$HOME/ai-inbox/_rejected/$J"
  [ -e "$REJ" ] && end 1 "FAIL Stage 1 $DEST (not moved: $REJ already exists)"
  mkdir -p "$HOME/ai-inbox/_rejected" && mv "$DEST" "$REJ" && \
  { echo "rejected: $(date -Is) by Stage 1 (stage1-check.sh via asset-pull.sh), commercial project: $COMM"; echo "$OUT" | grep -E '^  FAIL'; } > "$REJ/reason.txt"
  end 1 "FAIL Stage 1 -> moved to $REJ (see reason.txt)"
fi
echo "$OUT" | grep -q '^  WARN' && end 0 "PASS with warnings $DEST"
end 0 "PASS $DEST"
