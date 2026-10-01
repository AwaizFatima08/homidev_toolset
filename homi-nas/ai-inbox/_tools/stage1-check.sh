#!/usr/bin/env bash
# stage1-check.sh <job-folder> <commercial-project: yes|no>   (DRAFT v0.2, 1 Oct 2026)
# Lives on homi-nas at ~/ai-inbox/_tools/stage1-check.sh
# v0.2: receiver bookkeeping files (request.json, status.json) are expected, not "unlisted";
#       status.json must say "done"; list/dict fields printed on one line.
# Known gaps (to add in build step 10): subject-touches-edge check, Claude visual review,
# audio checks, automatic move of rejected jobs to ~/ai-inbox/_rejected/ with reason.
set -u
DIR="$1"; COMM="${2:-yes}"
cd "$DIR" || { echo "no such folder: $DIR"; exit 2; }
FAIL=0
ok(){ echo "  PASS  $1"; }
bad(){ echo "  FAIL  $1"; FAIL=1; }
echo "Stage 1 checks: $(basename "$DIR")   (commercial project: $COMM)"
if [ -f manifest.json ] && jq empty manifest.json 2>/dev/null; then ok "manifest.json present and valid"; else bad "manifest missing or invalid"; exit 1; fi
for k in job_id project asset_type model model_licence commercial_ok created_at; do
  v=$(jq -c ".$k // empty" manifest.json | tr -d '"'); [ -n "$v" ] && ok "field $k = $v" || bad "field $k missing"
done
[ "$(jq -r .job_id manifest.json)" = "$(basename "$DIR")" ] && ok "job_id matches folder name" || bad "job_id does not match folder name"
if [ -f status.json ]; then
  s=$(jq -r .state status.json); [ "$s" = "done" ] && ok "receiver status = done" || bad "receiver status = $s (not done)"
fi
while read -r name sha; do
  if [ ! -f "$name" ]; then bad "$name is missing"; continue; fi
  [ "$(sha256sum "$name" | cut -d' ' -f1)" = "$sha" ] && ok "$name fingerprint matches" || bad "$name fingerprint MISMATCH"
  echo "        $(file -b "$name")"
done < <(jq -r '.files[] | "\(.name) \(.sha256)"' manifest.json)
extra=$(comm -23 <(ls | grep -v -x -E 'manifest.json|request.json|status.json' | sort) <(jq -r '.files[].name' manifest.json | sort))
[ -z "$extra" ] && ok "no unlisted files" || bad "unlisted files: $(echo $extra)"
for c in $(jq -r '.files[].name' manifest.json | grep _cutout); do
  file -b "$c" | grep -q RGBA && ok "$c has transparency" || bad "$c has NO transparency"
done
LIC=$(jq -r .commercial_ok manifest.json)
if [ "$COMM" = "yes" ] && [ "$LIC" != "yes" ]; then bad "LICENCE GATE: commercial project, but commercial_ok = $LIC"; else ok "licence gate"; fi
[ $FAIL -eq 0 ] && echo "RESULT: PASS -> ready for Stage 2 (human review)" || echo "RESULT: FAIL"
exit $FAIL
