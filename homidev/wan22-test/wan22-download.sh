#!/bin/bash
# Wan 2.2 TI2V-5B (Comfy-Org repackage) - download to model-review first, verify sha256
cd ~/model-review/wan2.2 || exit 1
B=https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files
cat > SHA256SUMS <<S
456f901338bd9eadbded3828b819109a9b68e8a525ca5cf8d0049a69fcfeca1e  wan2.2_ti2v_5B_fp16.safetensors
e40321bd36b9709991dae2530eb4ac303dd168276980d3e9bc4b6e2b75fed156  wan2.2_vae.safetensors
c3355d30191f1f066b26d93fba017ae9809dce6c627dda5f6a66eaa651204f68  umt5_xxl_fp8_e4m3fn_scaled.safetensors
S
echo "Source: https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged (split_files), licence apache-2.0 per repo card; original: Wan-AI/Wan2.2-TI2V-5B. Downloaded $(date -I)" > SOURCE.txt
curl -fsSL https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B/resolve/main/LICENSE.txt -o LICENSE.txt || echo "LICENSE fetch failed" >> SOURCE.txt
for p in vae/wan2.2_vae.safetensors text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors diffusion_models/wan2.2_ti2v_5B_fp16.safetensors; do
  f=${p##*/}; echo "== $f $(date +%T)"
  curl -L -C - -sS --retry 5 "$B/$p" -o "$f" || echo "DOWNLOAD FAILED $f"
done
sha256sum -c SHA256SUMS > CHECK.txt 2>&1; cat CHECK.txt; echo "FINISHED $(date +%T)" >> CHECK.txt
