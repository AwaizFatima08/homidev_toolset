# homidev Steps 8b + 8c — Sound effects and music models: comparison (DRAFT for Homi's decision)

Date: 6 Oct 2026 · Design v1.1, step 8 · Status: **nothing downloaded; awaiting Homi's choice**
Limits: RTX 5060 Ti 16 GB VRAM · 16 GB RAM · ComfyUI 0.37.0 (24 Sep) · receiver v0.6.
Design v1.1 planned *Stable Audio Open* (SFX) and *ACE-Step* (music). Both have newer versions now, so they are compared again here.

## 1. Licences checked today (6 Oct 2026, from model pages)

| Model | For | Licence | Commercial use of output | Notes |
|---|---|---|---|---|
| Stable Audio Open 1.0 (Stability, 2024) | SFX, loops | Stability AI **Community Licence** | Yes, **free while revenue < US$1M/year**; you own the output | gated; 1B params; up to 47 s; 44.1 kHz stereo; trained on Freesound/FMA (CC0, CC-BY, CC Sampling+) |
| **Stable Audio 3 Small-SFX** (Stability, released 20 May — year to confirm) | SFX, ambience | Community Licence (+ Gemma terms for its text encoder) | Same as above | gated; 0.6B params; can run on CPU; trained on **licensed** data (AudioSparx) + Freesound; ComfyUI workflow exists (needs a newer ComfyUI) |
| **Stable Audio 3 Small** (music) | short music loops (≤ 2 min) | Community Licence | Same as above | same family, same text encoder, licensed training data |
| ACE-Step v1 3.5B (2025) | music (instrumental + vocals) | **Apache 2.0** | Yes; model card asks to check originality and disclose AI use | ComfyUI native support |
| **ACE-Step 1.5** (Feb 2026, Turbo / XL variants) | music | **Apache 2.0** | Yes (same notes) | newer, faster "Turbo"; Comfy-Org files exist; training-data licensing not stated |
| YuE | songs with vocals | Apache 2.0 | Yes | ❌ needs ~24 GB VRAM — too big |
| Meta MusicGen | music | CC-BY-NC 4.0 | ❌ **non-commercial** | → add to Blocked |

## 2. Important licence point — Community Licence ≠ Apache
- Free for HomiLabs **while yearly revenue stays under US$1M**; above that an Enterprise Licence is needed.
- Our licence gate is yes/no. Proposal: record these as `commercial_ok = yes` with licence text **"Stability AI Community Licence (free < US$1M revenue)"**, plus a yearly reminder to re-check.

## 3. Recommendation
**One family for both: Stable Audio 3** — *Small-SFX* for 8b, *Small* for 8c.
Reasons: one licence, one text encoder, one ComfyUI update, **licensed training data** (lower copyright risk for commercial apps), small models (fit easily in 16 GB).
**Reserve for music:** ACE-Step 1.5 Turbo (Apache 2.0, better/longer music, vocals) — only if Stable Audio 3 Small music is not good enough.

## 4. Critique / risks (to verify before any download)
1. **ComfyUI must be updated** for Stable Audio 3 (docs say "latest/nightly"). Updating ComfyUI can change PyTorch → needs its own small plan + `torch = 2.14.0+cu130` check + full image/voice re-test. This is the biggest risk in 8b/8c.
2. **Sample rate:** one page suggests Small-SFX outputs 16 kHz — too low for good sound effects. Must be confirmed; if true, Stable Audio Open 1.0 (44.1 kHz) is the SFX fallback.
3. File sizes and VRAM not yet confirmed — checked from Hugging Face at download time (as in 8a).
4. **Do we need AI for UI sounds at all?** Taps, chimes and success sounds are often better from free **CC0 sound packs** (e.g. Kenney, Freesound CC0) — no model, no licence threshold. AI SFX are most useful for unusual or story sounds (games, kids' apps). Worth deciding before building 8b.
5. Music: instrumental loops only for apps (no vocals) — fewer copyright and quality problems.
6. New receiver work: an `sfx` and a `music` recipe each, plus Stage 1 audio checks for stereo/longer files (current checks were built for short mono voice).

## 5. Decisions for Homi (P1–P6)
- **P1** 8b SFX: Stable Audio 3 Small-SFX (recommended) / Stable Audio Open 1.0 / CC0 sound packs instead of AI?
- **P2** 8c music: Stable Audio 3 Small (recommended) / ACE-Step 1.5 Turbo?
- **P3** Community-licence models recorded as `commercial_ok = yes` with the revenue condition in the licence text + yearly reminder?
- **P4** First sub-step = a **ComfyUI update plan** (read-only pre-checks, then update with torch check and image/voice re-test) — approved separately?
- **P5** Blocked list: add Meta MusicGen (CC-BY-NC)?
- **P6** Order: 8b first, then 8c (one asset type at a time, as design v1.1)?

## Sources
- https://huggingface.co/stabilityai/stable-audio-open-1.0 · https://stability.ai/license
- https://stability.ai/news-updates/meet-stable-audio-3-the-model-family-built-for-artistic-experimentation-with-open-weight-models
- https://huggingface.co/stabilityai/stable-audio-3-small-sfx · https://docs.comfy.org/tutorials/audio/stable-audio/stable-audio-3
- https://huggingface.co/ACE-Step/ACE-Step-v1-3.5B · https://comfyui-wiki.com/en/models/ace-step/ace-step-v1-5
- https://boppy.me/blog/best-open-source-ai-music-models
