# homidev Model Register

Every model file installed on homidev is listed here **before** it is used. The receiver copies `licence` and `commercial_ok` from this file into each job's `manifest.json`. Machine copy: `~/assets/models.json` — always update both together.

Rules:
- No entry = the model must not be used.
- Licence is checked **at download time** from the exact repository the file came from (repackaged copies can differ from the original).
- `commercial_ok = no` models may be used for tests only; their output never enters a commercial project.
- Blocked models are never downloaded.
- New model files are downloaded into `~/model-review/<model>/` first, checked (licence + sha256 against the value Hugging Face publishes), entered here, and only then moved into `~/ComfyUI/models/` (agreed 5 Oct 2026).

## Installed

| Model | File (under `~/ComfyUI/models/`) | Source | Licence | commercial_ok | sha256 | Added | Used for |
|---|---|---|---|---|---|---|---|
| Z-Image-Turbo, int8 "convrot" (Comfy-Org repackage) | `diffusion_models/z_image_turbo_int8_convrot.safetensors` (6.2 GB) | https://huggingface.co/Comfy-Org/z_image_turbo, revision `6fc90a3b1b653e935a0d175e260736de25b84df5` (original: Tongyi-MAI/Z-Image-Turbo) | Apache 2.0 (checked 5 Oct 2026, repo card + `licence.txt` on homidev) | **yes** | `be517ebd47c912a5626a588e1aeea43e6be4a43c0cdcd2b48a2a780d9f358635` | 2026-10-05 | Commercial image generation (step 8a) |
| Qwen3-4B text encoder, fp8 mixed (Comfy-Org repackage) | `text_encoders/qwen_3_4b_fp8_mixed.safetensors` (5.6 GB) | same repository and revision (original: Qwen/Qwen3-4B) | Apache 2.0 (checked 5 Oct 2026) | **yes** | `72450b19758172c5a7273cf7de729d1c17e7f434a104a00167624cba94f68f15` | 2026-10-05 | Text encoder for Z-Image-Turbo |
| Z-Image VAE `ae` (Comfy-Org repackage) | `vae/ae.safetensors` (335 MB) | same repository and revision | Apache 2.0 (checked 5 Oct 2026) | **yes** | `afc8e28272cd15db3919bacdb6918ce9c1ed22e96cb12c4d5ed0fba823529e38` | 2026-10-05 | VAE for Z-Image-Turbo |
| BiRefNet (General, Comfy-Org repackage) | `background_removal/birefnet.safetensors` (424 MB) | https://huggingface.co/Comfy-Org/BiRefNet (original: ZhengPeng7/BiRefNet) | MIT (checked 30 Sep 2026) | **yes** | `9ab37426bf4de0567af6b5d21b16151357149139362e6e8992021b8ce356a154` | 2026-09-30 | Background removal (built-in nodes "Load Background Removal Model" + "Remove Background") |
| Real-ESRGAN x4plus (Comfy-Org repackage) | `upscale_models/RealESRGAN_x4plus.safetensors` (64 MB) | https://huggingface.co/Comfy-Org/Real-ESRGAN_repackaged (original: xinntao/Real-ESRGAN) | BSD-3-Clause (checked 30 Sep 2026) | **yes** | `37f9a931c215f040aa6d50f711f2cb115f713c46df1d0d6469a8bd7bfe9a60bb` | 2026-09-30 | 4× upscaling (built-in nodes "Load Upscale Model" + "Upscale Image (using Model)") |
| Kokoro-82M v1.0 (TTS model) | `~/.cache/huggingface/hub/models--hexgrad--Kokoro-82M/…/kokoro-v1_0.pth` (313 MB) — **.pth, allowed: official source** | https://huggingface.co/hexgrad/Kokoro-82M (snapshot f3ff357) | Apache 2.0 (checked 30 Sep 2026) | **yes** | `496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4` | 2026-09-30 | English voice-overs (`~/voice/tts`, CPU) |
| Kokoro voice `af_heart` | `…/Kokoro-82M/…/voices/af_heart.pt` (512 KB) | same repository | Apache 2.0 | **yes** | `0ab5709b8ffab19bfd849cd11d98f75b60af7733253ad0d67b12382a102cb4ff` | 2026-09-30 | Default English (US, female) voice |
| faster-whisper `small.en` (voice check only, produces no asset) | `~/.cache/huggingface/hub/models--Systran--faster-whisper-small.en/` (folder, ~480 MB) | https://huggingface.co/Systran/faster-whisper-small.en | MIT (checked 30 Sep 2026) | **yes** | (folder — not fingerprinted) | 2026-10-01 | Voice script check (`~/voice/stt`, CPU) |
| spaCy `en_core_web_sm` 3.8.0 | Python package in `~/voice/tts` | https://github.com/explosion/spacy-models (official release) | MIT | **yes** | (pip package) | 2026-09-30 | English text processing for Kokoro |
| Stable Audio 3 Small-SFX (Comfy-Org repackage) | `checkpoints/stable_audio_3_small_sfx.safetensors` (2.27 GB) | https://huggingface.co/Comfy-Org/stable-audio-3, revision `96fc663283cde94cb631bc84f6c9ece7bbe2bf25` (original: stabilityai/stable-audio-3-small-sfx) | Stability AI Community Licence, 5 Jul 2024 (checked 6 Oct 2026; `LICENSE.md` in `~/model-review/stable-audio-3/`): free while HomiLabs revenue < US$1M/yr · **registered with Stability 2026-10-06 (company: HomiLabs Solutions SMC Pvt Ltd; contact: Humayun Shahzad)** · apps using its sounds show "Powered by Stability AI" · re-check every October | **yes (conditions)** | `ed9cf1b6172f1a8c2921a9560c21109ff3239524563ced9dce6dcdef41e2f515` | 2026-10-06 | Sound effects (step 8b) |
| Stable Audio 3 Small-Music (Comfy-Org repackage) | `checkpoints/stable_audio_3_small_music.safetensors` (2.27 GB) | https://huggingface.co/Comfy-Org/stable-audio-3, revision `96fc663283cde94cb631bc84f6c9ece7bbe2bf25` (original: stabilityai/stable-audio-3-small-music) | Stability AI Community Licence, 5 Jul 2024 — **byte-identical to the Small-SFX licence** (checked 7 Oct 2026; `LICENSE.md` in `~/model-review/stable-audio-3/small-music/`): same conditions and the same 2026-10-06 registration · apps using its music show "Powered by Stability AI" · re-check every October | **yes (conditions)** | `da85866b11b01d0694d990785f6abbd79c8064df1b0e6f8aea52935e0ef84b64` | 2026-10-07 | Music loops (step 8c) |
| T5Gemma b-b UL2 text encoder (Comfy-Org repackage) | `text_encoders/t5gemma_b_b_ul2.safetensors` (1.19 GB) | same repository and revision (original: google/t5gemma-b-b-ul2) | Gemma Terms of Use (checked 6 Oct 2026) | **yes** | `1e1eba25be8872edb0d3c6335c6658fd6388e7b14b60da6e454e404cfcd8150e` | 2026-10-06 | Text encoder for all Stable Audio 3 models (8b + 8c) |
| SDXL Turbo | `checkpoints/sd_xl_turbo_1.0_fp16.safetensors` (6.5 GB) | https://huggingface.co/stabilityai/sdxl-turbo | Stability AI Non-Commercial Research Community Licence | **no — tests only** | `e869ac7d6942cb327d68d5ed83a40447aadf20e0c3358d98b2cc9e270db0da26` | 2026-09-26 | Pipeline tests only |
| Wan 2.2 TI2V-5B (Comfy-Org repackage) | `diffusion_models/wan2.2_ti2v_5B_fp16.safetensors` (10.0 GB) | https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged (split_files; original: Wan-AI/Wan2.2-TI2V-5B) | Apache 2.0 (HF card + `LICENSE.txt` from github.com/Wan-Video/Wan2.2, kept in `~/model-review/wan2.2/`) | **yes** | `456f901338bd9eadbded3828b819109a9b68e8a525ca5cf8d0049a69fcfeca1e` | 2026-10-08 | Video test (step 12, S12-4) — **no recipe yet; tests only until Homi approves video** |
| Wan 2.2 VAE | `vae/wan2.2_vae.safetensors` (1.41 GB) | same repository | Apache 2.0 | **yes** | `e40321bd36b9709991dae2530eb4ac303dd168276980d3e9bc4b6e2b75fed156` | 2026-10-08 | VAE for Wan 2.2 5B |
| UMT5-XXL fp8 text encoder (Comfy-Org repackage) | `text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors` (6.74 GB) | same repository (original: google/umt5-xxl) | Apache 2.0 | **yes** | `c3355d30191f1f066b26d93fba017ae9809dce6c627dda5f6a66eaa651204f68` | 2026-10-08 | Text encoder for Wan 2.2 |

Z-Image-Turbo uses all three Z-Image files together; all are Apache 2.0, so a job using them is `commercial_ok = yes` (strictest-licence rule still applies when combined with other models).

Stable Audio 3 Small-SFX and Small-Music each use their checkpoint + the T5Gemma text encoder → a sound-effects or music job's licence is "Stability AI Community Licence + Gemma terms" (strictest-licence rule). Commercial use depends on the Community Licence conditions (revenue < US$1M/yr, registration, attribution) — re-check every October.

## Tools (not models, listed for completeness)

| Tool | Licence | Note |
|---|---|---|
| espeak-ng 1.52 (Debian package) | GPL-3 | Pronunciation helper for Kokoro; a tool — does not affect the licence of generated audio |

Note: Kokoro and faster-whisper models live in the Hugging Face cache (`~/.cache/huggingface/hub`), not under `~/ComfyUI/models/`.

## Blocked (never download)

| Model | Reason |
|---|---|
| BRIA RMBG-2.0 | CC BY-NC 4.0 — non-commercial |
| FLUX.2 [klein] **9B** | Non-commercial licence (the **4B** is Apache 2.0 — do not confuse) — added 5 Oct 2026 |
| FLUX.2 [dev] | FLUX non-commercial licence — added 5 Oct 2026 |
| FLUX.1 [dev] | FLUX.1 [dev] non-commercial licence — added 5 Oct 2026 |
| Meta MusicGen | CC-BY-NC 4.0 — non-commercial — added 6 Oct 2026 |

## Pending (planned, not yet installed)

| Model | Purpose | Licence to verify |
|---|---|---|
| (reserve) ACE-Step 1.5 Turbo | Music — only if Small-Music falls short | Apache 2.0 |
| (reserve) FLUX.2 [klein] 4B | Image editing / reference-based icon sets — only if Z-Image-Turbo falls short | Apache 2.0 (checked 5 Oct 2026) |
