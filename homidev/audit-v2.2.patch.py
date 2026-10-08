#!/usr/bin/env python3
# Builds homidev-audit.sh v2.2 from v2.1 (T6, step 12). Exact-once replacements. Run on homidev.
import sys
p = sys.argv[1]
s = open(p).read()
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:50]
    s = s.replace(old, new)

rep("# homidev-audit.sh v2.1 (5 Oct 2026; v2.1: swap via /proc/swaps, du follows symlinks, clean-up log line)",
    "# homidev-audit.sh v2.2 (8 Oct 2026; v2.2 (T6, step 12): LM Studio checks, no LLM model left loaded, bind addresses of ComfyUI/Ollama/LM Studio)\n# v2.1 (5 Oct 2026: swap via /proc/swaps, du follows symlinks, clean-up log line)")
rep('echo "homidev-audit v2.1 —', 'echo "homidev-audit v2.2 —')
rep("# ---------------------------------------------------------------- 12. Removed tools",
r'''# ---------------------------------------------------------------- 11b. LLM tools (step 12) and who listens where
head_ "11b. LLM tools (step 12): nothing may stay loaded on the GPU; servers local-only where agreed"
LMS="$HOME/.lmstudio/bin/lms"
if [ -x "$LMS" ]; then
  if "$LMS" daemon status 2>/dev/null | grep -q running; then
    info "LM Studio daemon running ($("$LMS" daemon status 2>/dev/null | grep -o 'v[0-9.+]*' | head -n1))"
    LP=$("$LMS" ps --json 2>/dev/null); [ "$LP" = "[]" ] && pass "LM Studio: no model loaded" || warn "LM Studio has a model loaded: $LP (run: lms unload --all)"
  else info "LM Studio daemon not running (normal after a reboot; start with: lms daemon up && lms server start)"; fi
  LB=$(ss -ltnH 2>/dev/null | awk '$4 ~ /:1234$/{print $4}' | head -n1)
  case "$LB" in "") info "LM Studio server not listening";; 127.0.0.1:*) pass "LM Studio server local-only ($LB)";; *) fail "LM Studio server listens on $LB (must be 127.0.0.1)";; esac
else info "LM Studio not installed"; fi
OP=$(curl -s -m 5 http://127.0.0.1:11434/api/ps 2>/dev/null | jq -r '[.models[].name]|join(", ")' 2>/dev/null)
[ -z "$OP" ] && pass "Ollama: no model loaded" || warn "Ollama has loaded: $OP (unloads itself after 2 min)"
for pair in "8188 ComfyUI" "11434 Ollama"; do
  set -- $pair; B=$(ss -ltnH 2>/dev/null | awk -v p=":$1\$" '$4 ~ p {print $4}' | head -n1)
  case "$B" in 127.0.0.1:*) pass "$2 :$1 local-only ($B)";; "") fail "$2 :$1 not listening";; *) warn "$2 :$1 listens on $B — open to the whole LAN without a password (review D4: bind to 127.0.0.1)";; esac
done

# ---------------------------------------------------------------- 12. Removed tools''')
open(p, "w").write(s)
print("audit v2.2 written")
