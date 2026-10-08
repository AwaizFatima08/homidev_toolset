#!/bin/bash
# review-sheet.sh v1.1 (8 Oct 2026) — step 10c: one self-contained HTML review page per batch (L1-L7)
# v1.1 (step 11, A3): music players loop (hear the join); music cards show BPM + loop length.
# Usage: review-sheet.sh <project> [job-folder ...]   (no folders = every job waiting in ~/ai-inbox/<project>/)
# Claude's visual note per job: ~/ai-inbox/<project>/_notes/<job-id>.txt (optional)
# View only: Homi decides in chat ("approve 1, 3; reject 2: reason"). Re-runs stage1-check.sh (pure checker).
set -u
[ $# -ge 1 ] || { echo "usage: review-sheet.sh <project> [job-folder ...]"; exit 2; }
PROJECT=$1; shift
BASE="$HOME/ai-inbox/$PROJECT"; S1="$HOME/ai-inbox/_tools/stage1-check.sh"
if [ $# -gt 0 ]; then JOBS=("$@"); else mapfile -t JOBS < <(find "$BASE" -mindepth 2 -maxdepth 2 -name manifest.json -printf '%h\n' 2>/dev/null | sort); fi
[ ${#JOBS[@]} -gt 0 ] || { echo "no jobs found for project $PROJECT"; exit 1; }
mkdir -p "$BASE"; OUT="$BASE/review-$(date +%Y%m%d-%H%M).html"
esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

{
cat <<'HEAD'
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Asset review</title><style>
:root{--bg:#f6f7f9;--card:#fff;--ink:#1d2330;--muted:#5b6475;--line:#dde1e8;--pass:#1f7a3a;--warn:#9a6300;--fail:#b3261e;--chip:#eef1f5}
@media (prefers-color-scheme:dark){:root{--bg:#14171c;--card:#1d2128;--ink:#e8ebf0;--muted:#9aa3b2;--line:#2e343e;--pass:#5cc27a;--warn:#e0a83a;--fail:#ff7a70;--chip:#262b33}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:980px;margin:0 auto;padding:20px 16px 60px}h1{font-size:22px;margin:0 0 4px}.sub{color:var(--muted);margin:0 0 20px}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;margin:0 0 18px;display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.2fr);gap:18px}
@media (max-width:720px){.card{grid-template-columns:1fr}}
.num{font-size:28px;font-weight:700;margin-right:8px}.media img{width:100%;height:auto;border-radius:8px;border:1px solid var(--line);background:repeating-conic-gradient(#ccc 0 25%,#fff 0 50%) 0 0/16px 16px}
audio{width:100%}.k{color:var(--muted);font-size:13px;margin:10px 0 2px}.v{margin:0;word-break:break-word}
.chip{display:inline-block;background:var(--chip);border-radius:999px;padding:2px 10px;font-size:13px;margin:2px 4px 2px 0}
.res{font-weight:700;margin-top:6px}.pass{color:var(--pass)}.warn{color:var(--warn)}.fail{color:var(--fail)}
.lines{font:13px/1.45 ui-monospace,Menlo,monospace;margin:4px 0 0;padding:0;list-style:none}
.note{border-left:3px solid var(--line);padding:4px 10px;margin:4px 0 0;white-space:pre-wrap}
footer{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px}
</style></head><body><main>
HEAD
echo "<h1>Asset review — $(printf '%s' "$PROJECT" | esc)</h1>"
echo "<p class=\"sub\">${#JOBS[@]} job(s) · made $(date '+%d %b %Y, %H:%M') on homi-nas · review-sheet.sh v1.1</p>"
n=0
for D in "${JOBS[@]}"; do
  n=$((n+1)); M="$D/manifest.json"; J=$(basename "$D")
  [ -f "$M" ] || { echo "<section class=\"card\"><div><span class=\"num\">#$n</span>$(printf '%s' "$J" | esc)</div><div class=\"fail\">manifest.json missing</div></section>"; continue; }
  COMM=$(jq -r '.commercial // "yes"' "$D/request.json" 2>/dev/null || echo yes)
  S1OUT=$("$S1" "$D" "$COMM" 2>&1)
  RES=$(printf '%s\n' "$S1OUT" | grep '^RESULT' | tail -n1)
  case "$RES" in *FAIL*) RC=fail;; *warning*) RC=warn;; *) RC=pass;; esac
  LOOP=""; [ "$(jq -r .asset_type "$M")" = music ] && LOOP=" loop"
  echo "<section class=\"card\"><div class=\"media\">"
  # pictures, then audio (OGG preferred; WAV only if there is no OGG)
  for f in $(jq -r '.files[].name' "$M"); do
    case "$f" in
      *.png) echo "<img alt=\"$f\" src=\"data:image/png;base64,$(base64 -w0 "$D/$f")\">";;
      *.jpg|*.jpeg) echo "<img alt=\"$f\" src=\"data:image/jpeg;base64,$(base64 -w0 "$D/$f")\">";;
      *.ogg) echo "<audio controls$LOOP preload=\"metadata\" src=\"data:audio/ogg;base64,$(base64 -w0 "$D/$f")\"></audio>";;
      *.wav) jq -e '.files[].name|select(endswith(".ogg"))' "$M" >/dev/null || echo "<audio controls src=\"data:audio/wav;base64,$(base64 -w0 "$D/$f")\"></audio>";;
    esac
  done
  echo "</div><div>"
  echo "<div><span class=\"num\">#$n</span><span class=\"chip\">$(jq -r .asset_type "$M" | esc)</span><span class=\"chip\">$(jq -r .recipe "$M" | esc)</span><span class=\"chip\">commercial_ok: $(jq -r .commercial_ok "$M" | esc)</span>$(jq -r 'if .postprocess.type == "music" then "<span class=\"chip\">\(.postprocess.bpm) BPM · \(.postprocess.bars) bars · \(.postprocess.loop_sec) s loop (plays on repeat)</span>" else "" end' "$M")</div>"
  echo "<p class=\"k\">Job</p><p class=\"v\">$(printf '%s' "$J" | esc)</p>"
  TXT=$(jq -r '.prompt // .script // empty' "$M")
  [ -n "$TXT" ] && echo "<p class=\"k\">$(jq -r 'if .script then "Script" else "Prompt" end' "$M")</p><p class=\"v\">$(printf '%s' "$TXT" | esc)</p>"
  SEED=$(jq -r '.seed // empty' "$M"); [ -n "$SEED" ] && echo "<p class=\"k\">Seed</p><p class=\"v\">$SEED</p>"
  echo "<p class=\"k\">Models and licences</p><p class=\"v\">$(jq -r '.model_licence|to_entries|map("\(.key): \(.value)")|join(" · ")' "$M" | esc)</p>"
  echo "<p class=\"k\">Stage 1</p><p class=\"res $RC\">$(printf '%s' "${RES#RESULT: }" | esc)</p>"
  LINES=$(printf '%s\n' "$S1OUT" | grep -E '^  (WARN|FAIL)')
  if [ -n "$LINES" ]; then
    echo "<ul class=\"lines\">"
    while IFS= read -r l; do c=warn; [[ "$l" == "  FAIL"* ]] && c=fail; echo "<li class=\"$c\">$(printf '%s' "${l#  }" | esc)</li>"; done <<<"$LINES"
    echo "</ul>"
  fi
  NOTE="$(dirname "$D")/_notes/$J.txt"   # outside the job folder, so Stage 1 sees no unlisted file
  if [ -s "$NOTE" ]; then echo "<p class=\"k\">Claude's note</p><p class=\"note\">$(esc < "$NOTE")</p>"; fi
  echo "</div></section>"
done
cat <<'FOOT'
<footer><strong>How to decide:</strong> reply in the chat with Claude, e.g. <em>"approve 1, 3; reject 2: too busy"</em>.
Nothing on this page changes any file. Only approved assets are added to a project (asset-integrate.sh).</footer>
</main></body></html>
FOOT
} > "$OUT"
echo "review sheet: $OUT  ($(du -h "$OUT" | cut -f1), ${#JOBS[@]} job(s))"
