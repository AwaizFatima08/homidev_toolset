#!/bin/bash
# run-llm-test-v2.sh v2.0 (8 Oct 2026) — Step 12 / L4: fair "deep thinking" comparison
# gpt-oss:20b (reasoning high) vs qwen3.5:9b (thinking on) vs deepseek-r1:14b / :8b (always think)
# Same prompts via the Ollama API; records speed, GPU memory, fits/spills. Homi judges quality.
# Usage: run-llm-test-v2.sh [model ...]   (default: all four)
set -u
OUT="$HOME/llm-test/results-$(date +%Y%m%d-%H%M)"; mkdir -p "$OUT"
API=http://127.0.0.1:11434/api
MODELS="${*:-gpt-oss:20b qwen3.5:9b deepseek-r1:14b deepseek-r1:8b}"
NUM_PREDICT=8000   # lesson 5 Oct: thinking models need >= 6000 tokens

# Guard (G3 + L2): nothing else may hold the GPU — ComfyUI job, Ollama or LM Studio model
USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1)
if [ "$USED" -gt 1500 ]; then echo "STOP: GPU already uses ${USED} MiB (job running or model loaded?)"; exit 1; fi
if command -v lms >/dev/null 2>&1 || [ -x "$HOME/.lmstudio/bin/lms" ]; then
  LMS_PS=$("$HOME/.lmstudio/bin/lms" ps 2>/dev/null | grep -vc "No models" || true)
  [ "$LMS_PS" -gt 1 ] && { echo "STOP: LM Studio has a model loaded — run: lms unload --all"; exit 1; }
fi

P1='A clinic sees one patient every 12 minutes, starting at 08:00. Each visit must finish before a break at 10:30. After a 20-minute break the clinic restarts and must finish all visits by 13:00. What is the maximum number of patients seen? Explain briefly.'
P2='A medicine is given as 5 mg per kg of body weight per day, split into 3 equal doses. The tablets are 125 mg and may be halved but not quartered. For a child weighing 27 kg, what is the closest practical dose per intake, and how far (in percent) is it from the exact dose? Show your working.'
P3='You have 3 boxes. One has two gold coins, one has two silver coins, one has one of each. You pick a box at random and draw one coin: it is gold. What is the probability the other coin in that box is also gold? Explain step by step, then state the answer as a fraction.'
P4='Write in Urdu (Urdu script, not Roman Urdu) a 5-sentence notice for factory workers about drinking enough water and recognising heat exhaustion during summer.'
P5='Write a Flutter/Dart function that takes a list of medication times (as "HH:mm" strings) and returns the next time after a given "now" time, wrapping to the next day if needed. Include a short test. Keep it under 60 lines.'

printf "model\tprompt\tseconds_total\tload_s\tthink_tokens\tanswer_tokens\ttokens_per_s\tgpu_mib\tplacement\n" > "$OUT/summary.tsv"

think_opt() {  # how to switch "deep thinking" on for each model
  case "$1" in
    gpt-oss*)  echo '"high"' ;;   # low / medium / high
    *)         echo 'true' ;;     # qwen3.5 (default on), deepseek-r1 (always)
  esac
}

ask() {  # model, id, prompt
  local body r f gpu place
  body=$(jq -n --arg m "$1" --arg p "$3" --argjson t "$(think_opt "$1")" \
    '{model:$m,prompt:$p,stream:false,think:$t,options:{num_predict:'"$NUM_PREDICT"'}}')
  # fire request in background, sample GPU memory and placement while it runs
  curl -s -m 1800 "$API/generate" -d "$body" > "$OUT/.resp.json" &
  local pid=$!; gpu=0; place="?"
  while kill -0 $pid 2>/dev/null; do
    sleep 5
    local u; u=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1)
    [ "$u" -gt "$gpu" ] && gpu=$u
    local p; p=$(curl -s "$API/ps" | jq -r --arg m "$1" '.models[]|select(.name==$m)|"\(.size_vram)/\(.size)"' 2>/dev/null)
    [ -n "$p" ] && place="$p"
  done
  r=$(cat "$OUT/.resp.json")
  # placement: 100% GPU if size_vram == size, else "spills"
  case "$place" in
    "?") ;;
    *) local sv s; sv=${place%/*}; s=${place#*/}
       if [ "$sv" = "$s" ]; then place="fits GPU"; else place="SPILLS to RAM ($(( (s-sv)/1048576 )) MiB)"; fi ;;
  esac
  f="$OUT/${1//[:\/]/_}_$2.md"
  { echo "# $1 — $2"; echo; echo "## Prompt"; echo "$3"; echo
    echo "## Thinking"; echo "$r" | jq -r '.thinking // "(none shown)"'; echo
    echo "## Answer"; echo "$r" | jq -r '.response // .error // "NO RESPONSE"'
    echo; echo "## Facts"; echo "done_reason: $(echo "$r" | jq -r '.done_reason // "?"')  peak GPU: ${gpu} MiB  placement: $place"; } > "$f"
  local think_tok; think_tok=$(echo "$r" | jq -r '(.thinking // "") | length' 2>/dev/null)
  echo "$r" | jq -r --arg m "$1" --arg id "$2" --arg g "$gpu" --arg pl "$place" --arg tt "${think_tok:-0}" \
    '[$m,$id,(.total_duration/1e9|.*10|round/10),(.load_duration/1e9|.*10|round/10),($tt+" chars"),.eval_count,(.eval_count/(.eval_duration/1e9)|.*10|round/10),$g,$pl]|@tsv' \
    >> "$OUT/summary.tsv" 2>/dev/null || echo -e "$1\t$2\tERROR" >> "$OUT/summary.tsv"
  echo "  done: $1 $2 ($(echo "$r" | jq -r '.done_reason // "?"'), peak ${gpu} MiB, $place)"
}

for m in $MODELS; do
  echo "== $m"
  ask "$m" 1-schedule "$P1"
  ask "$m" 2-dose     "$P2"
  ask "$m" 3-coins    "$P3"
  ask "$m" 4-urdu     "$P4"
  ask "$m" 5-dart     "$P5"
  curl -s "$API/generate" -d "{\"model\":\"$m\",\"keep_alive\":0}" > /dev/null   # unload before next model
  sleep 5
done
rm -f "$OUT/.resp.json"
echo; column -t -s $'\t' "$OUT/summary.tsv"; echo; echo "Answers in: $OUT"
echo "Expected answers: 1 = 22 patients; 2 = exact 45 mg per intake, only whole/half tablets possible → 62.5 mg (half tablet), +38.9 %; 3 = 2/3"
