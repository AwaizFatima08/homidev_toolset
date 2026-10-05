#!/bin/bash
# homidev-audit.sh v2.1 (5 Oct 2026; v2.1: swap via /proc/swaps, du follows symlinks, clean-up log line) — read-only health check of homidev (design v1.1)
# Decisions A1–A4 (Homi, 5 Oct): read-only, sudo checks SKIP · fast by default, --hashes for sha256
# · unregistered model = FAIL · exit 1 if any FAIL.
# Usage:  ./homidev-audit.sh            (a few seconds)
#         ./homidev-audit.sh --hashes   (adds sha256 of every registered model, ~2 min)

set -u
HASHES=no; [ "${1:-}" = "--hashes" ] && HASHES=yes

NVME_SERIAL="S6S2NS0TB11541M"          # Samsung 970 EVO Plus 2TB (system disk)
MODELS_JSON="$HOME/assets/models.json"
COMFY_MODELS="$HOME/ComfyUI/models"
MIN_FREE_GB=100
BLOCKED_RE='rmbg-2|rmbg_2|rmbg2|klein-9b|klein_9b|klein9b|flux1-dev|flux1_dev|flux\.1-dev|flux2-dev|flux2_dev|flux-2-dev'

P=0; W=0; F=0; S=0
pass() { echo "  PASS  $*"; P=$((P+1)); }
warn() { echo "  WARN  $*"; W=$((W+1)); }
fail() { echo "  FAIL  $*"; F=$((F+1)); }
skip() { echo "  SKIP  $*"; S=$((S+1)); }
info() { echo "  info  $*"; }
head_() { echo; echo "== $*"; }

echo "homidev-audit v2.1 — $(hostname) — $(date '+%Y-%m-%d %H:%M')  (hashes: $HASHES)"

# ---------------------------------------------------------------- 1. Boot
head_ "1. Boot (system disk = 970, serial $NVME_SERIAL)"
part() { readlink -f /dev/disk/by-id/nvme-*"${NVME_SERIAL}"-part"$1" 2>/dev/null | head -n1; }
P1=$(part 1); P2=$(part 2); P3=$(part 3)
if [ -z "$P3" ]; then
  fail "970 not found by serial in /dev/disk/by-id"
else
  ROOT=$(findmnt -no SOURCE /)
  [ "$ROOT" = "$P3" ] && pass "/ on 970 partition 3 ($ROOT)" || fail "/ is on $ROOT, expected 970 p3 ($P3)"
  EFI=$(findmnt -no SOURCE /boot/efi)
  [ "$EFI" = "$P1" ] && pass "/boot/efi on 970 partition 1" || fail "/boot/efi is on $EFI, expected 970 p1 ($P1)"
  SWAPS=$(awk 'NR>1{print $1}' /proc/swaps | while read -r d; do readlink -f "$d"; done)
  if grep -qx "$P2" <<<"$SWAPS"; then pass "swap on 970 partition 2"
  else fail "970 swap (p2) not active; active swap: $(tr '\n' ' ' <<<"$SWAPS")"; fi
fi
if command -v mokutil >/dev/null; then
  SB=$(mokutil --sb-state 2>/dev/null)
  if   echo "$SB" | grep -q "SecureBoot enabled"; then pass "Secure Boot enabled"
  elif [ -z "$SB" ]; then skip "Secure Boot state not readable without sudo"
  else warn "Secure Boot: $SB"; fi
else skip "mokutil not installed"; fi
if EB=$(efibootmgr 2>/dev/null); then
  if echo "$EB" | grep -q "debian-nvme"; then pass "boot entry 'debian-nvme' present (by name)"
  else fail "boot entry 'debian-nvme' missing — see recovery recipe in checklist E"; fi
else skip "efibootmgr not readable without sudo"; fi
info "kernel $(uname -r), up $(uptime -p | sed 's/^up //')"

# ---------------------------------------------------------------- 2. Disk / RAM
head_ "2. Disk and memory"
FREE_GB=$(df -BG --output=avail / | tail -n1 | tr -dc '0-9')
[ "$FREE_GB" -ge "$MIN_FREE_GB" ] && pass "free on /: ${FREE_GB} GB" || warn "free on /: only ${FREE_GB} GB (< ${MIN_FREE_GB})"
info "RAM: $(free -h | awk '/^Mem:/{print $7" available of "$2}') · swap used: $(free -h | awk '/^Swap:/{print $3" of "$2}')"
systemctl is-active --quiet earlyoom && pass "earlyoom running" || fail "earlyoom not running"

# ---------------------------------------------------------------- 3. GPU
head_ "3. GPU"
if GPU=$(nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total --format=csv,noheader 2>/dev/null); then
  echo "$GPU" | grep -q "5060 Ti" && pass "GPU: $GPU" || warn "unexpected GPU: $GPU"
else fail "nvidia-smi failed (driver not loaded?)"; fi

# ---------------------------------------------------------------- 4. Services
head_ "4. Services"
for s in comfyui ollama asset-receiver; do
  a=$(systemctl is-active "$s" 2>/dev/null); e=$(systemctl is-enabled "$s" 2>/dev/null)
  [ "$a" = active ] && [ "$e" = enabled ] && pass "$s active + enabled" || fail "$s: $a / $e"
done
systemctl is-active --quiet asset-cleanup.timer && pass "asset-cleanup.timer active" || fail "asset-cleanup.timer not active"
if L=$(journalctl -u asset-cleanup.service -n 50 --no-pager -o cat 2>/dev/null | grep -E 'DRY RUN|would delete|[0-9]+ deleted|kept [0-9]' | tail -n1) && [ -n "$L" ]; then
  info "last clean-up: $L"
else skip "clean-up log not readable without sudo (or no run yet)"; fi

# ---------------------------------------------------------------- 5. Endpoints
head_ "5. Endpoints"
LANIP=$(hostname -I | awk '{print $1}')
code() { for h in 127.0.0.1 "$LANIP"; do c=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "http://$h:$1$2"); [ "$c" != 000 ] && { echo "$c"; return; }; done; echo 000; }
[ "$(code 8188 /system_stats)" = 200 ] && pass "ComfyUI :8188 answers" || fail "ComfyUI :8188 not answering"
[ "$(code 11434 /api/tags)" = 200 ] && pass "Ollama :11434 answers" || fail "Ollama :11434 not answering"
RC=$(code 8190 /health)
case "$RC" in
  401) pass "receiver :8190 answers and refuses a request without token (401)";;
  200) fail "receiver :8190 answered WITHOUT a token — token check broken";;
  *)   fail "receiver :8190 not answering (HTTP $RC)";;
esac

# ---------------------------------------------------------------- 6. ComfyUI torch
head_ "6. ComfyUI PyTorch"
PY=$(systemctl show -p ExecStart --value comfyui 2>/dev/null | sed -n 's/.*path=\([^ ;]*\).*/\1/p' | head -n1)
if [ -n "$PY" ] && [ -x "$PY" ]; then
  T=$("$PY" -c 'import torch;print(torch.__version__, torch.cuda.is_available())' 2>/dev/null)
  [ "$T" = "2.14.0+cu130 True" ] && pass "torch $T" || fail "torch is '$T', expected '2.14.0+cu130 True'"
else skip "could not find ComfyUI's python from the service file"; fi

# ---------------------------------------------------------------- 7. Registered models
head_ "7. Registered models (models.json)"
REG_FILES=""
if jq -e . "$MODELS_JSON" >/dev/null 2>&1; then
  pass "models.json valid JSON ($(jq '.models|length' "$MODELS_JSON") entries, updated $(jq -r .updated "$MODELS_JSON"))"
  while IFS=$'\t' read -r key file ok sha; do
    path="$HOME/$file"; REG_FILES+="$path"$'\n'
    if [ "$sha" = folder ]; then
      [ -d "$path" ] && pass "$key (folder, commercial_ok=$ok)" || fail "$key: folder missing $path"
      continue
    fi
    if [ ! -s "$path" ]; then fail "$key: file missing or empty $path"; continue; fi
    if [ "$HASHES" = yes ]; then
      h=$(sha256sum "$path" | cut -d' ' -f1)
      [ "$h" = "$sha" ] && pass "$key sha256 OK (commercial_ok=$ok)" || fail "$key sha256 MISMATCH"
    else
      pass "$key present, $(du -hL "$path" | cut -f1) (commercial_ok=$ok)"
    fi
  done < <(jq -r '.models|to_entries[]|[.key,.value.file,.value.commercial_ok,.value.sha256]|@tsv' "$MODELS_JSON")
else fail "models.json missing or invalid: $MODELS_JSON"; fi
[ -f "$HOME/assets/MODEL-REGISTER.md" ] && pass "MODEL-REGISTER.md present" || fail "MODEL-REGISTER.md missing"

# ---------------------------------------------------------------- 8. Unregistered models
head_ "8. Unregistered model files under ComfyUI/models"
N=0
while IFS= read -r f; do
  if ! grep -qxF "$f" <<<"$REG_FILES"; then fail "not in register: ${f#$HOME/}"; N=$((N+1)); fi
done < <(find "$COMFY_MODELS" \( -type f -o -type l \) \
          \( -iname '*.safetensors' -o -iname '*.ckpt' -o -iname '*.pt' -o -iname '*.pth' \
             -o -iname '*.bin' -o -iname '*.gguf' -o -iname '*.onnx' -o -iname '*.sft' \) 2>/dev/null | sort)
[ "$N" -eq 0 ] && pass "every model file is registered"

# ---------------------------------------------------------------- 9. Blocked models
head_ "9. Blocked models"
B=$(find "$COMFY_MODELS" "$HOME/.cache/huggingface" "$HOME/model-review" 2>/dev/null | grep -Ei "$BLOCKED_RE")
[ -z "$B" ] && pass "no blocked model found" || { while IFS= read -r b; do fail "BLOCKED model present: ${b#$HOME/}"; done <<<"$B"; }

# ---------------------------------------------------------------- 10. Pipeline
head_ "10. Pipeline folders and pull key"
for d in "$HOME/assets/jobs" "$HOME/assets/recipes"; do
  [ -d "$d" ] && pass "${d#$HOME/} exists" || fail "${d#$HOME/} missing"
done
info "jobs on disk: $(find "$HOME/assets/jobs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
if grep -E '^restrict,command="/usr/bin/rrsync -ro ' "$HOME/.ssh/authorized_keys" >/dev/null 2>&1; then
  pass "pull key locked (restrict + rrsync -ro)"
else fail "pull key lock not found in ~/.ssh/authorized_keys"; fi
[ -s "$HOME/.config/asset-receiver/token" ] && pass "receiver token present" || fail "receiver token missing"

# ---------------------------------------------------------------- 11. Voice
head_ "11. Voice environments"
for d in tts stt; do
  if [ -x "$HOME/voice/$d/bin/python" ] || [ -x "$HOME/voice/$d/.venv/bin/python" ]; then pass "~/voice/$d environment present"
  elif [ -d "$HOME/voice/$d" ]; then warn "~/voice/$d exists but no python found inside"
  else fail "~/voice/$d missing"; fi
done

# ---------------------------------------------------------------- 12. Removed tools
head_ "12. Removed tools stay removed"
GONE=1
for c in invokeai invokeai-web upscayl rustdesk; do command -v "$c" >/dev/null && { fail "$c is back ($(command -v $c))"; GONE=0; }; done
for p in rustdesk claude-desktop; do dpkg -s "$p" >/dev/null 2>&1 && { fail "package $p is installed again"; GONE=0; }; done
[ -d "$HOME/invokeai" ] && { fail "~/invokeai folder is back"; GONE=0; }
[ "$GONE" -eq 1 ] && pass "InvokeAI, Upscayl, RustDesk, Claude desktop absent"

# ---------------------------------------------------------------- info
head_ "Info"
info "Ollama models: $(curl -s -m 5 http://127.0.0.1:11434/api/tags 2>/dev/null | jq -r '[.models[].name]|join(", ")' 2>/dev/null)"
pgrep -f open-webui >/dev/null && info "OpenWebUI running" || info "OpenWebUI not running (normal — started by hand with 'webui')"

# ---------------------------------------------------------------- summary
echo
echo "== SUMMARY: $P pass · $W warn · $F fail · $S skip"
[ "$F" -eq 0 ] && { echo "RESULT: OK"; exit 0; } || { echo "RESULT: FAIL"; exit 1; }
