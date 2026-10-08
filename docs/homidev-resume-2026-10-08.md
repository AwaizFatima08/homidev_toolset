# homidev asset pipeline — resume note for Claude Code (8 Oct 2026)

Written at the end of the Cowork sessions of 6–8 Oct 2026 so the work can continue in Claude Code on homi-nas.
Read this first, then `docs/homidev-toolset-checklist.md` (full history, every fingerprint) and `docs/homidev-step8bc-audio-comparison.md` (audio decisions).

## 1. Who and how
- Owner: **Homi** (Dr. Humayun Shahzad), HomiLabs. Learner with no formal IT background — explain simply, in plain English.
- **Working rules (agreed, keep them):**
  1. One step at a time; build → verify → next.
  2. **Lock decisions in writing** (numbered, e.g. VL1–VL6) and wait for "agreed" **before** any command.
  3. Always **critique** Homi's proposals and your own plan; flag scope creep openly.
  4. **Test everything first** (sandbox / mock / copy) before Homi runs it on a real machine.
  5. Installs as one chained paste (`&&`): hostname guard → check current file's sha256 → backup (`.bak-<old version>`) → write `.new` by heredoc → check new sha256 → syntax check → `mv` → health check → versioned success line `== <step> … INSTALLED (v1)`. Never `exit` in an interactive paste.
  6. Small patches are fine for big files (python `rep()` with exact-once asserts), result verified by sha256.
  7. Downloads go to `~/model-review/<model>/` first; licence + sha256 checked; register updated before moving into ComfyUI.
  8. Close every session with the backup routine: docs into `~/homidev_toolset/docs/` → `~/ai-inbox/_tools/homidev-backup.sh` (git commit + push; check **no `D` lines**) → local snapshot → Google Drive copy (folder "homidev toolset").
- Changes on **homidev** are made by Homi pasting commands there (SSH/Remote Desktop). Claude Code runs on **homi-nas** only. The `~/.claude/homidev.md` rule "do not change anything on homidev" is for *app-project* sessions; pipeline-development sessions like this one prepare pastes for Homi.

## 2. Machines
| | homidev | homi-nas |
|---|---|---|
| Role | GPU asset engine | Claude Code, inbox, tools, git backup |
| Address / user | `192.168.100.123` / `homidev` | local / `humayun` |
| Key facts | Debian on Samsung 970 2 TB NVMe (boot entry `debian-nvme`, F11; Windows is default), RTX 5060 Ti 16 GB, **16 GB RAM (1 Corsair stick; 2nd identical Corsair CMK16GX5M1B5200Z40 on order)**, ComfyUI 0.37.0 (`comfyui` service, 8188), Ollama (11434), receiver (`asset-receiver` service, 8190), ~920 GB free | no sound card (listen on desktop), ffmpeg 5.1.9, git repo `~/homidev_toolset` |

## 3. What is built (all installed and tested)
**Flow:** `asset-job.sh` (homi-nas) → receiver (homidev: validate, licence gate, unload Ollama, run ComfyUI/Kokoro, clean up) → pull (read-only key) → `stage1-check.sh` → `review-sheet.sh` → Homi decides → `asset-integrate.sh`.

| Component | Version | sha256 (start) | Where |
|---|---|---|---|
| receiver | **v0.10** | `0e911ecc…` | homidev `~/receiver/receiver.py` |
| recipe `image-zimage-basic` | v1.0 | — | homidev `~/assets/recipes/` |
| recipe `voice-en-standard` | **v0.2** (limiter) | `ee4d58c1…` | 〃 |
| recipe `sfx-ui-basic` | v1.1 | recipe `cb08f549…` | 〃 |
| recipe `music-loop-basic` | v1.0 | `7b56f758…` / workflow `c3ddd55f…` | 〃 |
| MODEL-REGISTER / models.json | 8 Oct | `9f2fdd87…` / `f1699315…` | homidev `~/assets/` |
| `asset-job.sh` | v1.1 | `1c86fcc4…` | homi-nas `~/ai-inbox/_tools/` |
| `stage1-check.sh` | **v0.6** (image/voice/sfx/music rules) | `d23243c3…` | 〃 |
| `review-sheet.sh` | **v1.1** (music loops on page) | `1ce2bf4a…` | 〃 |
| `asset-integrate.sh` | **v1.1** (ATTRIBUTION.md) | `767c2689…` | 〃 |
| Claude Code rules | **homidev.md v2.2** | `83a4b91a…` | homi-nas `~/.claude/homidev.md` |

**Models (all commercial OK, in MODEL-REGISTER):** Z-Image-Turbo int8 (Apache 2.0) · Kokoro 82M + af_heart (Apache 2.0) · faster-whisper small.en (MIT) · Stable Audio 3 Small-SFX + Small-Music + T5Gemma encoder (Stability AI Community Licence — HomiLabs registered 6 Oct 2026; apps must show **"Powered by Stability AI"**; re-check every October) · BiRefNet, Real-ESRGAN. SDXL Turbo = tests only. Blocked: FLUX.1/2 dev, FLUX.2 klein 9B, BRIA RMBG-2.0, Meta MusicGen.

**Key behaviours to remember:**
- Sound effects: mono OGG, silence trimmed both ends (10 ms lead), peak −3 dB. Same seed + prompt + recipe = same sound.
- Music: model writes short pieces with endings → receiver cuts the largest whole number of bars in the first 75 %, 0.5 s blend into the start, −16 LUFS, stereo Opus 128k. Loudness is written to a WAV first, then OGG (v0.9.1 fix for a wrong Ogg end marker in "dynamic" loudness mode).
- Voice: gain + limiter −2 dB at 4× rate, re-measured ≤ 4 rounds; fails if > +20 dB needed.
- Lesson: every audio test set must include a **loud, peaky** sample (the music length bug hid behind calm test files).

## 4. Status of the build plan
- Steps 1–10: done. **Step 8 closed** (image 8a, sound effects 8b — pick tap 02, music 8c — pick loop 03).
- **Step 11: planned items done** — 11a voice limiter (Homi: "natural"), 11b attribution + sfx/music integration + looping review sheet, 11c homidev.md v2.2.
- Last backup: git commit `7e6e02a` (8 Oct 13:56), Drive folder "2026-10-08 homidev step 11 backup (11a–11c done)".

## 5. Open items (choose with Homi)
1. **Step 12 — LLM workbench** (design v1.2, L1–L6 locked 7 Oct): LM Studio (receiver must also unload it — rule: never run models in parallel), Qwen + DeepSeek in Ollama sized for 16 GB, fair "deep thinking" comparison (gpt-oss high / Qwen thinking / DeepSeek-R1), test sheet (tokens/s, VRAM, fits/spills, quality) to decide hardware vs online spending. **First: get Homi's full "max" wishlist (L6)** and make one ordered plan.
2. Icon cut-out recipe (transparent PNG; built-in BiRefNet + Invert Mask chain known from step 4).
3. `homidev-backup.sh` delete-guard (stop if a commit would delete tracked docs).
4. Tidy `~/model-review/z-image-turbo/` (keep licence record only).
5. Optional: voice tolerance ±0.3 LU; music limiter if a loop sounds squashed; BPM detection only if a join lands off the beat.
6. Q5 follow-up: when the first app ships with homidev sounds, Homi checks the About screen once by hand.

**Dated reminders:**
- ~**15 Oct**: check the clean-up log (`asset-cleanup` dry runs) and decide whether to add `--delete`.
- ~**19 Oct**: decide the Toshiba disk and the old `debian` boot entry.
- **Corsair stick** arrives: fit, check both seen, memtest86+ overnight.
- 2× 512 GB NVMe: stay unplugged until a purpose is decided.

## 6. Start of the next session
1. Read this file, the checklist and `~/.claude/homidev.md`.
2. Check the live state (read-only) and compare with section 3:
   `curl -s -H "X-Receiver-Token: $(cat ~/.config/asset-receiver/token)" http://192.168.100.123:8190/health` and `sha256sum ~/ai-inbox/_tools/*.sh ~/.claude/homidev.md`
3. Ask Homi which open item to take; propose numbered decisions; wait for "agreed".
