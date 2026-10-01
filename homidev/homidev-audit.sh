#!/usr/bin/env bash
# homidev-audit.sh — READ-ONLY status check for the homidev toolset checklist.
# It changes nothing. Run with:  bash homidev-audit.sh
# (It asks for your sudo password once, only to read Secure Boot state.)

ok()   { printf "  [OK]   %s\n" "$1"; }
bad()  { printf "  [--]   %s\n" "$1"; }
info() { printf "  [..]   %s\n" "$1"; }
has()  { command -v "$1" >/dev/null 2>&1; }

echo "=== homidev audit  $(date '+%Y-%m-%d %H:%M') ==="

echo; echo "A. Foundation"
if nvidia-smi >/dev/null 2>&1; then
  ok "NVIDIA driver $(nvidia-smi --query-gpu=driver_version,name --format=csv,noheader)"
else bad "NVIDIA driver NOT working"; fi
info "Secure Boot: $(mokutil --sb-state 2>/dev/null || echo unknown)"
[ "$(systemctl is-enabled sleep.target 2>/dev/null)" = "masked" ] && ok "Sleep disabled (masked)" || bad "Sleep NOT masked"
for p in btop nvtop earlyoom google-chrome-stable; do
  dpkg -s "$p" >/dev/null 2>&1 && ok "$p installed" || bad "$p missing"
done
[ "$(systemctl is-active earlyoom)" = "active" ] && ok "earlyoom active" || bad "earlyoom not active"

echo; echo "B. AI engines"
# ComfyUI
[ "$(systemctl is-active comfyui 2>/dev/null)" = "active" ] && ok "comfyui service active" || bad "comfyui service not active"
[ "$(systemctl is-enabled comfyui 2>/dev/null)" = "enabled" ] && ok "comfyui starts at boot" || bad "comfyui not enabled at boot"
if [ -x ~/ComfyUI/venv/bin/python ]; then
  info "ComfyUI torch: $(~/ComfyUI/venv/bin/python -c 'import torch;print(torch.__version__, "cuda=",torch.cuda.is_available())' 2>/dev/null)"
fi
[ -d ~/ComfyUI/custom_nodes/ComfyUI-Manager ] && ok "ComfyUI-Manager installed" || bad "ComfyUI-Manager not installed"
info "ComfyUI checkpoints: $(ls ~/ComfyUI/models/checkpoints 2>/dev/null | grep -v put_ | tr '\n' ' ')"
# InvokeAI
if [ -x ~/invokeai/venv/bin/python ]; then
  info "InvokeAI torch/numpy: $(~/invokeai/venv/bin/python -c 'import torch,numpy;print(torch.__version__, "cuda=",torch.cuda.is_available(), "numpy",numpy.__version__)' 2>/dev/null)"
fi
grep -q "host: 0.0.0.0" ~/invokeai/invokeai.yaml 2>/dev/null && ok "InvokeAI LAN config (0.0.0.0)" || bad "InvokeAI not set for LAN"
# Ollama
if has ollama; then
  ok "Ollama $(ollama -v 2>/dev/null | awk '{print $NF}')"
  info "Ollama models: $(ollama list 2>/dev/null | awk 'NR>1{print $1}' | tr '\n' ' ')"
else bad "Ollama not installed"; fi
[ -f /etc/systemd/system/ollama.service.d/override.conf ] && ok "Ollama override file present" || bad "Ollama override missing"

echo; echo "   All listening ports (8188 ComfyUI / 9090 InvokeAI / 11434 Ollama / OpenWebUI usually 8080):"
ss -tln 2>/dev/null | awk 'NR>1{print $4}' | sort -u | sed 's/^/     /'
pgrep -af -i "open-webui|open_webui" >/dev/null && ok "OpenWebUI process running" || bad "OpenWebUI process not found"

echo; echo "C. Extra tools"
for t in whisper-ctranslate2 piper kdenlive; do has "$t" && ok "$t" || bad "$t not installed"; done

echo; echo "D. Storage"
info "Root (/) is on: $(findmnt -n -o SOURCE /)"
info "Boot files (/boot/efi) on: $(findmnt -n -o SOURCE /boot/efi 2>/dev/null || echo 'not mounted')"
lsblk -d -o NAME,ROTA,SIZE,MODEL | sed 's/^/     /'
if [ "$(awk 'NR>1' /proc/swaps | wc -l)" -gt 0 ]; then
  ok "Swap: $(awk 'NR>1{printf "%s (%d MB) ", $1, $3/1024}' /proc/swaps)"
else bad "No swap configured"; fi
info "RAM: $(free -h | awk '/Mem:/{print $2" total, "$7" available"}')"
info "Disk free on /: $(df -h / | awk 'NR==2{print $4}')"

echo; echo "E/F. Network & later"
for t in tailscale docker; do has "$t" && ok "$t installed" || bad "$t not installed"; done

echo; echo "=== end of audit ==="
