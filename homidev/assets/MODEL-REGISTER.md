# homidev Model Register

Every model file installed on homidev is listed here **before** it is used. The receiver copies `licence` and `commercial_ok` from this file into each job's `manifest.json`.

Rules:
- No entry = the model must not be used.
- Licence is checked **at download time** from the exact repository the file came from (repackaged copies can differ from the original).
- `commercial_ok = no` models may be used for tests only; their output never enters a commercial project.
- Blocked models are never downloaded.

## Installed

| Model | File (under `~/ComfyUI/models/`) | Source | Licence | commercial_ok | sha256 | Added | Used for |
|---|---|---|---|---|---|---|---|
| BiRefNet (General, Comfy-Org repackage) | `background_removal/birefnet.safetensors` (424 MB) | https://huggingface.co/Comfy-Org/BiRefNet (original: ZhengPeng7/BiRefNet) | MIT (checked 30 Sep 2026) | **yes** | `9ab37426bf4de0567af6b5d21b16151357149139362e6e8992021b8ce356a154` | 2026-09-30 | Background removal (built-in nodes "Load Background Removal Model" + "Remove Background") |
| Real-ESRGAN x4plus (Comfy-Org repackage) | `upscale_models/RealESRGAN_x4plus.safetensors` (64 MB) | https://huggingface.co/Comfy-Org/Real-ESRGAN_repackaged (original: xinntao/Real-ESRGAN) | BSD-3-Clause (checked 30 Sep 2026) | **yes** | `37f9a931c215f040aa6d50f711f2cb115f713c46df1d0d6469a8bd7bfe9a60bb` | 2026-09-30 | 4× upscaling (built-in nodes "Load Upscale Model" + "Upscale Image (using Model)") |
| Kokoro-82M v1.0 (TTS model) | `~/.cache/huggingface/hub/models--hexgrad--Kokoro-82M/…/kokoro-v1_0.pth` (313 MB) — **.pth, allowed: official source** | https://huggingface.co/hexgrad/Kokoro-82M (snapshot f3ff357) | Apache 2.0 (checked 30 Sep 2026) | **yes** | `496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4` | 2026-09-30 | English voice-overs (`~/voice/tts`, CPU) |
| Kokoro voice `af_heart` | `…/Kokoro-82M/…/voices/af_heart.pt` (512 KB) | same repository | Apache 2.0 | **yes** | `0ab5709b8ffab19bfd849cd11d98f75b60af7733253ad0d67b12382a102cb4ff` | 2026-09-30 | Default English (US, female) voice |
| faster-whisper `small.en` (voice check only, produces no asset) | `~/.cache/huggingface/hub/models--Systran--faster-whisper-small.en/` (folder, ~480 MB) | https://huggingface.co/Systran/faster-whisper-small.en | MIT (checked 30 Sep 2026) | **yes** | (folder — not fingerprinted) | 2026-10-01 | Voice script check (`~/voice/stt`, CPU) |
| spaCy `en_core_web_sm` 3.8.0 | Python package in `~/voice/tts` | https://github.com/explosion/spacy-models (official release) | MIT | **yes** | (pip package) | 2026-09-30 | English text processing for Kokoro |
| SDXL Turbo | `checkpoints/sd_xl_turbo_1.0_fp16.safetensors` (6.5 GB) | https://huggingface.co/stabilityai/sdxl-turbo | Stability AI Non-Commercial Research Community Licence | **no — tests only** | `e869ac7d6942cb327d68d5ed83a40447aadf20e0c3358d98b2cc9e270db0da26` | 2026-09-26 | Pipeline tests only |

## Tools (not models, listed for completeness)

| Tool | Licence | Note |
|---|---|---|
| espeak-ng 1.52 (Debian package) | GPL-3 | Pronunciation helper for Kokoro; a tool — does not affect the licence of generated audio |

Note: Kokoro and faster-whisper models live in the Hugging Face cache (`~/.cache/huggingface/hub`), not under `~/ComfyUI/models/`. Include this folder in the NVMe move.

## Blocked (never download)

| Model | Reason |
|---|---|
| BRIA RMBG-2.0 | CC BY-NC 4.0 — non-commercial |

## Pending (planned, not yet installed)

| Model | Purpose | Licence to verify |
|---|---|---|
| Commercial image model (FLUX.1-schnell / SDXL base / Z-Image) | Image generation | at download |
| Stable Audio Open | Sound effects | Stability AI Community Licence — revenue threshold, record terms |
| ACE-Step | Music | Apache 2.0 expected |
