#!/bin/bash
cd ~/model-review/lmstudio/qwen3.5-9b || exit 1
U=https://huggingface.co/lmstudio-community/Qwen3.5-9B-GGUF/resolve/main
for f in Qwen3.5-9B-Q4_K_M.gguf mmproj-Qwen3.5-9B-BF16.gguf; do echo "== $f $(date +%T)"; curl -L -C - -sS --retry 5 "$U/$f" -o "$f" || echo "DOWNLOAD FAILED $f"; done
sha256sum -c SHA256SUMS > CHECK.txt 2>&1; cat CHECK.txt
if ! grep -q FAILED CHECK.txt; then export PATH=$HOME/.lmstudio/bin:$PATH; lms import --user-repo lmstudio-community/Qwen3.5-9B-GGUF -y -c Qwen3.5-9B-Q4_K_M.gguf 2>&1 | grep -v Warn | tail -3; lms import --user-repo lmstudio-community/Qwen3.5-9B-GGUF -y -c mmproj-Qwen3.5-9B-BF16.gguf 2>&1 | grep -v Warn | tail -2; lms ls 2>&1 | grep -v Warn | tail -5; fi
echo "FINISHED $(date +%T)" >> CHECK.txt
