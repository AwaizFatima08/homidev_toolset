#!/bin/bash
# homidev-status.sh v1.0 (9 Oct 2026, S2) - one-screen state of homidev from homi-nas. Read-only.
# Usage: homidev-status.sh          (receiver over HTTP + details over SSH; ~3 s)
set -u
H=192.168.100.123; TOK=$(cat "$HOME/.config/asset-receiver/token" 2>/dev/null || true)
echo "homidev status  $(date '+%Y-%m-%d %H:%M')"
if ! ping -c1 -W1 $H >/dev/null 2>&1; then echo "  DOWN   homidev does not answer (off, or booted into Windows)"; exit 1; fi
HEALTH=$(curl -s -m 5 -H "X-Receiver-Token: $TOK" "http://$H:8190/health" 2>/dev/null)
if [ -n "$HEALTH" ]; then
  echo "$HEALTH" | jq -r '"  receiver \(.receiver) · comfyui \(.comfyui) · queue \(.queue_length) · running \(.running // "none") · disk free \(.disk_free_gb) GB · recipes \(.approved_recipes) (problems \(.recipe_problems))"'
else echo "  WARN   receiver :8190 not answering (service down?)"; fi
ssh -o BatchMode=yes -o ConnectTimeout=5 homidev@$H 'export PATH=$HOME/.lmstudio/bin:$PATH
echo "  up $(uptime -p | sed s/^up\ //) · load $(cut -d" " -f1 /proc/loadavg) · RAM $(free -h | awk "/^Mem:/{print \$7\" free of \"\$2}")"
echo "  GPU $(nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader | sed "s/, / · /g")"
O=$(curl -s -m 3 http://127.0.0.1:11434/api/ps | jq -r "[.models[].name]|join(\", \")" 2>/dev/null); echo "  Ollama loaded: ${O:-none}"
if [ -x "$HOME/.lmstudio/bin/lms" ]; then L=$(lms ps --json 2>/dev/null); if [ "$L" = "[]" ] || [ -z "$L" ]; then echo "  LM Studio loaded: none ($(lms daemon status 2>/dev/null | grep -q running && echo daemon up || echo daemon down))"; else echo "  LM Studio loaded: $L"; fi; fi
echo "  services: $(for s in comfyui ollama asset-receiver; do printf "%s=%s " $s $(systemctl is-active $s 2>/dev/null); done)"
echo "  jobs on disk: $(ls -d ~/assets/jobs/*/ 2>/dev/null | wc -l) · ComfyUI output leftovers: $(find ~/ComfyUI/output -type f 2>/dev/null | wc -l) file(s)"
A=$(ls -t ~/audit-logs/*.txt 2>/dev/null | head -n1); if [ -n "$A" ]; then echo "  last audit: $(basename $A .txt) -> $(grep -m1 "^== SUMMARY" "$A" | sed "s/== //")"; else echo "  last audit: no audit-logs yet (S3 not installed) - run ~/homidev-audit.sh"; fi' 2>/dev/null || echo "  WARN   ssh to homidev failed (key?)"
