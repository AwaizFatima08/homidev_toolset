# homidev — asset engine (read by Claude Code on homi-nas)

Last updated: 6 Oct 2026 (step 10e, v2.1 after the pilot). Full designs on homi-nas: `~/homidev_toolset/docs/homidev-asset-pipeline-design.md` (v1.1, LOCKED), `receiver-design.md` (v1.0) and `homidev-step10-design.md` (v0.1, E1–E8 locked).

## What it is
- Separate GPU machine on the LAN: `192.168.100.123`, user `homidev`. RTX 5060 Ti 16 GB, 16 GB RAM.
- Makes assets for projects: **images/graphics and English voice-overs** today; sound effects and background music are planned (not yet available).
- NOT for: video, Urdu voice (deferred), pipeline text. Small UI animations are made by you (Claude Code) as code/Lottie, only where required. GIFs only with Homi's approval per request.
- **Only available when Homi has booted it into Debian** (usually at night). `asset-job.sh` checks this for you; never assume it is up.

## Current status
- Receiver v0.6 (service `asset-receiver`): validates every request, applies the licence gate, unloads Ollama before image jobs.
- Approved recipes (6 Oct 2026):

| Recipe | Makes | Inputs | Notes |
|---|---|---|---|
| `image-zimage-basic` v1.0 | 1024×1024 PNG, **commercial OK** (Z-Image-Turbo, Apache 2.0) | `prompt` (required), `seed` (optional) | no negative prompt — say in the prompt what you want, incl. "no text", "no frame" |
| `voice-en-standard` | WAV + OGG voice-over, **commercial OK** (Kokoro) | `script`, `glossary` (both required, never empty), `voice` (optional, default `af_heart`) | only the OGG goes into an app |
| `test-image-cutout` | **tests only — never for a project** | — | SDXL Turbo, non-commercial |

- A new recipe or tool needs Homi's approval. A refused job lists the currently approved recipes.

## Workflow — always in this order
1. **Ask before requesting.** Tell Homi what you want to make (type, purpose, prompt or script, where it goes) and wait for his OK.
2. **Request** — one asset per call (run `asset-job.sh` once per job, no shell loops; read each job's last line), batches of at most 5:
   `~/ai-inbox/_tools/asset-job.sh <project> <recipe> <yes|no> <inputs.json>`
   - `<project>`: repo folder name in lowercase with hyphens (e.g. `sehat-alarm`).
   - `yes` = commercial project (default for every HomiLabs app). The licence gate decides — never work around a refusal.
   - Read the **last line**: `RESULT: PASS <folder>` / `PASS with warnings <folder>` / `FAIL <reason>`. Exit 3 = refused or homidev unreachable → tell Homi and **stop**; no retry loops. A Stage 1 FAIL is moved to `~/ai-inbox/_rejected/` automatically.
3. **Look at every image yourself** (open the PNG). Write a short note — matches the brief? extra objects, garbled text, odd hands, frame/tile in the background? — to `~/ai-inbox/<project>/_notes/<job-id>.txt` (never inside the job folder).
4. **Review sheet** for the batch: `~/ai-inbox/_tools/review-sheet.sh <project> <job-folder> ...` → give Homi the path of the HTML page.
5. **Wait for Homi's decision in chat** ("approve 1, 3; reject 2: reason"). Never decide for him.
6. Act on it, one job at a time:
   - approve: `~/ai-inbox/_tools/asset-integrate.sh approve <job-folder> <repo> <subfolder>`
   - reject: `~/ai-inbox/_tools/asset-integrate.sh reject <job-folder> "<Homi's reason>"`
7. Commit the new `assets/` files and `assets/ASSET-REGISTER.md` in the project's normal way (Homi's backup routine applies). Never edit register rows by hand. If the repo has no commits yet, the commit would include other files, or the git name/email looks wrong, ask Homi before committing.

## Prompt rules (from tests on 5 Oct 2026)
- **People:** always name the audience, e.g. "a Pakistani family, modest clothing". Without it the model picks its own default.
- **Icons:** ask for "solid filled shapes, no outlines, centered, empty space around, no frame, no border, no text". For launcher icons use a **solid background colour that fills the whole square edge to edge** — this avoids the faint background tile (pilot 6 Oct: 2 of 3 clean; still check every image for a rounded tile or white margin). A transparent version needs a cut-out recipe (not built yet). Simple flat shapes can also be drawn as SVG in code — offer that option.
- **Text in images** works well — keep it short and spell it exactly in quotes.
- **Plain gradients / flat colours:** make them in app code, not with AI.
- **Voice:** `glossary` is never empty — list app, brand and medical words from the script; if there are none, use the main subject word. Short clips (< 5 s) may get a loudness WARN — Homi listens.

## Always reviewed by Homi
Health or medical content, anything for children, images with text or people, every voice-over and music track, every GIF. Treat every `WARN` line as something Homi must see or hear before deciding.

## Do not
- integrate anything Homi has not approved in this chat;
- put WAV masters, test-recipe output or files from `~/ai-inbox/_rejected/` into a repo;
- call homidev's receiver, ComfyUI or Ollama directly, or use the read-only pull key (`~/.ssh/homidev_pull`) for anything except what `asset-job.sh` does;
- change anything on homidev (models, recipes, receiver) — that is Homi's separate, planned work.
