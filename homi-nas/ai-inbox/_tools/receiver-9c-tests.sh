#!/usr/bin/env bash
# receiver-9c-tests.sh - run on homi-nas. Sends 1 good + 9 bad job requests to the receiver (v0.3).
# Validation only: nothing is created or run on homidev.
T=$(cat ~/.config/asset-receiver/token)
URL=http://192.168.100.123:8190/jobs
ID="$(date +%Y%m%d-%H%M)-test-image-01"

send() {  # $1 = label, $2 = JSON body, $3 = token (optional override)
  local tok="${3-$T}"
  code=$(curl -s -o /tmp/r9c.json -w "%{http_code}" -X POST "$URL" \
         -H "Content-Type: application/json" -H "X-Receiver-Token: $tok" -d "$2")
  printf "%-34s -> %s  %s\n" "$1" "$code" "$(jq -c '.detail // .state' /tmp/r9c.json 2>/dev/null | cut -c1-140)"
}

GOOD='{"job_id":"'$ID'","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"a red apple"}}'

send "1  good request (expect 200 valid)"  "$GOOD"
send "2  no token (401)"                   "$GOOD" ""
send "3  bad job_id format (422)"          '{"job_id":"apple-1","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"a red apple"}}'
send "4  impossible date (422)"            '{"job_id":"20261345-2599-test-image-01","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"a red apple"}}'
send "5  job_id already used (409)"        '{"job_id":"20260930-2303-test-image-01","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"a red apple"}}'
send "6  unknown recipe (422)"             '{"job_id":"'$ID'","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"magic-recipe","inputs":{"prompt":"a red apple"}}'
send "7  missing prompt (422)"             '{"job_id":"'$ID'","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{}}'
send "8  unknown input key (422)"          '{"job_id":"'$ID'","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"x","steps":50}}'
send "9  seed not a number (422)"          '{"job_id":"'$ID'","project":"test","commercial":"no","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"x","seed":"abc"}}'
send "10 LICENCE GATE commercial (422)"    '{"job_id":"'$ID'","project":"test","commercial":"yes","requested_by":"homi-nas","asset_type":"image","recipe":"test-image-cutout","inputs":{"prompt":"a red apple"}}'
