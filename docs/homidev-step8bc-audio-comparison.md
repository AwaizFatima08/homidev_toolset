# homidev Steps 8b + 8c — Sound effects and music models: comparison v0.6 — **P1–P7 LOCKED 6 Oct 2026**

Date: 6 Oct 2026 · Design v1.1, step 8 · Status: **P1–P7, Q1–Q6, R1–R6 locked 6 Oct · 8b-1 passed · 8b-2 done · 8b-3 closed (register + models installed) · next 8b-4 first test sound (plan pending)**
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

## 6. Step log
- **8b-1 (6 Oct) — PASSED, closed.** Read-only pre-check: ComfyUI 0.37.0 has Stable Audio 3 support built in (`comfy/text_encoders/sa3.py` + core files; audio nodes present) → **no ComfyUI update (P4)**. torch `2.14.0+cu130 True` (first attempt failed only because the shell sat in a deleted folder `/tmp/zrec`). 862 GB free, 10 GB RAM available, GPU idle, Ollama empty, no Stable Audio files present. Only Medium templates ship with ComfyUI.
- **P7 settled (6 Oct):** Stability's model page says the `_base` file is "the base (pre-trained) model intended for fine-tuning" → use the normal file.
- **8b-2 (6 Oct) — PASSED, closed.** Both files downloaded into `~/model-review/stable-audio-3/` (~13 min at ~4.4 MB/s), **both sha256 OK** against Hugging Face; `LICENSE.md` (Community Licence, pinned revision `ae127552…8c20`), `README-comfy-org.md`, `SHA256SUMS`, `SOURCE.txt` saved beside them. Nothing moved into ComfyUI.
- Checked 6 Oct: original text encoder `google/t5gemma-b-b-ul2` is under the **Gemma licence** (gated by Google; the Comfy-Org copy is not). Claude's copy of MODEL-REGISTER.md matches the homidev version (sha256 `29e1905a…3cde`).
- **8b-3a (6 Oct, 01:30) — DONE.** Homi registered with Stability AI on 6 Oct 2026 (company HomiLabs Solutions SMC Pvt Ltd, contact Humayun Shahzad). MODEL-REGISTER.md → sha256 `4118d485…6ec4`, models.json → `7e6e9d0d…22ed`; backups `*.bak-20261006` = originals (`29e1905a…`, `78bf2d4e…`). Note: the superseded v1 paste was run first, then the v2 paste correctly refused (fingerprint check); a 2-line patch brought the text to v2. **Lesson: every paste ends with a versioned success line, e.g. `(v2)`, so the output shows which version ran.**
- **8b-3b (6 Oct) — DONE; 8b-3 closed.** Both models moved with `mv -n` into `~/ComfyUI/models/checkpoints/` and `text_encoders/`; register fingerprints checked against the review files *before* the move and against the installed files *after* (paths read from models.json): all OK. Review folder keeps LICENSE.md, README-comfy-org.md, SHA256SUMS, SOURCE.txt. Paste caught in testing first: register check was after the move, and `exit 1` would have closed the SSH session — both fixed before use.

## 7. Plan 8b-2 — download + verify (Q1–Q6 LOCKED 6 Oct 2026 by Homi)
Facts checked 6 Oct (two independent sources agree: Hugging Face API from Claude's sandbox + model web pages):

| File | Size (bytes) | sha256 (Hugging Face) |
|---|---|---|
| `checkpoints/stable_audio_3_small_sfx.safetensors` | 2,270,384,940 | `ed9cf1b6172f1a8c2921a9560c21109ff3239524563ced9dce6dcdef41e2f515` |
| `text_encoders/t5gemma_b_b_ul2.safetensors` | 1,187,264,003 | `1e1eba25be8872edb0d3c6335c6658fd6388e7b14b60da6e454e404cfcd8150e` |

Repository `Comfy-Org/stable-audio-3`, revision `96fc663283cde94cb631bc84f6c9ece7bbe2bf25` (17 Aug 2026), licence tag `stable-audio-community`, **not gated** (no login needed; tested).

Licence (Stability AI Community License Agreement, 5 July 2024, from `stabilityai/stable-audio-3-small-sfx/LICENSE.md`):
- Free while HomiLabs + affiliates have **< US$1M annual revenue**; above that the licence ends unless an Enterprise licence is bought.
- **"If You are using or distributing the Stability AI Materials for a Commercial Purpose, You must register with Stability AI"** (stability.ai/community-license).
- **"If You distribute or make available … a product or service that uses any portion of them, You shall … prominently display 'Powered by Stability AI'"** on a website, UI, about page or product documentation. Whether an app that only contains *generated sounds* "uses" the model is unclear → cheapest safe reading: show it.
- "You own any outputs generated from the Models."
- Text encoder T5Gemma: Google Gemma terms (commercial use allowed; use-policy rules). Recorded in the register.

Decisions:
- **Q1 Files:** exactly the 2 files above, from the pinned revision, into `~/model-review/stable-audio-3/` (not into ComfyUI yet).
- **Q2 Tool:** `curl -L --fail -C -` (resumable; nothing to install). Licence file `LICENSE.md` + Comfy-Org `README.md` saved next to the models.
- **Q3 Fingerprint:** expected sha256 written into a `SHA256SUMS` file from the table above; `sha256sum -c` must say OK for both, else stop. Same check again after the move in 8b-3.
- **Q4 Registration:** Homi registers HomiLabs at stability.ai/community-license **before the first sound goes into a commercial app** (not needed to download/test). Recorded in the register.
- **Q5 Attribution:** every HomiLabs app that ships a Stable Audio sound shows **"Powered by Stability AI"** on its About screen or store description. Becomes an `asset-integrate.sh` / homidev.md rule later (step 11), not now.
- **Q6 Scope of 8b-2:** download + verify only. Register/models.json entries, moving into `~/ComfyUI/models/`, and the first test sound are **8b-3 and 8b-4**, each separately approved (same pattern as 8a).

## 8. Plan 8b-3 — register + install (R1–R6 LOCKED 6 Oct 2026 by Homi)
- **R1 Register with Stability first.** Homi fills in the free form at stability.ai/community-license for HomiLabs **before** 8b-3 runs; date recorded in the register. Reason: once `commercial_ok = yes`, the licence gate lets SFX into commercial apps — registration must already be done. (Alternative: `commercial_ok = no` until registered — more moving parts.)
- **R2 MODEL-REGISTER "Installed" rows (draft):**

| Model | File | Source | Licence | commercial_ok | sha256 | Added | Used for |
|---|---|---|---|---|---|---|---|
| Stable Audio 3 Small-SFX (Comfy-Org repackage) | `checkpoints/stable_audio_3_small_sfx.safetensors` (2.27 GB) | https://huggingface.co/Comfy-Org/stable-audio-3, revision `96fc663283cde94cb631bc84f6c9ece7bbe2bf25` (original: stabilityai/stable-audio-3-small-sfx) | Stability AI Community Licence (5 Jul 2024; checked 6 Oct 2026, `LICENSE.md` in `~/model-review/stable-audio-3/`): free while HomiLabs revenue < US$1M/yr · registered <date> · apps show "Powered by Stability AI" · re-check every October | **yes (conditions)** | `ed9cf1b6172f1a8c2921a9560c21109ff3239524563ced9dce6dcdef41e2f515` | 2026-10-06 | Sound effects (step 8b) |
| T5Gemma b-b UL2 text encoder (Comfy-Org repackage) | `text_encoders/t5gemma_b_b_ul2.safetensors` (1.19 GB) | same repository and revision (original: google/t5gemma-b-b-ul2) | Gemma Terms of Use (checked 6 Oct 2026) | **yes** | `1e1eba25be8872edb0d3c6335c6658fd6388e7b14b60da6e454e404cfcd8150e` | 2026-10-06 | Text encoder for all Stable Audio 3 models (8b + 8c) |

  Note under the table: an SFX job uses both files → its licence text is "Stability AI Community Licence + Gemma terms" (strictest-licence rule).
- **R3 Other register sections:** Blocked += **Meta MusicGen** (CC-BY-NC 4.0). Pending: "Stable Audio Open" → **Stable Audio 3 Small-Music (8c)**; "ACE-Step" → **ACE-Step 1.5 Turbo (reserve)**.
- **R4 models.json:** same fields as the Z-Image entries. Claude drafts it from the current file (Homi pastes it, read-only).
- **R5 Install method (as 8a):** backups `*.bak-20261006` of both register files → write new files by heredoc + sha256 check → in the review folder `sha256sum -c` → `mv -n` into `~/ComfyUI/models/checkpoints/` and `text_encoders/` → `sha256sum` again in place. All chained with `&&`. Review folder keeps `LICENSE.md`, `SOURCE.txt`, `SHA256SUMS` as the record (not deleted).
- **R6 Scope of 8b-3:** no ComfyUI restart, no receiver change, no recipe. First test sound = 8b-4 (separate approval).

## Sources
- https://arxiv.org/html/2605.17991v1 (Stable Audio 3 paper: 44.1 kHz stereo, parameter counts)
- https://blog.comfy.org/p/stable-audio-3-day-0-support (ComfyUI v0.22.0)
- https://github.com/Comfy-Org/ComfyUI/actions/runs/26172925119 (PR #14010 "Support Stable Audio 3 model")
- https://huggingface.co/Comfy-Org/stable-audio-3 (file names and sizes)
- https://huggingface.co/stabilityai/stable-audio-3-small-sfx · https://stability.ai/license
- https://stability.ai/news-updates/meet-stable-audio-3-the-model-family-built-for-artistic-experimentation-with-open-weight-models
