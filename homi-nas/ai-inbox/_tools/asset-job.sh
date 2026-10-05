#!/bin/bash
# asset-job.sh v1.1 (5 Oct 2026) — step 10b: Stage 1 FAIL -> job moved to ~/ai-inbox/_rejected/<job>/ + reason.txt
# v1.0 (5 Oct 2026) — step 10a: request one asset from homidev
# Usage: asset-job.sh <project> <recipe> <commercial: yes|no> <inputs.json>
# submit -> wait -> pull (read-only key) -> stage1-check.sh. Last line: RESULT: PASS <folder> | RESULT: FAIL <reason>
# Exit: 0 pass · 1 Stage 1 failed · 2 job failed on homidev / pull failed · 3 refused or receiver unreachable
set -u
H=192.168.100.123; R="${ASSET_RECEIVER:-http://$H:8190}"
TOOLS="$HOME/ai-inbox/_tools"
end() { echo "RESULT: $2"; exit "$1"; }

[ $# -eq 4 ] || { echo "usage: asset-job.sh <project> <recipe> <yes|no> <inputs.json>"; exit 3; }
PROJECT=$1; RECIPE=$2; COMM=$3; INPUTS=$4
[ "$COMM" = yes ] || [ "$COMM" = no ] || end 3 "FAIL commercial must be yes or no"
jq -e 'type=="object"' "$INPUTS" >/dev/null 2>&1 || end 3 "FAIL $INPUTS is not a JSON object"
TOK=$(cat "$HOME/.config/asset-receiver/token" 2>/dev/null) || end 3 "FAIL token file missing"
HDR="X-Receiver-Token: $TOK"

# F2: health, retry every 15 s for up to 3 min (homidev may be booting)
for i in $(seq 1 13); do
  [ "$(curl -s -m 5 -o /dev/null -w '%{http_code}' -H "$HDR" "$R/health")" = 200 ] && break
  [ "$i" -eq 13 ] && end 3 "FAIL receiver unreachable after 3 min (homidev off or in Windows?)"
  echo "  receiver not ready, retry in 15 s ($i/12)"; sleep 15
done
TYPE=$(curl -s -m 10 -H "$HDR" "$R/recipes" | jq -r --arg r "$RECIPE" '.recipes[]|select(.name==$r)|.asset_type')
[ -n "$TYPE" ] || end 3 "FAIL recipe '$RECIPE' unknown or not approved"

# F3: job ID = date-time-project-type-NN, next free NN
STAMP=$(date +%Y%m%d-%H%M); BODY=$(mktemp); trap 'rm -f "$BODY"' EXIT
for n in $(seq -w 1 99); do
  J="$STAMP-$PROJECT-$TYPE-$n"
  CODE=$(jq -n --arg j "$J" --arg p "$PROJECT" --arg c "$COMM" --arg t "$TYPE" --arg r "$RECIPE" \
            --arg by "${ASSET_REQUESTED_BY:-claude-code}" --slurpfile in "$INPUTS" \
           '{job_id:$j,project:$p,commercial:$c,requested_by:$by,asset_type:$t,recipe:$r,inputs:$in[0]}' | \
         curl -s -m 30 -o "$BODY" -w '%{http_code}' -H "$HDR" -H 'Content-Type: application/json' "$R/jobs" -d @-)
  [ "$CODE" = 409 ] && continue
  [ "$CODE" = 200 ] && break
  end 3 "FAIL refused ($CODE): $(jq -r '.detail // .' "$BODY" 2>/dev/null | tr '\n' ' ')"
done
[ "$CODE" = 200 ] || end 3 "FAIL no free job number this minute"
echo "submitted $J (commercial_ok: $(jq -r .commercial_ok "$BODY"))"

# F4: wait up to 10 min
for _ in $(seq 1 120); do
  S=$(curl -s -m 10 -H "$HDR" "$R/jobs/$J" | jq -r '.state // "unknown"')
  [ "$S" = "done" ] || [ "$S" = failed ] && break
  sleep 5
done
[ "$S" = "done" ] || end 2 "FAIL job $J state=$S: $(curl -s -m 10 -H "$HDR" "$R/jobs/$J" | jq -r '.error // "timeout after 10 min"')"

DEST="$HOME/ai-inbox/$PROJECT/$J"
mkdir -p "$DEST" && \
rsync -a -e "ssh -i $HOME/.ssh/homidev_pull -o BatchMode=yes" "homidev@$H:$J/" "$DEST/" || end 2 "FAIL pull of $J"

OUT=$("$TOOLS/stage1-check.sh" "$DEST" "$COMM"); RC=$?
echo "$OUT"
if [ "$RC" -ne 0 ]; then
  REJ="$HOME/ai-inbox/_rejected/$J"
  [ -e "$REJ" ] && end 1 "FAIL Stage 1 $DEST (not moved: $REJ already exists)"
  mkdir -p "$HOME/ai-inbox/_rejected" && mv "$DEST" "$REJ" && \
  { echo "rejected: $(date -Is) by Stage 1 (stage1-check.sh), commercial project: $COMM"; echo "$OUT" | grep -E '^  FAIL'; } > "$REJ/reason.txt"
  end 1 "FAIL Stage 1 -> moved to $REJ (see reason.txt)"
fi
echo "$OUT" | grep -q '^  WARN' && end 0 "PASS with warnings $DEST"
end 0 "PASS $DEST"
