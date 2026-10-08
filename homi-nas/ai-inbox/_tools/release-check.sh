#!/bin/bash
# release-check.sh <repo>   (v1.0, 9 Oct 2026, S5) - run before any release build of a Flutter app that uses homidev assets.
# Checks: every file in assets/ASSET-REGISTER.md exists and its folder is declared in pubspec.yaml; every credit line in
# assets/ATTRIBUTION.md (e.g. "Powered by Stability AI") appears somewhere in lib/ (About screen) or in a store-listing text
# file (store/*.txt, fastlane/metadata/**); lottie files need the lottie package. Pure checker. Exit 0 = PASS, 1 = FAIL.
set -u
REPO=$(realpath -m "${1:-.}"); cd "$REPO" || { echo "no such folder: $REPO"; exit 2; }
FAIL=0; WARN=0
ok(){ echo "  PASS  $1"; }; bad(){ echo "  FAIL  $1"; FAIL=1; }; warn(){ echo "  WARN  $1"; WARN=$((WARN+1)); }
echo "Release check: $REPO"
[ -f pubspec.yaml ] || { bad "pubspec.yaml missing (not a Flutter app?)"; echo "RESULT: FAIL"; exit 1; }
REG=assets/ASSET-REGISTER.md
if [ -f "$REG" ]; then
  n=0
  while IFS= read -r f; do
    n=$((n+1))
    [ -f "$f" ] && ok "$f present" || bad "$f listed in ASSET-REGISTER but missing"
    dir="$(dirname "$f")/"
    grep -qE "^\s*-\s*$dir\s*$|^\s*-\s*$f\s*$" pubspec.yaml && ok "$dir declared in pubspec" || bad "$dir (or $f) not declared under flutter: assets: in pubspec.yaml"
    case "$f" in *.json) grep -qE "^\s*lottie:" pubspec.yaml && ok "lottie package present for $f" || bad "$f is a Lottie file but pubspec has no lottie package";; esac
  done < <(grep -oE '`assets/[^`]+`' "$REG" | tr -d '`' | sort -u)
  [ $n -gt 0 ] && ok "$n registered asset file(s) checked" || warn "ASSET-REGISTER.md has no file rows"
else warn "no assets/ASSET-REGISTER.md (no homidev assets in this app?)"; fi
ATT=assets/ATTRIBUTION.md
if [ -f "$ATT" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if grep -rqF -- "$line" lib/ 2>/dev/null; then ok "credit \"$line\" found in lib/ (About screen)"
    elif grep -rqF -- "$line" store/ fastlane/ 2>/dev/null; then ok "credit \"$line\" found in store listing text"
    else bad "credit \"$line\" (assets/ATTRIBUTION.md) not found in lib/ or store text - do not release"; fi
  done < <(grep -oE '\*\*[^*]+\*\*' "$ATT" | tr -d '*' | sort -u)
else ok "no ATTRIBUTION.md - no credits required"; fi
if [ $FAIL -ne 0 ]; then echo "RESULT: FAIL - fix before building a release"; else echo "RESULT: PASS${WARN:+ ($WARN warning(s))} - ready for a release build"; fi
exit $FAIL
