#!/usr/bin/env python3
# Builds stage1-check.sh v0.7 from v0.6 (T3, pipeline review D2 + W1). Exact-once replacements.
import sys
src = open(sys.argv[1]).read()
def rep(old, new):
    global src
    assert src.count(old) == 1, old[:70]
    src = src.replace(old, new)

rep('# stage1-check.sh <job-folder> <commercial-project: yes|no>   (v0.6, 8 Oct 2026)\n',
'''# stage1-check.sh <job-folder> <commercial-project: yes|no>   (v0.7, 8 Oct 2026)
# v0.7 (T3, review D2 + W1): image rules: a PNG with ComfyUI's hidden prompt/workflow text chunk = FAIL for jobs
#       made by receiver >= 0.11 (which strips it), WARN for older jobs; width/height from the file must match
#       the manifest; a non-cutout PNG with transparency = WARN (look). Audio/voice checks unchanged.
''')
rep('''for c in $(jq -r '.files[].name' manifest.json | grep _cutout); do
  file -b "$c" | grep -q RGBA && ok "$c has transparency" || bad "$c has NO transparency"
done
''','''for c in $(jq -r '.files[].name' manifest.json | grep _cutout); do
  file -b "$c" | grep -q RGBA && ok "$c has transparency" || bad "$c has NO transparency"
done

# ---- images (v0.7): hidden workflow text, size, unexpected transparency
RV=$(jq -r '.receiver_version // "0"' manifest.json)
for p in $(jq -r '.files[].name' manifest.json | grep -E '\\.png$'); do
  [ -f "$p" ] || continue
  if python3 - "$p" <<'PY'
import struct, sys
f = open(sys.argv[1], "rb"); f.read(8); hit = False
while True:
    h = f.read(8)
    if len(h) < 8: break
    n, t = struct.unpack(">I4s", h); d = f.read(n); f.read(4)
    if t in (b"tEXt", b"zTXt", b"iTXt") and d.split(b"\\0", 1)[0] in (b"prompt", b"workflow"): hit = True
    if t == b"IEND": break
sys.exit(0 if hit else 1)
PY
  then
    if [ "$(printf '%s\\n' 0.11 "$RV" | sort -V | head -n1)" = 0.11 ]; then bad "$p contains hidden workflow info (receiver $RV should have stripped it)"
    else warn "$p contains ComfyUI's hidden prompt/workflow text (made by receiver $RV, before v0.11 stripped it)"; fi
  else ok "$p no hidden workflow info"; fi
  read -r w h < <(file -b "$p" | grep -oP '\\d+ x \\d+' | head -n1 | tr -d x)
  mw=$(jq -r --arg f "$p" '.files[]|select(.name==$f)|.width // empty' manifest.json)
  mh=$(jq -r --arg f "$p" '.files[]|select(.name==$f)|.height // empty' manifest.json)
  if [ -n "$mw" ] && [ -n "$w" ]; then
    [ "$w" = "$mw" ] && [ "$h" = "$mh" ] && ok "$p size ${w}x${h} matches manifest" || bad "$p size ${w:-?}x${h:-?} but manifest says ${mw}x${mh}"
  fi
  case "$p" in *_cutout.*) ;; *) file -b "$p" | grep -q RGBA && warn "$p has transparency (not a cutout - look at it)";; esac
done
''')
open(sys.argv[2], "w").write(src)
print("stage1-check.sh v0.7 written to", sys.argv[2])
