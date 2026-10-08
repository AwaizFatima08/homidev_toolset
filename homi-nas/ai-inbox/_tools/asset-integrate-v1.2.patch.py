#!/usr/bin/env python3
# Builds asset-integrate.sh v1.2 from v1.1 (LT3): Lottie jobs integrate their *_lottie.json (suggested subfolder: lottie).
import sys
src = open(sys.argv[1]).read()
def rep(old, new):
    global src
    assert src.count(old) == 1, old[:60]
    src = src.replace(old, new)

rep("# asset-integrate.sh v1.1 (8 Oct 2026) — step 10d (M1-M8) + step 11 (A1): act on Homi's Stage 2 decision\n",
    "# asset-integrate.sh v1.2 (8 Oct 2026) — LT3: Lottie jobs (asset_type lottie) copy their *_lottie.json (subfolder: lottie);\n"
    "#       also runs lottie-check.sh again before approving (must not FAIL).\n"
    "# v1.1 (8 Oct 2026) — step 10d (M1-M8) + step 11 (A1): act on Homi's Stage 2 decision\n")
rep('''# M3: images -> all image files; voice -> OGG only (WAV master stays in the inbox)
if jq -e '.files[].name|select(endswith(".ogg"))' "$M" >/dev/null; then''',
'''# M3: images -> all image files; voice -> OGG only (WAV master stays in the inbox); lottie -> the JSON
if [ "$(jq -r .asset_type "$M")" = lottie ]; then
  "$HOME/ai-inbox/_tools/lottie-check.sh" "$JD" >/dev/null 2>&1 || stop "lottie-check FAIL for $J — run lottie-check.sh to see why"
  mapfile -t FILES < <(jq -r '.files[].name|select(endswith("_lottie.json"))' "$M")
elif jq -e '.files[].name|select(endswith(".ogg"))' "$M" >/dev/null; then''')
open(sys.argv[2], "w").write(src)
print("asset-integrate.sh v1.2 written to", sys.argv[2])
