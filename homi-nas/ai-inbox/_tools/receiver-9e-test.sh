#!/usr/bin/env bash
# receiver-9e-test.sh - run on homi-nas. First automatic VOICE job (commercial-OK recipe):
# health -> submit -> poll -> pull (read-only key) -> Stage 1 checks.   (1 Oct 2026)
set -u
T=$(cat ~/.config/asset-receiver/token)
R=http://192.168.100.123:8190
ID="$(date +%Y%m%d-%H%M)-test-voice-01"
H=(-H "X-Receiver-Token: $T")

echo "== 1. health"
curl -s "${H[@]}" $R/health | jq -c .

echo "== 2. submit $ID"
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $R/jobs -d '{
  "job_id": "'$ID'", "project": "test", "commercial": "yes", "requested_by": "homi-nas (9e test)",
  "asset_type": "voice", "recipe": "voice-en-standard",
  "inputs": {"script": "Welcome to LiveHealthy Learn by HomiLabs. Drink enough water every day, and wash your hands before meals.", "glossary": "LiveHealthy HomiLabs"}
}' | jq -c .

echo "== 3. waiting (checks every 10 s, max 10 min)"
for i in $(seq 1 60); do
  S=$(curl -s "${H[@]}" $R/jobs/$ID | jq -r .state)
  echo "   $(date +%H:%M:%S)  $S"
  [ "$S" = "done" ] || [ "$S" = "failed" ] && break
  sleep 10
done
if [ "$S" != "done" ]; then
  echo "Job did not finish:"; curl -s "${H[@]}" $R/jobs/$ID | jq .; exit 1
fi

echo "== 4. pull"
mkdir -p ~/ai-inbox/test/$ID
rsync -a -e "ssh -i ~/.ssh/homidev_pull" homidev@192.168.100.123:$ID/ ~/ai-inbox/test/$ID/
ls -l ~/ai-inbox/test/$ID

echo "== 5. Stage 1 checks (as a COMMERCIAL project - must pass the licence gate)"
~/ai-inbox/_tools/stage1-check.sh ~/ai-inbox/test/$ID yes
echo "== 6. whisper script check (from manifest)"
jq -c ".script_check, [.files[] | {name, duration_sec, loudness_lufs, size}]" ~/ai-inbox/test/$ID/manifest.json
echo "Listen in VS Code on homi-nas (click the .ogg or .wav): ~/ai-inbox/test/$ID/"
