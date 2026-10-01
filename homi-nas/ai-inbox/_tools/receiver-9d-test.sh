#!/usr/bin/env bash
# receiver-9d-test.sh - run on homi-nas. First fully automatic image job:
# health -> submit -> poll -> pull (read-only key) -> Stage 1 checks.   (1 Oct 2026)
set -u
T=$(cat ~/.config/asset-receiver/token)
R=http://192.168.100.123:8190
ID="$(date +%Y%m%d-%H%M)-test-image-01"
H=(-H "X-Receiver-Token: $T")

echo "== 1. health"
curl -s "${H[@]}" $R/health | jq -c .

echo "== 2. submit $ID"
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $R/jobs -d '{
  "job_id": "'$ID'", "project": "test", "commercial": "no", "requested_by": "homi-nas (9d test)",
  "asset_type": "image", "recipe": "test-image-cutout",
  "inputs": {"prompt": "flat vector illustration of a single red apple, centered, plain white background, lots of empty space"}
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

echo "== 5. Stage 1 checks (non-commercial test project)"
~/ai-inbox/_tools/stage1-check.sh ~/ai-inbox/test/$ID no
echo "Look at the images in VS Code on homi-nas: ~/ai-inbox/test/$ID/"
