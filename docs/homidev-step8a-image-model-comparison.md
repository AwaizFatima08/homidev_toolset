# homidev Step 8a — Commercial Image Model: Comparison (DRAFT for Homi's decision)

Date: 5 Oct 2026 · Design v1.1, step 8 · Status: **D1–D6 LOCKED 5 Oct 2026 (Homi) — see section 7. Nothing downloaded yet.**
Limits: RTX 5060 Ti **16 GB VRAM** · **16 GB system RAM** (the tighter limit) · 32 GiB swap on the 970 · Ollama gpt-oss also uses ~12 GB VRAM when loaded.

## 1. Licences checked today (5 Oct 2026, from the original repositories)

| Model | Licence (source page) | Commercial use of images | Notes |
|---|---|---|---|
| FLUX.1-schnell (Black Forest Labs) | Apache 2.0 | Yes | Repo is gated (share contact info to download) |
| SDXL base 1.0 (Stability AI) | CreativeML Open RAIL++-M | Yes, Stability "claims no rights in the Output" | Use restrictions (no harmful/deceptive use, **no "medical advice or interpretation"**) |
| Z-Image-Turbo (Alibaba Tongyi-MAI) | Apache 2.0 | Yes | Released Nov 2025. Comfy-Org repackage also states Apache 2.0 |
| FLUX.2 [klein] **4B** (Black Forest Labs) | Apache 2.0 | Yes | ⚠️ Its sister **klein 9B is NON-commercial** — similar name, different licence |
| Qwen-Image (Alibaba) | Apache 2.0 | Yes | 20B parameters (too big, see below) |

## 2. Size and fit on homidev

| Model | Parameters | Files you'd download (ComfyUI versions) | Fits 16 GB VRAM? | Fits 16 GB RAM? |
|---|---|---|---|---|
| FLUX.1-schnell | 12B | all-in-one 23.8 GB, or fp8 17.2 GB | Only fp8, barely | ❌ larger than RAM → heavy swapping |
| SDXL base | 3.5B | ~6.9 GB | ✅ easily | ✅ easily |
| **Z-Image-Turbo** | 6B | model 12.3 GB (bf16) or 6.2 GB (int8) + text encoder Qwen3-4B 8.0 GB or 5.6 GB (fp8) + small VAE | ✅ (smaller versions comfortably) | ✅ with int8 + fp8 (~12 GB); bf16 + full encoder (~20 GB) would lean on swap |
| **FLUX.2 klein 4B** | 4B | model 7.75 GB + text encoder Qwen3-4B 8.0 GB (or 3.8 GB fp4) | ✅ (~13 GB stated) | ✅ |
| Qwen-Image | 20B | 20.4 GB (fp8) + 7B text encoder | ❌ | ❌ → **excluded** |

Note: Z-Image and klein 4B use the same text encoder family (Qwen3-4B, identical file size 8,044,982,048 bytes). If the sha256 matches at download, both models could share one file.

## 3. Quality for app images and icons (from published reviews — not yet tested by us)

| Model | Strengths | Weaknesses |
|---|---|---|
| FLUX.1-schnell | Good general quality | Aug 2024, now outclassed; too big for 16 GB RAM |
| SDXL base | Huge add-on (LoRA) library, small, well known | Oldest; needs 25–40 steps; weak at text in images; more cleanup per image |
| **Z-Image-Turbo** | Strong photoreal + illustration; good English text in images; 8–9 steps; reviewed as close to FLUX quality at far less compute | Newer, fewer LoRAs; SDXL LoRAs don't work |
| **FLUX.2 klein 4B** | Smallest modern option; 4 steps; also **edits images and takes reference images** (useful for matching icon sets) | Smaller model → likely somewhat less detail than Z-Image; quality claims not yet verified by us |

## 4. Recommendation

**Primary: Z-Image-Turbo** (int8 model + fp8 text encoder, ~12 GB total), Apache 2.0, from the Comfy-Org repackage with licence re-checked at download.
Reasons: clean licence, fits RAM and VRAM, best quality-for-size of the candidates, handles text inside images.

**Runner-up: FLUX.2 klein 4B** — choose it instead if consistent icon *sets* (editing from a reference) matter more than raw image quality.

**Drop:** FLUX.1-schnell (too big, outdated), Qwen-Image (too big). **SDXL base:** only if we later need its LoRA library.

## 5. Risks / points to verify at download

1. The int8 "convrot" file is a newer ComfyUI format — confirm our ComfyUI loads it. If not, fall back to bf16 model + fp8 encoder and accept some swap use.
2. Ollama and ComfyUI share the GPU. An image job while gpt-oss is loaded (~12 GB) will not fit → the receiver should check/unload Ollama before image jobs (same idea as the existing `POST /free` rule).
3. Licence for the **exact files** (Comfy-Org repackage) re-checked and recorded in MODEL-REGISTER.md with sha256 before first use.

## 6. Decisions for Homi (nothing downloaded until these are confirmed)

- **D1** Model: Z-Image-Turbo / FLUX.2 klein 4B / both for a small test (see D4)?
- **D2** Files: int8 model + fp8 text encoder (~12 GB)?
- **D3** Source: Comfy-Org repackage on Hugging Face, licence + sha256 recorded at download?
- **D4** Bake-off: test only the chosen model (simplest), or both on the same 5 prompts (+~12 GB, one extra session)?
- **D5** Add to MODEL-REGISTER "Blocked": FLUX.2 klein 9B, FLUX.2 dev, FLUX.1 dev (all non-commercial)?
- **D6** Receiver rule: unload Ollama before every image job?

## 7. LOCKED decisions (Homi, 5 Oct 2026)

- **D1** Model = **Z-Image-Turbo** (FLUX.2 klein 4B is the reserve, not installed).
- **D2** Files (from `Comfy-Org/z_image_turbo`, ~12.2 GB total):
  - `diffusion_models/z_image_turbo_int8_convrot.safetensors` (6,201,001,296 bytes)
  - `text_encoders/qwen_3_4b_fp8_mixed.safetensors` (5,631,994,051 bytes)
  - `vae/ae.safetensors` (335,304,388 bytes)
  - Fallback only if int8 won't load: `z_image_turbo_bf16.safetensors` (12.3 GB) — needs a new OK from Homi.
- **D3** Source = Comfy-Org repackage; licence (Apache 2.0) re-read on the day of download; each file's sha256 compared with the value Hugging Face publishes, then recorded in MODEL-REGISTER.md **before** first use.
- **D4** Test only Z-Image-Turbo (no bake-off): 5 fixed test prompts, Stage 1 + Homi's Stage 2 review.
- **D5** MODEL-REGISTER "Blocked": FLUX.2 klein 9B, FLUX.2 dev, FLUX.1 dev (non-commercial).
- **D6** Receiver: before every image job, unload Ollama models (receiver change = its own sub-step, tested separately).

### Sub-steps (one at a time, each verified before the next)
| # | What | Changes anything? |
|---|---|---|
| 8a-1 | Pre-checks: ComfyUI version supports Z-Image + int8, disk, RAM/VRAM | No (read-only) |
| 8a-2 | Download 3 files + sha256 check against Hugging Face | Adds ~12.2 GB |
| 8a-3 | MODEL-REGISTER: 3 entries + blocked list (D5); `models.json` entry | Docs/config |
| 8a-4 | First manual test image, job sent from homi-nas via API | No |
| 8a-5 | Receiver v0.6: Ollama unload before image jobs (D6) + test | Receiver code |
| 8a-6 | 5-prompt quality test, Stage 1 + Stage 2 → step 8a closed | No |

Not in 8a (flagged to avoid scope creep): recipe `app-icon-flat` (step 11), removing SDXL Turbo, Stable Audio Open / ACE-Step (8b/8c).

## Sources
- https://huggingface.co/black-forest-labs/FLUX.1-schnell
- https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0 (LICENSE.md)
- https://huggingface.co/Tongyi-MAI/Z-Image-Turbo
- https://huggingface.co/black-forest-labs/FLUX.2-klein-4B
- https://huggingface.co/Comfy-Org/z_image_turbo · https://huggingface.co/Comfy-Org/flux2-klein-4B · https://huggingface.co/Comfy-Org/flux1-schnell (file sizes)
- https://docs.comfy.org/tutorials/image/qwen/qwen-image
- https://www.thundercompute.com/blog/z-image-turbo-comfyui
- https://www.bentoml.com/blog/a-guide-to-open-source-image-generation-models
