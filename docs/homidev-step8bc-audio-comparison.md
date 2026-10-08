# homidev Steps 8b + 8c — Sound effects and music models: comparison v0.9 — **P1–P7 LOCKED 6 Oct 2026**

Date: 6 Oct 2026 · Design v1.1, step 8 · Status: **P1–P7, Q1–Q6, R1–R6 locked 6 Oct · 8b-1 passed · 8b-2 done · 8b-3 closed (register + models installed) · 8b-4 first sounds passed · SFX0–SFX8 locked 7 Oct · 8b-5a receiver v0.7 + 8b-5b recipe installed · 8b-5c stage1 v0.5 · 8b-5d first real jobs · D1–D3 locked · 8b-6 receiver v0.8 + recipe v1.1 · **8b CLOSED 7 Oct (Stage 2 pick: tap 02)** · M1–M6, S1–S4, N1–N5, MU0–MU8, F1–F3 locked · receiver v0.9.1 + recipe `music-loop-basic` v1.0 + stage1 v0.6 · **8c CLOSED 8 Oct (Stage 2 pick: loop 03) — step 8 complete**
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

- **8b-4 (7 Oct) — first sounds, PASSED.** T1–T7 locked. Read-only look at the official Medium template (8b-4a): graph = CheckpointLoaderSimple + CLIPLoader (t5gemma, type `stable_audio`) + CLIPTextEncode ×2 + EmptyLatentAudio + KSampler (8 steps, cfg 1, `lcm`, `simple`) + VAEDecodeAudio; its Qwen 3.5 "reprompt" part **not used** (Claude writes prompts). `SaveAudio` (FLAC) used instead of `SaveAudioAdvanced` (format input form unverified). Script `~/ai-inbox/_test/8b4/sfx-test.sh` v1 (sha256 `72eae8a7…88fa`) on homi-nas, mock-tested (5 cases). Three jobs, **5 s each** incl. model load:
  - 01 chime (2 s asked): ~1.0 s sound + 1 s silence; peak −6.2 dB; Homi: "more than one note, clear"
  - 02 tap (1 s): 23 ms click + ~1 s silence; peak −14 dB (too quiet); Homi: "a tick, then a long pause"
  - 03 boing (2 s, "rising pitch"): ~1.25 s + 0.8 s silence; peak −1.7 dB; Homi: pitch **falling** → model ignores fine details
  - Analysis (Claude, from Homi's uploaded files, fingerprints matched): L/R identical in all three (correlation 1.000) → really mono; ComfyUI writes the whole workflow into the FLAC as hidden `prompt` metadata. Trial clean-up (mono, trim, peak −3 dB, metadata stripped, Opus 64k): 0.91 s/8 KB, 0.11 s/1.7 KB, 1.15 s/8.6 KB — previews sent to Homi
- RAM (7 Oct): new SK hynix 16 GB DDR5-5600 in B2 **not detected** (only Corsair 16 GB DDR5-5200 in A2 seen); `EDAC MC: Ver` line was a harmless driver message, not an error. Homi checks the stick this evening; then memtest86+ overnight. Does not block 8b.

- **8b-5a (7 Oct) — receiver v0.7 INSTALLED, closed.** V1–V6 locked. `receiver.py` v0.7 (sha256 `de10a598…7afd`; backup `receiver.py.bak-20261007` = v0.6 `0b3be3ff…3b3e`): ComfyUI audio outputs collected; `postprocess: sfx` clean-up (mono, trailing-silence trim −50 dB/50 ms + 10 ms fade, peak −3 dB, metadata stripped, Opus 64k) → `<job>_master.flac` (as generated, tags removed) + `<job>_sfx.ogg`; job fails if < 20 ms of sound remains; int inputs may have min/max. Tested in Claude's sandbox with real v0.7 code, mock ComfyUI/Ollama and Homi's 3 real sounds (sfx ×3 done, image regression done, silent output → failed with reason, seconds 0/60 refused, no workflow text left). File moved via homi-nas (`~/homidev_toolset/incoming/`, removed after copy). On homidev: health `ok (v0.7)`, 3 recipes, 0 problems; image job `20261007-1401-test-image-01` PASS with receiver_version 0.7.
  - Voice regression job `20261007-1401-test-voice-01` **Stage 1 FAIL**: 2.1 s clip at −23.5 LUFS (limit −16 ± 3). Not caused by v0.7 (voice code byte-identical); it is the known short-clip limit (loudnorm held back by the −1.5 dB true-peak cap). **Moved to the top of step 11: voice recipe v1.1 with a limiter.** Not fixed now (outside 8b).

- **8b-5b (7 Oct) — recipe `sfx-ui-basic` v1.0 installed, closed.** recipe.json `bfd19982…d3d8`, workflow.json `04bba283…b2ac`; receiver lists it commercial_ok yes, nothing skipped. First attempt ran on homi-nas (no `~/assets`, `mv` failed, nothing changed) → rule: every paste starts with a hostname check.
- **8b-5c decisions K1–K6 LOCKED 7 Oct; order agreed: 8b-5c before the first real sfx job (8b-5d).** K1 rules by asset type, voice/image unchanged · K2 sfx OGG: 0.02–10 s, mono, true peak −4..−1 PASS / > −1 FAIL / < −4 WARN, loudness info only · K3 start silence > 0.1 s WARN, end silence > 0.1 s FAIL · K4 hidden workflow text in any audio file FAIL · K5 manifest `postprocess.type = sfx` required; master = fingerprint + info line · K6 v0.5, backup `.bak-20261007`. Built + tested: v0.5 `3ebb7e9a…568d`.
- **8b-5c (7 Oct) — stage1-check.sh v0.5 INSTALLED, closed.** On homi-nas `~/ai-inbox/_tools/`, backup `.bak-20261007` = v0.4; image test job still PASS.
- **8b-5d (7 Oct) — first real sfx jobs, PASSED with warnings.** `asset-job.sh test sfx-ui-basic yes`, prompt "Single soft button tap, short plastic click, close-up, dry, no reverb. Length: 1 seconds", seconds 2, seeds 3001–3003 → `20261007-1709-test-sfx-01..03`. OGG 1.10–1.13 s, mono, peak −2.9…−3.2 dB, no hidden workflow text. Each Stage 1 WARN: **0.31–0.35 s silence before the click** (SFX2 left the start untrimmed); plus a faint sound near 1.04 s that keeps files at ~1.1 s.
- **D1–D3 LOCKED 7 Oct by Homi.** D1 trim the start too, keep 10 ms (receiver v0.8 + recipe v1.1; v1.0 recipes behave as before) · D2 leave the faint tail (inaudible; a stricter threshold could cut real tails like bell rings) — shorter 'Length:' in the prompt if a file must be tiny · D3 pick none from the 1709 jobs; re-run the same seeds after the fix.
- **8b-6 (7 Oct) — receiver v0.8 + recipe v1.1 INSTALLED, closed.** Receiver by a 6-line patch (sha256 `0081529c…3748`, backup `receiver.py.bak-v0.7`); health `ok (v0.8)`. Recipe v1.1 `cb08f549…4fbb` (`lead_keep_s: 0.01`; backup `~/assets/recipe-sfx-ui-basic-v1.0.json.bak`). Sandbox tests first: v0.8 + recipe v1.0 output byte-identical to v0.7; silent output still fails; image regression OK. Re-run `20261007-2120-test-sfx-01..03`: 0.78 / 0.82 / 0.80 s, pause before click < 0.01 s, peak −2.8…−3.0 dB, **Stage 1 PASS, no WARN** on all three. Masters identical to the 1709 run → same seed + prompt + recipe reproduces the same sound.
- **8b CLOSED 7 Oct.** Homi's Stage 2 pick: **tap 02** (`20261007-2120-test-sfx-02`). Carried to step 11: Q5 attribution rule, `asset-integrate.sh` and `review-sheet.sh` sfx support.

## 6c. Step log 8c (music)
- **M1–M6 LOCKED 7 Oct:** same pinned revision `96fc6632…`, fingerprint `da85866b…4b64`; normal file only (no `_base`, no Medium); 8c-1 download only; test loops 30 s (menu 90 BPM, study 70 BPM, kids 120 BPM), instrumental; measure join/stereo/loudness/time; receiver already frees Ollama.
- **8c-1 (7 Oct) — PASSED.** `~/model-review/stable-audio-3/small-music/`; 2,270,384,940 bytes in 8 min 14 s; model + licence sha256 OK; licence **byte-identical** to Small-SFX (`d6f6b1a4…`), so the 6 Oct registration covers it. 857 GB free.
- **S1–S4 LOCKED / 8c-2 (7 Oct) — DONE.** Register row + models.json key `stable-audio-3-small-music` (same licence text, commercial_ok yes); Pending row removed; backups `*.bak-8c`; one combined paste: file checked *before* any register change, then register, then `mv -n` + sha256 in place. MODEL-REGISTER `9f2fdd87…`, models.json `f1699315…`.
- **N1–N5 LOCKED / 8c-3 (7 Oct) — first loops.** `music-test.sh` v1 (copy of sfx-test.sh: model, folder, 10 min wait, stereo + edge measurements, `_loop2x.ogg`). Model card: 8 steps, cfg 1, BPM in prompt. Results: **5 s per 30 s clip**; real stereo (L/R corr 0.4–0.8); −15.4/−13.9/−11.3 LUFS; clipping 0/133/2685 samples; **each clip is a short piece with an ending** (fade or stop + silence) → not a loop by itself. Claude's demo (cut at whole bars before the ending, 0.5 s blend into the start) → Homi: quality great, joins acceptable, no distortion heard.
- **MU0–MU8 LOCKED 8 Oct.** MU0 Small-Music good enough (ACE-Step reserve) · MU1 stereo · MU2 loop = largest whole bars inside first 75 %, 0.5 s blend, ≥ 4 bars · MU3 −16 LUFS, true peak ≤ −1 dB, baked-in clipping accepted (counted, info) · MU4 FLAC master (no metadata) + stereo Opus 128k OGG; only OGG into apps · MU5 recipe `music-loop-basic` v1.0: prompt + bpm (60–160, required) + seconds (20–60, default 30) + seed; model text "{prompt}, {bpm} BPM, instrumental, no vocals" · MU6 Stage 1 music rules · MU7 prompt rules (style + instruments + mood; BPM only in its field; 3 seeds) · MU8 build order receiver → recipe → Stage 1 → real jobs.
- **8c-4a (8 Oct) — receiver v0.9 INSTALLED** (`05908d0e…`, backup `receiver.py.bak-v0.8`). Sandbox found + fixed 2 bugs first: ffmpeg crash in the first loop-cut method (→ `acrossfade`, max 2 % difference from the approved demo); unclear error on silent music. SFX output byte-identical to v0.8. Homi listened to the receiver's own loops: "great".
- **8c-4b (8 Oct) — recipe `music-loop-basic` v1.0 INSTALLED** (`7b56f758…`, `c3ddd55f…`); paste refuses unless receiver v0.9 is running (v0.8 would deliver raw FLAC only).
- **8c-4c (8 Oct) — stage1-check.sh v0.6 INSTALLED** (`d23243c3…`, backup `.bak-v0.5`): 3 good loops PASS, 7 broken copies each caught; 14 older image/voice/sfx jobs give identical output to v0.5.
- **8c-5 (8 Oct) — first real music jobs: 2 of 3 FAILED Stage 1** (`20261008-1037-test-music-01`, `1038-test-music-01`, now in `_rejected/`): OGG length 21.4065 s vs loop 21.3333 s. Diagnosis from Homi's files: decoded audio was exactly 21.333 s; the Ogg **end granule** claimed 21.400 s. Cause: when loudnorm falls back to **dynamic** mode (peaky model output, master peak −0.1 dB), encoding straight to Opus writes a wrong end marker. Reproduced in the sandbox with ffmpeg 6.1 and 7.0.
- **F1–F3 LOCKED 8 Oct:** F1 receiver v0.9.1: loudness → WAV, then WAV → OGG; manifest records `loudness_mode` · F2 Stage 1 stays strict (±0.05 s) · F3 failed jobs kept in `_rejected/` as the record; re-run seeds 5001–5003.
- **8c-5a (8 Oct) — receiver v0.9.1 INSTALLED** (`be613986…`, backup `receiver.py.bak-v0.9`). Re-run `20261008-1050-test-music-01..03`: **all Stage 1 PASS**, 21.34 s, −16.2/−15.8/−16.0 LUFS, true peak −1.3/−2.0/−1.2 dB; seed 5001 (dynamic) now correct; 02 byte-identical to the v0.9 run (linear path unchanged). Edge levels (start/end): 01 −13/−40 dB, 02 −18/−17, 03 −29/−25.
- **8c CLOSED 8 Oct.** Homi's Stage 2 pick: **loop 03** (`20261008-1050-test-music-03`). **Step 8 complete.** Carried to step 11: Q5 attribution, `asset-integrate.sh` + `review-sheet.sh` music support, limiter option for peaky music.

## 6b. Sound-effects recipe decisions (SFX0–SFX8) — LOCKED 7 Oct 2026 by Homi
- **SFX0** Small-SFX is good enough → build the recipe.
- **SFX1** Always mono.
- **SFX2** Trim trailing silence below −50 dB, keep 50 ms + 10 ms fade-out; start not trimmed; Stage 1 WARN if > 0.1 s silence at the start. **Changed by D1 (7 Oct): start is now trimmed too, keeping 10 ms (recipe v1.1).**
- **SFX3** Level by **peak**: normalise to −3 dB (not LUFS; voice keeps −16 LUFS).
- **SFX4** FLAC master kept in the job folder; deliverable = OGG/Opus mono 64 kb/s; only the OGG goes into apps.
- **SFX5** Strip all metadata (hidden ComfyUI workflow) from delivered files.
- **SFX6** Request ~2 s for UI sounds, 3–4 s for longer effects; trim does the rest.
- **SFX7** Prompt rules: kind of sound + source + material + space ("dry, close-up") + "Length: N seconds"; don't rely on fine details (pitch direction, note count); make **3 versions** (seeds), Homi picks by ear.
- **SFX8** Clean-up runs on homidev inside the receiver (like the voice recipe); build = 3 separately approved steps: receiver version → recipe `sfx-ui-basic` v1.0 → Stage 1 SFX rules in `stage1-check.sh`. Q5 ("Powered by Stability AI") still in step 11.

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
