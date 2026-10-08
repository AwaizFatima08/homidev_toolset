#!/bin/bash
# ask-homidev.sh "<question>" [model] [--think]   (v1.0, 9 Oct 2026, S6) - ask a local LLM on homidev from homi-nas.
# Offline backup when no online model is available (Homi, 9 Oct). Default model gpt-oss:20b (reasoning high when --think).
# Goes over SSH (Ollama is local-only on homidev). Refuses if the GPU is busy with an asset job. Unloads nothing: Ollama
# drops the model itself after 2 min; the receiver unloads it anyway before any job. Reply printed to stdout; facts to stderr.
set -u
Q="${1:-}"; [ -n "$Q" ] || { echo "usage: ask-homidev.sh \"<question>\" [model] [--think]"; exit 2; }
MODEL="${2:-gpt-oss:20b}"; THINK=false; [ "${3:-}" = "--think" ] || [ "${2:-}" = "--think" ] && THINK=true
[ "$MODEL" = "--think" ] && MODEL=gpt-oss:20b
case "$MODEL" in gpt-oss*) T=$([ $THINK = true ] && echo '"high"' || echo '"low"');; *) T=$THINK;; esac
H=192.168.100.123
BUSY=$(curl -s -m 5 -H "X-Receiver-Token: $(cat ~/.config/asset-receiver/token)" http://$H:8190/health | jq -r '.running // empty')
[ -n "$BUSY" ] && { echo "homidev is running asset job $BUSY - try again later" >&2; exit 1; }
BODY=$(jq -n --arg m "$MODEL" --arg p "$Q" --argjson t "$T" '{model:$m,prompt:$p,stream:false,think:$t,options:{num_predict:4000}}')
R=$(ssh -o BatchMode=yes -o ConnectTimeout=5 homidev@$H "curl -s -m 600 http://127.0.0.1:11434/api/generate -d @-" <<<"$BODY") || { echo "homidev unreachable" >&2; exit 1; }
echo "$R" | jq -r '.response // .error // "no response"'
echo "$R" | jq -r '"[\(.model) · \(.eval_count) tokens · \((.eval_count/(.eval_duration/1e9))|round) tok/s · \(.done_reason)]"' >&2
