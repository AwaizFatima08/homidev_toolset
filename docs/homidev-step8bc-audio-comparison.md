# homidev Steps 8b + 8c — Sound effects and music models: comparison v0.3 — **P1–P7 LOCKED 6 Oct 2026**

Date: 6 Oct 2026 · Design v1.1, step 8 · Status: **P1–P7 locked by Homi 6 Oct; nothing downloaded yet; next = 8b-1 read-only pre-check**
Limits: RTX 5060 Ti 16 GB VRAM · 16 GB RAM · ComfyUI 0.37.0 (24 Sep) · receiver v0.6.
**Change from v0.1:** the three open risks were checked against primary sources (section 2). Two are resolved, one is narrowed. Decisions renumbered P1–P7.

## 1. Licences (checked 6 Oct 2026, from model pages)

| Model | For | Licence | Commercial use of output | Notes |
|---|---|---|---|---|
| Stable Audio Open 1.0 (Stability, 2024) | SFX, loops | Stability AI **Community Licence** | Yes, **free while revenue < US$1M/year**; you own the output | 1B params; up to 47 s; 44.1 kHz stereo |
| **Stable Audio 3 Small-SFX** (Stability, **20 May 2026**) | SFX, ambience | Community Licence (+ Gemma terms for its text encoder) | Same as above | ~0.45B params; up to 2:00; **44.1 kHz stereo**; licensed training data |
| **Stable Audio 3 Small-Music** (same release; v0.1 called it "Small") | music loops | Community Licence | Same as above | same size, same text encoder, same output format |
| ACE-Step 1.5 (Feb 2026) | music | **Apache 2.0** | Yes; model card asks to check originality and disclose AI use | reserve only |
| YuE | songs with vocals | Apache 2.0 | Yes | ❌ needs ~24 GB VRAM |
| Meta MusicGen | music | CC-BY-NC 4.0 | ❌ **non-commercial** | → Blocked |

## 2. Open risks — findings 6 Oct

| Risk (v0.1) | Finding | Status |
|---|---|---|
| ComfyUI must be updated (torch could change) | Official Comfy blog: Stable Audio 3 needs **ComfyUI v0.22.0**; homidev has **0.37.0** (newer). Code support merged as PR #14010 | **Probably no update needed.** Confirm with a read-only check on homidev before any download |
| Small-SFX outputs only 16 kHz | Stable Audio 3 paper: all models output **stereo 44.1 kHz**; same autoencoder for all | **Resolved — 16 kHz was wrong** |
| File sizes / VRAM unknown | `Comfy-Org/stable-audio-3`: `stable_audio_3_small_sfx.safetensors` **2.27 GB**, `stable_audio_3_small_music.safetensors` **2.27 GB**, text encoder `t5gemma_b_b_ul2.safetensors` **1.19 GB** (shared). Each repo also has a `_base` variant (2.27 GB) | **Resolved.** ~5.7 GB total for both steps; fits 16 GB VRAM easily |
| CC0 packs vs AI for UI sounds | Still a judgement call — see P1 | Open |

New points found:
- **Licence threshold counts the whole organisation's revenue** ("regardless of the source of that revenue") — i.e. HomiLabs as a company.
- **Registration:** the Community Licence FAQ mentions registering with Stability for commercial use. Exact wording to be read and recorded from the full agreement at download time (as in 8a).
- **Text encoder T5Gemma** carries Google's Gemma terms (use-policy rules pass down). Commercial use is allowed; record it in the register like any other file.
- **`_base` vs normal file:** download only the file the official Comfy workflow template uses; the other stays on Hugging Face unless quality fails.

## 3. Recommendation (unchanged, now better supported)
**Stable Audio 3** for both: *Small-SFX* (8b) and *Small-Music* (8c). One licence, one shared text encoder, licensed training data, small files, probably no ComfyUI update.
**Reserve for music:** ACE-Step 1.5 Turbo (Apache 2.0) — only if Small-Music is not good enough.

## 4. Critique of this plan (things still to watch)
1. **Loudness target for SFX is different from voice.** −16 LUFS integrated works for speech, but is meaningless for a 0.2 s tap. The SFX recipe needs its own Stage 1 rule (likely peak-based, e.g. true peak ≤ −1 dB, and a short-sound loudness WARN only). To be designed in 8b, not guessed now.
2. **Stereo:** UI sounds are usually better as mono (smaller files, same sound on phone speakers). Recipe decision in 8b.
3. **Scope creep check:** CC0 packs are *not* in design v1.1. Adding them as a manual source is a small scope change — see P1.
4. Music: instrumental loops only (no vocals).

## 5. Decisions (P1–P7) — LOCKED 6 Oct 2026 by Homi, all as recommended
- **P1** 8b SFX source: **Stable Audio 3 Small-SFX** (recommended). CC0 packs: **not now** — revisit only if a real project needs plain UI taps (would be a design change, recorded separately).
- **P2** 8c music: **Stable Audio 3 Small-Music** (recommended); ACE-Step 1.5 Turbo stays reserve.
- **P3** Community-Licence models recorded as `commercial_ok = yes` with licence text **"Stability AI Community Licence (free while HomiLabs revenue < US$1M/yr)"** + yearly reminder (each October) + registration requirement recorded at download.
- **P4** First sub-step **8b-1 = read-only pre-check** on homidev (ComfyUI version, Stable Audio 3 code present, torch = 2.14.0+cu130, disk, GPU idle). **No ComfyUI update** unless this check fails — an update would get its own plan.
- **P5** Blocked list: add **Meta MusicGen** (CC-BY-NC 4.0).
- **P6** Order: **8b first**, 8c after 8b closes. The shared text encoder is downloaded in 8b.
- **P7** Download only the files the official Comfy workflow uses (no `_base` files, no Medium 9.2 GB).

## Sources
- https://arxiv.org/html/2605.17991v1 (Stable Audio 3 paper: 44.1 kHz stereo, parameter counts)
- https://blog.comfy.org/p/stable-audio-3-day-0-support (ComfyUI v0.22.0)
- https://github.com/Comfy-Org/ComfyUI/actions/runs/26172925119 (PR #14010 "Support Stable Audio 3 model")
- https://huggingface.co/Comfy-Org/stable-audio-3 (file names and sizes)
- https://huggingface.co/stabilityai/stable-audio-3-small-sfx · https://stability.ai/license
- https://stability.ai/news-updates/meet-stable-audio-3-the-model-family-built-for-artistic-experimentation-with-open-weight-models
