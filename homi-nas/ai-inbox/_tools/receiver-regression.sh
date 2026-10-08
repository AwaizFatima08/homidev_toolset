#!/bin/bash
# receiver-regression.sh v1.0 (9 Oct 2026, S1) - five "golden" jobs through the real pipeline after any receiver/recipe change.
# Usage: receiver-regression.sh --baseline   first run: records fingerprints + facts in ~/ai-inbox/_regression/golden.json
#        receiver-regression.sh              later runs: same inputs, compares every file sha256 + key facts with the golden
# Jobs land in project "regress" (~/ai-inbox/regress/...), never in a real project. Exit 0 = all match, 1 = differences, 3 = could not run.
set -u
TOOLS="$HOME/ai-inbox/_tools"; BASE="$HOME/ai-inbox/_regression"; GOLD="$BASE/golden.json"
MODE=compare; [ "${1:-}" = "--baseline" ] && MODE=baseline
mkdir -p "$BASE/inputs"
# fixed inputs (seeds fixed so ComfyUI output is reproducible on the same GPU; voice is CPU-deterministic)
cat > "$BASE/inputs/image.json"  <<'EOF'
{"prompt":"Flat vector illustration of a single orange carrot with green leaves, centered, plain white background, no text, no frame","seed":77001}
EOF
cat > "$BASE/inputs/icon.json"   <<'EOF'
{"prompt":"Flat app icon: a solid blue bell, solid filled shapes, no outlines, centered, empty space around, on a plain single-colour light grey background, no frame, no border, no text, no shadow","seed":77002}
EOF
cat > "$BASE/inputs/voice.json"  <<'EOF'
{"script":"Welcome to HomiLabs. This is the regression voice check.","glossary":"HomiLabs"}
EOF
cat > "$BASE/inputs/sfx.json"    <<'EOF'
{"prompt":"Single soft button tap, short plastic click, close-up, dry, no reverb. Length: 1 seconds","seconds":2,"seed":77003}
EOF
cat > "$BASE/inputs/music.json"  <<'EOF'
{"prompt":"Calm app menu background music, soft piano and warm pads, gentle and friendly","bpm":90,"seconds":30,"seed":77004}
EOF
declare -A RECIPE=([image]=image-zimage-basic [icon]=icon-cutout-basic [voice]=voice-en-standard [sfx]=sfx-ui-basic [music]=music-loop-basic)
ORDER="image icon voice sfx music"

facts() {  # job folder -> one JSON object of the things that must stay the same
  # ComfyUI outputs (image, icon, sfx, music) are bit-identical for the same seed -> sha256 compared.
  # Kokoro voice on the CPU is NOT bit-exact (seen 9 Oct: 28 bytes, 0.1 LU apart) -> voice compared by
  # rounded loudness/peak (0.5 dB), length (0.5 s) and the whisper result instead of a fingerprint.
  jq -c 'def r(x;s): if x==null then null else ((x/s)|round)*s end;
         if .asset_type=="voice" then
           {files:[.files[]|{name:(.name|sub("^[0-9]{8}-[0-9]{4}-regress-[a-z]+-[0-9]{2}";"JOB")),format,channels,sample_rate,
                            duration_sec,loudness_lufs,true_peak_db}],
            post:(.postprocess|if .==null then null else {type,limiter_db,gain_db} end),
            check:(.script_check.result // null), receiver:.receiver_version, recipe_version:.recipe_version, tolerant:true}
         else
         {files:[.files[]|{name:(.name|sub("^[0-9]{8}-[0-9]{4}-regress-[a-z]+-[0-9]{2}";"JOB")),sha256,size,width,height,duration_sec,channels,sample_rate,loudness_lufs,true_peak_db}],
          post:(.postprocess|if .==null then null else del(.input_lufs,.gain_db,.rounds,.loudness_lufs,.true_peak_db)+{gain_db:(.gain_db|if .==null then null else (.*2|round/2) end)} end),
          check:(.script_check.result // null), receiver:.receiver_version, recipe_version:.recipe_version}
         end' "$1/manifest.json"
}

# keep the inbox tidy: only the 2 newest regress jobs per kind stay on homi-nas (homidev keeps its copies 14 days)
for k in $ORDER; do ls -d "$HOME/ai-inbox/regress/"*-regress-$k-* 2>/dev/null | sort | head -n -2 | xargs -r rm -rf; done
RESULT=0; NEW="{}"
for k in $ORDER; do
  echo "== $k (${RECIPE[$k]})"
  OUT=$("$TOOLS/asset-job.sh" regress "${RECIPE[$k]}" yes "$BASE/inputs/$k.json" 2>&1); RC=$?
  LAST=$(echo "$OUT" | tail -n1); echo "   $LAST"
  if [ $RC -ne 0 ]; then
    [ $RC -eq 3 ] && { echo "RESULT: FAIL could not run ($LAST)"; exit 3; }
    echo "   FAIL job did not pass"; RESULT=1; continue
  fi
  JOB=$(echo "$LAST" | awk '{print $NF}')
  F=$(facts "$JOB")
  NEW=$(echo "$NEW" | jq --arg k "$k" --argjson f "$F" '.[$k]=$f')
  if [ "$MODE" = compare ] && [ -f "$GOLD" ]; then
    G=$(jq -c --arg k "$k" '.[$k]' "$GOLD")
    SAME=$([ "$G" = "$F" ] && echo yes || echo no)
    if [ "$SAME" = no ] && [ "$(echo "$F" | jq -r '.tolerant // false')" = true ]; then
      # voice: every number within tolerance (loudness/peak 0.5 dB, length 0.2 s, gain 0.5 dB), everything else equal
      SAME=$(jq -n --argjson g "$G" --argjson f "$F" '
        def near(a;b;t): (a==null and b==null) or (a!=null and b!=null and ((a-b)|fabs) <= t);
        ($g.files|length)==($f.files|length) and
        ([range(0;$g.files|length)] | all(. as $i | ($g.files[$i]) as $a | ($f.files[$i]) as $b |
           $a.name==$b.name and $a.format==$b.format and $a.channels==$b.channels and $a.sample_rate==$b.sample_rate and
           near($a.duration_sec;$b.duration_sec;0.2) and near($a.loudness_lufs;$b.loudness_lufs;0.5) and near($a.true_peak_db;$b.true_peak_db;0.5))) and
        $g.post.type==$f.post.type and $g.post.limiter_db==$f.post.limiter_db and near($g.post.gain_db;$f.post.gain_db;0.5) and
        $g.check==$f.check and $g.receiver==$f.receiver and $g.recipe_version==$f.recipe_version' | sed 's/true/yes/;s/false/no/')
      [ "$SAME" = yes ] && echo "   PASS within tolerance of golden (voice is not bit-exact)"
    elif [ "$SAME" = yes ]; then echo "   PASS identical to golden"
    fi
    if [ "$SAME" = no ]; then
      RESULT=1; echo "   DIFF from golden:"
      diff <(echo "$G" | jq -S . ) <(echo "$F" | jq -S .) | grep -E '^[<>]' | head -20 | sed 's/^/     /'
    fi
  fi
done
if [ "$MODE" = baseline ]; then
  echo "$NEW" | jq --arg d "$(date -Is)" --arg r "$(curl -s -m 5 -H "X-Receiver-Token: $(cat ~/.config/asset-receiver/token)" http://192.168.100.123:8190/health | jq -r .receiver)" '. + {_recorded:$d,_receiver:$r}' > "$GOLD"
  echo "RESULT: BASELINE recorded in $GOLD ($(jq -r ._receiver "$GOLD"))"; exit 0
fi
[ -f "$GOLD" ] || { echo "RESULT: FAIL no golden.json - run with --baseline first"; exit 3; }
[ $RESULT -eq 0 ] && echo "RESULT: PASS all 5 golden jobs identical (golden from $(jq -r ._recorded "$GOLD"), $(jq -r ._receiver "$GOLD"))" || echo "RESULT: DIFFERENCES found - see above (expected after an intended change: re-run with --baseline)"
exit $RESULT
