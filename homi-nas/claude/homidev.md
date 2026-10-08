# homidev — asset engine (read by Claude Code on homi-nas)

Last updated: 8 Oct 2026 (v2.4 — Lottie animations on homi-nas, LT1–LT8; v2.3: receiver v0.11 GPU guard, asset-pull.sh, LM Studio + LLM models, Wan 2.2 test only). Full designs on homi-nas: `~/homidev_toolset/docs/homidev-asset-pipeline-design.md` (v1.1, LOCKED), `receiver-design.md` (v1.0), `homidev-step10-design.md` (v0.1, E1–E8 locked) and `homidev-step8bc-audio-comparison.md` (sound effects + music decisions).

## What it is
- Separate GPU machine on the LAN: `192.168.100.123`, user `homidev`. RTX 5060 Ti 16 GB, 16 GB RAM.
- Makes assets for projects: **images/graphics, English voice-overs, short sound effects (UI taps, chimes) and background music loops**.
- NOT for: video (Wan 2.2 5B is installed for **tests only** — no recipe, no project use until Homi approves), Urdu voice (deferred), songs with vocals, pipeline text.
- Also on homidev (outside the asset pipeline, for Homi's own LLM work): Ollama (gpt-oss:20b, gemma4:12b, qwen3.5:9b, deepseek-r1:14b/8b) and LM Studio headless (`lms`, port 1234, local only). You never start these for a project; the receiver unloads them before every job.
- Small UI animations are made by you (Claude Code) **on homi-nas as Lottie**, only where required (see 'Lottie' below). GIFs only with Homi's approval per request.
- **Only available when Homi has booted it into Debian** (usually at night). `asset-job.sh` checks this for you; never assume it is up.

## Current status
- Receiver v0.11 (service `asset-receiver`): validates every request, applies the licence gate, unloads Ollama **and LM Studio** before every ComfyUI job, then checks the GPU is free (a job fails with `GPU busy: … MiB` if something else holds it — tell Homi, do not retry in a loop), strips ComfyUI's hidden prompt/workflow text from PNGs, cleans up audio (sound effects, music loops, voice levelling).
- Approved recipes (8 Oct 2026):

| Recipe | Makes | Inputs | Notes |
|---|---|---|---|
| `image-zimage-basic` v1.0 | 1024×1024 PNG, **commercial OK** (Z-Image-Turbo, Apache 2.0) | `prompt` (required), `seed` (optional) | no negative prompt — say in the prompt what you want, incl. "no text", "no frame" |
| `voice-en-standard` v0.2 | WAV + OGG voice-over, **commercial OK** (Kokoro) | `script`, `glossary` (both required, never empty), `voice` (optional, default `af_heart`) | levelled to −16 LUFS with a limiter (short clips too); only the OGG goes into an app |
| `sfx-ui-basic` v1.1 | sound effect: FLAC master + **mono OGG**, **commercial OK** (Stable Audio 3 Small-SFX — needs attribution, see below) | `prompt` (required), `seconds` (1–10, default 2), `seed` (optional) | silence trimmed at both ends, peak −3 dB; only the OGG goes into an app |
| `music-loop-basic` v1.0 | background music loop: FLAC master + **stereo OGG loop**, **commercial OK** (Stable Audio 3 Small-Music — needs attribution, see below) | `prompt` (required), `bpm` (60–160, **required**), `seconds` (20–60, default 30), `seed` (optional) | instrumental only; the loop is cut at whole bars (≈ 70 % of `seconds`: 30 → ~21 s, 60 → ~42 s), −16 LUFS; only the OGG goes into an app |
| `test-image-cutout` | **tests only — never for a project** | — | SDXL Turbo, non-commercial |

- A new recipe or tool needs Homi's approval. A refused job lists the currently approved recipes.

## Workflow — always in this order
1. **Ask before requesting.** Tell Homi what you want to make (type, purpose, prompt or script, where it goes) and wait for his OK.
2. **Request** — one asset per call (run `asset-job.sh` once per job, no shell loops; read each job's last line), batches of at most 5:
   `~/ai-inbox/_tools/asset-job.sh <project> <recipe> <yes|no> <inputs.json>`
   - `<project>`: repo folder name in lowercase with hyphens (e.g. `sehat-alarm`).
   - `yes` = commercial project (default for every HomiLabs app). The licence gate decides — never work around a refusal.
   - **Sound effects and music: always make 3 versions** — the same prompt with 3 different `seed` values (3 separate calls). Homi picks by ear.
   - Read the **last line**: `RESULT: PASS <folder>` / `PASS with warnings <folder>` / `FAIL <reason>`. Exit 3 = refused or homidev unreachable → tell Homi and **stop**; no retry loops. A Stage 1 FAIL is moved to `~/ai-inbox/_rejected/` automatically.
   - `asset-job.sh` waits 15 min. If it says the job is **still running on homidev**, do not resubmit: later run `~/ai-inbox/_tools/asset-pull.sh <project> <job-id>` once, which pulls and Stage-1-checks the finished job.
3. **Check every asset yourself and write a short note** to `~/ai-inbox/<project>/_notes/<job-id>.txt` (never inside the job folder):
   - images: open the PNG — matches the brief? extra objects, garbled text, odd hands, frame/tile in the background?
   - audio (voice, sound effects, music): you cannot listen — note the Stage 1 facts instead (length, loudness, any WARN lines; for music the BPM and loop length) and say plainly that Homi must listen.
4. **Review sheet** for the batch: `~/ai-inbox/_tools/review-sheet.sh <project> <job-folder> ...` → give Homi the path of the HTML page. Music players on the page loop, so Homi can hear the join.
5. **Wait for Homi's decision in chat** ("approve 1, 3; reject 2: reason"). Never decide for him.
6. Act on it, one job at a time:
   - approve: `~/ai-inbox/_tools/asset-integrate.sh approve <job-folder> <repo> <subfolder>` — suggested subfolders: `images`, `icons`, `audio/voice`, `audio/sfx`, `audio/music`
   - reject: `~/ai-inbox/_tools/asset-integrate.sh reject <job-folder> "<Homi's reason>"`
   - If it prints `REMINDER: this app must show "Powered by Stability AI"`, pass that on to Homi.
7. Commit the new `assets/` files, `assets/ASSET-REGISTER.md` and (if created) `assets/ATTRIBUTION.md` in the project's normal way (Homi's backup routine applies). Never edit register rows by hand. If the repo has no commits yet, the commit would include other files, or the git name/email looks wrong, ask Homi before committing.

## Lottie animations (homi-nas, agreed 8 Oct 2026, LT1–LT8)
- Scope: loaders, success ticks, empty states, onboarding micro-motion, splash accents. Original HomiLabs vector work — no AI model, no attribution. homidev is not involved.
- Make: one Python script per animation in `~/lottie/animations/<project>/<name>.py` using `~/lottie/homilottie.py` (`~/lottie/venv/bin/python <script>`); it writes a job folder `~/ai-inbox/<project>/<job-id>/` like a homidev job. Rules: shapes, fills, strokes, transforms, opacity, trim paths, masks only; **no expressions, images, text layers, effects**; 30 fps max; 512×512; aim ≤ 50 KB. Scripts add shapes background-first (`finish()` fixes the order); screen y grows downward.
- Check: `~/ai-inbox/_tools/lottie-check.sh <job>` and `stage1-check.sh <job> yes` must PASS; look at the two preview PNGs in `_notes/`; write the usual note.
- Review: `review-sheet.sh` plays the animations (loops per manifest); Homi decides in chat as always. Approve with `asset-integrate.sh approve <job> <repo> lottie`.
- Flutter: `lottie` pub package, `Lottie.asset('assets/lottie/<name>.json')`. Keep the source script in the toolset repo (`homi-nas/lottie/animations/`), so every animation can be regenerated.

## Attribution rule (Stability AI Community Licence)
- Every app that contains a HomiLabs sound effect or music loop from homidev must show **"Powered by Stability AI"** on its About screen or store description. `asset-integrate.sh` writes this into `assets/ATTRIBUTION.md` the first time.
- **Before any release build**, check that the About screen (or store listing) shows every line in `assets/ATTRIBUTION.md`. If it does not, tell Homi — do not release without it.

## Prompt rules (from tests on 5–8 Oct 2026)
- **People:** always name the audience, e.g. "a Pakistani family, modest clothing". Without it the model picks its own default.
- **Icons:** ask for "solid filled shapes, no outlines, centered, empty space around, no frame, no border, no text". For launcher icons use a **solid background colour that fills the whole square edge to edge** — this avoids the faint background tile (pilot 6 Oct: 2 of 3 clean; still check every image for a rounded tile or white margin). A transparent version needs a cut-out recipe (not built yet). Simple flat shapes can also be drawn as SVG in code — offer that option.
- **Text in images** works well — keep it short and spell it exactly in quotes.
- **Plain gradients / flat colours:** make them in app code, not with AI.
- **Voice:** `glossary` is never empty — list app, brand and medical words from the script; if there are none, use the main subject word. Every voice-over is levelled automatically; Homi still listens to every one.
- **Sound effects:** describe the kind of sound + source + material + space, e.g. "Single soft button tap, short plastic click, close-up, dry, no reverb. Length: 1 seconds". Use `seconds` 2 for UI sounds, 3–4 for longer effects. Don't rely on fine details (pitch going up or down, number of notes) — the model often ignores them.
- **Music:** style + instruments + mood, e.g. "Calm app menu background music, soft piano and warm pads, gentle and friendly". Put the tempo **only** in `bpm` (not in the prompt — the recipe adds it, plus "instrumental, no vocals"). `seconds` 30 gives a ~21 s loop; use 60 for a longer, less repetitive loop.

## Always reviewed by Homi
Health or medical content, anything for children, images with text or people, every voice-over, every sound effect and music loop, every GIF. Treat every `WARN` line as something Homi must see or hear before deciding.

## Do not
- integrate anything Homi has not approved in this chat;
- put WAV or FLAC masters, test-recipe output or files from `~/ai-inbox/_rejected/` into a repo;
- release an app with homidev sound effects or music without "Powered by Stability AI" (see Attribution rule);
- call homidev's receiver, ComfyUI or Ollama directly, or use the read-only pull key (`~/.ssh/homidev_pull`) for anything except what `asset-job.sh` does;
- change anything on homidev (models, recipes, receiver) — that is Homi's separate, planned work.
