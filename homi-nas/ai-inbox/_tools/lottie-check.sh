#!/usr/bin/env bash
# lottie-check.sh <job-folder>   (v1.0, 8 Oct 2026, LT3) - checks a HomiLabs Lottie job on homi-nas. Pure checker.
# Rules (LT2): valid JSON with Lottie fields; fps <= 30; 0.3-10 s; 512 px square (WARN otherwise); size <= 50 KB WARN,
#   > 150 KB FAIL; forbidden: expressions ("x":"..."), images (assets with p/u), text layers (ty 5), effects (ef),
#   precomp layers (ty 0) WARN; manifest asset_type lottie + commercial_ok yes; renders frame 0 with python-lottie.
# Prints PASS/WARN/FAIL lines like stage1-check.sh. Exit 0 = no FAIL.
set -u
DIR="$1"; cd "$DIR" || { echo "no such folder: $DIR"; exit 2; }
PY="$HOME/lottie/venv/bin/python"
FAIL=0; WARN=0
ok(){ echo "  PASS  $1"; }
bad(){ echo "  FAIL  $1"; FAIL=1; }
warn(){ echo "  WARN  $1"; WARN=$((WARN+1)); }
echo "Lottie checks: $(basename "$DIR")"
[ -f manifest.json ] || { bad "manifest.json missing"; echo "RESULT: FAIL"; exit 1; }
[ "$(jq -r .asset_type manifest.json)" = lottie ] && ok "manifest asset_type = lottie" || bad "manifest asset_type is not lottie"
[ "$(jq -r .commercial_ok manifest.json)" = yes ] && ok "commercial_ok = yes (original work)" || bad "commercial_ok not yes"
for f in $(jq -r '.files[].name' manifest.json | grep -E '\.json$'); do
  [ -f "$f" ] || { bad "$f missing"; continue; }
  jq empty "$f" 2>/dev/null && ok "$f is valid JSON" || { bad "$f is not valid JSON"; continue; }
  v=$(jq -r '.v // empty' "$f"); fr=$(jq -r '.fr // empty' "$f"); ip=$(jq -r '.ip // empty' "$f"); op=$(jq -r '.op // empty' "$f")
  w=$(jq -r '.w // empty' "$f"); h=$(jq -r '.h // empty' "$f"); layers=$(jq '.layers|length' "$f")
  [ -n "$v" ] && [ -n "$fr" ] && [ -n "$op" ] && ok "$f Lottie v$v, $layers layer(s)" || bad "$f missing Lottie fields (v/fr/op)"
  awk -v r="$fr" 'BEGIN{exit !(r>0 && r<=30)}' && ok "$f fps $fr" || bad "$f fps $fr (max 30)"
  sec=$(awk -v a="$ip" -v b="$op" -v r="$fr" 'BEGIN{printf "%.2f", (b-a)/r}')
  awk -v s="$sec" 'BEGIN{exit !(s>=0.3 && s<=10)}' && ok "$f length ${sec}s ($((op-ip)) frames)" || bad "$f length ${sec}s (allowed 0.3-10 s)"
  [ "$w" = 512 ] && [ "$h" = 512 ] && ok "$f size ${w}x${h}" || warn "$f size ${w:-?}x${h:-?} (standard is 512x512)"
  kb=$(( $(stat -c %s "$f") / 1024 ))
  if [ "$kb" -gt 150 ]; then bad "$f is ${kb} KB (max 150)"; elif [ "$kb" -gt 50 ]; then warn "$f is ${kb} KB (aim <= 50)"; else ok "$f ${kb} KB"; fi
  # forbidden features
  ex=$(jq '[..|objects|select(has("x") and (.x|type=="string"))]|length' "$f")
  [ "$ex" = 0 ] && ok "$f no expressions" || bad "$f has $ex expression(s) (not allowed: Flutter/Android do not run them)"
  im=$(jq '[.assets[]?|select(has("p") or has("u"))]|length' "$f")
  [ "$im" = 0 ] && ok "$f no embedded images" || bad "$f has $im image asset(s)"
  tx=$(jq '[.layers[]?|select(.ty==5)]|length' "$f")
  [ "$tx" = 0 ] && ok "$f no text layers" || bad "$f has $tx text layer(s)"
  ef=$(jq '[.layers[]?|select(has("ef") and (.ef|length>0))]|length' "$f")
  [ "$ef" = 0 ] && ok "$f no effects" || bad "$f has effects on $ef layer(s)"
  pc=$(jq '[.layers[]?|select(.ty==0)]|length' "$f")
  [ "$pc" = 0 ] && ok "$f no precomp layers" || warn "$f has $pc precomp layer(s) (keep simple)"
  # render test
  if [ -x "$PY" ]; then
    if "$PY" - "$f" <<'EOF' 2>/dev/null
import sys, io
from lottie.parsers.tgs import parse_tgs
from lottie.exporters.cairo import export_png
an = parse_tgs(sys.argv[1]); buf = io.BytesIO(); export_png(an, buf, frame=0)
sys.exit(0 if buf.tell() > 100 else 1)
EOF
    then ok "$f renders (frame 0 via python-lottie)"; else bad "$f failed to render with python-lottie"; fi
  else warn "python-lottie env missing (~/lottie/venv) - render test skipped"; fi
done
if [ $FAIL -ne 0 ]; then echo "RESULT: FAIL"; elif [ $WARN -gt 0 ]; then echo "RESULT: PASS with $WARN warning(s)"; else echo "RESULT: PASS"; fi
exit $FAIL
