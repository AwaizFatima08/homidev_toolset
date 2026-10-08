#!/bin/bash
# asset-integrate.sh v1.1 (8 Oct 2026) — step 10d (M1-M8) + step 11 (A1): act on Homi's Stage 2 decision
# v1.1 (A1): assets made under the Stability AI Community Licence (Stable Audio sfx/music) add a one-time
#       "Powered by Stability AI" line to <repo>/assets/ATTRIBUTION.md and print a reminder. Never blocks.
#   asset-integrate.sh approve <job-folder> <repo> <subfolder>   copy into <repo>/assets/<subfolder>/ + ASSET-REGISTER.md row
#   asset-integrate.sh reject  <job-folder> "<reason>"           move job to ~/ai-inbox/_rejected/ + reason.txt
# Only run after Homi decided in chat. Never overwrites, never commits (M8). Exit 0 done, 1 refused.
set -u
S1="$HOME/ai-inbox/_tools/stage1-check.sh"
stop() { echo "REFUSED: $*"; exit 1; }
MODE=${1:-}; JD=${2:-}
[ -n "$MODE" ] && [ -n "$JD" ] || stop "usage: approve <job-folder> <repo> <subfolder> | reject <job-folder> \"<reason>\""
JD=$(realpath -m "$JD"); J=$(basename "$JD")
[ -f "$JD/manifest.json" ] || stop "no job folder with manifest.json: $JD"
M="$JD/manifest.json"

if [ "$MODE" = reject ]; then
  REASON=${3:-}; [ -n "${REASON// /}" ] || stop "a reason is required for reject"
  REJ="$HOME/ai-inbox/_rejected/$J"; [ -e "$REJ" ] && stop "$REJ already exists"
  mkdir -p "$HOME/ai-inbox/_rejected" && mv "$JD" "$REJ" || stop "could not move $JD"
  printf 'rejected: %s by Homi (Stage 2)\nreason: %s\n' "$(date -Is)" "$REASON" > "$REJ/reason.txt"
  echo "REJECTED: $J -> $REJ"; exit 0
fi
[ "$MODE" = approve ] || stop "mode must be approve or reject"

REPO=${3:-}; SUB=${4:-}
[ -n "$REPO" ] && [ -n "$SUB" ] || stop "approve needs <repo> and <subfolder>"
[[ "$SUB" =~ ^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*$ ]] || stop "subfolder must be simple names like icons or audio/voice"
REPO=$(realpath -m "$REPO")
git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || stop "$REPO is not a git repo (M2)"

# M2: Stage 1 again (must not FAIL) + licence matches the request
COMM=$(jq -r '.commercial // "yes"' "$JD/request.json" 2>/dev/null || echo yes)
"$S1" "$JD" "$COMM" >/dev/null 2>&1 || stop "Stage 1 FAIL for $J — run stage1-check.sh to see why"
LIC=$(jq -r .commercial_ok "$M")
[ "$COMM" = yes ] && [ "$LIC" != yes ] && stop "LICENCE GATE: commercial request but commercial_ok = $LIC"

# M3: images -> all image files; voice -> OGG only (WAV master stays in the inbox)
if jq -e '.files[].name|select(endswith(".ogg"))' "$M" >/dev/null; then
  mapfile -t FILES < <(jq -r '.files[].name|select(endswith(".ogg"))' "$M")
else
  mapfile -t FILES < <(jq -r '.files[].name|select(test("\\.(png|jpe?g|webp|svg)$"))' "$M")
fi
[ ${#FILES[@]} -gt 0 ] || stop "no files to integrate in $J"
DEST="$REPO/assets/$SUB"
for f in "${FILES[@]}"; do [ -e "$DEST/$f" ] && stop "$DEST/$f already exists (M4: never overwrite)"; done
DONE="$(dirname "$JD")/_integrated/$J"; [ -e "$DONE" ] && stop "$DONE already exists"

mkdir -p "$DEST" || stop "cannot create $DEST"
REG="$REPO/assets/ASSET-REGISTER.md"
if [ ! -f "$REG" ]; then
  { echo "# Asset register"; echo
    echo "Assets from the homidev pipeline, one row per file. Added by asset-integrate.sh after Homi's approval — do not edit rows by hand."; echo
    echo "| Approved | File | Job ID | Recipe | Models | Licences | commercial_ok | sha256 | Approved by |"
    echo "|---|---|---|---|---|---|---|---|---|"; } > "$REG"
fi
RECIPE="$(jq -r '.recipe + (if .recipe_version then " v" + .recipe_version else "" end)' "$M")"
MODELS=$(jq -r '.model|join(", ")' "$M")
LICS=$(jq -r '[.model_licence[]]|unique|join(", ")' "$M")
for f in "${FILES[@]}"; do
  cp "$JD/$f" "$DEST/$f" || stop "copy failed: $f"   # existence checked above (M4)
  SHA=$(sha256sum "$DEST/$f" | cut -d' ' -f1)
  [ "$SHA" = "$(jq -r --arg f "$f" '.files[]|select(.name==$f)|.sha256' "$M")" ] || stop "fingerprint changed while copying $f"
  echo "| $(date +%F) | \`assets/$SUB/$f\` | $J | $RECIPE | $MODELS | $LICS | $LIC | \`$SHA\` | Homi |" >> "$REG"
  echo "  added assets/$SUB/$f"
done
mkdir -p "$(dirname "$DONE")" && mv "$JD" "$DONE"
# A1 (step 11): Stability AI Community Licence -> attribution record + reminder (never blocks)
if printf '%s' "$LICS" | grep -q "Stability AI Community Licence"; then
  ATT="$REPO/assets/ATTRIBUTION.md"
  [ -f "$ATT" ] || printf '# Attribution\n\nCredits this app must show. Added by asset-integrate.sh — keep in sync with the About screen / store listing.\n\n' > "$ATT"
  if ! grep -q "Powered by Stability AI" "$ATT"; then
    echo "- Sound effects and/or music in this app were made with Stable Audio 3 (Stability AI Community Licence, first added $(date +%F) by job $J). Show **Powered by Stability AI** on the app's About screen or store description." >> "$ATT"
    echo "  added assets/ATTRIBUTION.md line: Powered by Stability AI"
  fi
  echo "REMINDER: this app must show \"Powered by Stability AI\" on its About screen or store description (see assets/ATTRIBUTION.md)."
fi
echo "APPROVED: $J -> $DEST (${#FILES[@]} file(s)); register updated; job moved to $DONE"
echo "Not committed (M8): review with  git -C $REPO status  and commit in the project's normal workflow."
