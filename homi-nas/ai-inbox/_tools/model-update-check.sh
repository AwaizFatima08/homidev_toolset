#!/bin/bash
# model-update-check.sh   (v1.0, 9 Oct 2026, S10) - monthly reminder: what could be updated, what must be re-checked.
# Read-only. Reports: newer Ollama tags for installed chat models (registry manifest digest vs local), LM Studio runtime/app
# updates, and the dated licence re-checks (Stability AI every October). Nothing is downloaded or changed.
set -u
H=192.168.100.123
echo "model-update-check  $(date '+%Y-%m-%d')"
echo "== Ollama chat models (local manifest digest vs registry)"
ssh -n -o BatchMode=yes -o ConnectTimeout=5 homidev@$H 'curl -s -m 5 http://127.0.0.1:11434/api/tags | jq -r ".models[]|\"\(.name) \(.digest)\""' 2>/dev/null > /tmp/ollama-tags.$$ || true
while read -r name digest; do
  repo=${name%%:*}; tag=${name##*:}; [ "$repo" = "$name" ] && tag=latest
  remote=$(curl -sI -m 10 -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "https://registry.ollama.ai/v2/library/$repo/manifests/$tag" | tr -d "\r" | awk -F": " "tolower(\$1)==\"ollama-content-digest\" || tolower(\$1)==\"docker-content-digest\"{print \$2}" | sed "s/^sha256://")
  if [ -z "$remote" ]; then echo "  ?      $name - registry did not answer"
  elif [ "$remote" = "$digest" ]; then echo "  OK     $name is current"
  else echo "  UPDATE $name - registry has a newer build (ollama pull $name; re-run the LLM test sheet if it is a test model)"; fi
done < /tmp/ollama-tags.$$; rm -f /tmp/ollama-tags.$$
echo "== LM Studio"
ssh -o BatchMode=yes -o ConnectTimeout=5 homidev@$H 'export PATH=$HOME/.lmstudio/bin:$PATH; echo "  daemon: $(lms daemon status 2>/dev/null | grep -o "v[0-9.+]*" | head -n1 || echo not running)"; lms runtime ls 2>/dev/null | grep -v Warn | grep -E "cuda|SELECTED" | head -3 | sed "s/^/  /"; echo "  check for updates: lms daemon update (asks first); lms runtime update"' 2>/dev/null
echo "== Dated licence and model re-checks"
M=$(date +%m)
[ "$M" = 10 ] && echo "  DUE    October: re-check the Stability AI Community Licence terms (Stable Audio 3 sfx/music) and HomiLabs' registration" || echo "  -      Stability AI Community Licence: re-check every October (next: October $(( $(date +%Y) + ( M > 10 ) )))"
echo "  -      Z-Image-Turbo, Kokoro, Wan 2.2, BiRefNet, Real-ESRGAN: no dated terms (Apache/MIT/BSD)"
echo "  -      python-lottie (AGPL tool), lottie-web (MIT): check for new versions when touching the Lottie tools"
echo "Nothing was changed. Updates go through the normal download -> ~/model-review -> register -> Homi approval path."
