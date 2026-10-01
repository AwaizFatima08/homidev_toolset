# homidev Receiver — Design v1.0 (APPROVED by Homi, 1 Oct 2026)

**Date:** 1 Oct 2026 · **Part of:** homidev asset pipeline design v1.1, build step 9
**Status:** APPROVED — decisions R1–R11 confirmed. Changes need Homi's approval.

---

## 1. What the receiver is

A small program on homidev that **accepts asset requests from homi-nas, runs the right recipe, and packages the result** — automatically doing what we did by hand in step 5.

```
homi-nas (Claude Code)                     homidev
──────────────────────                     ─────────────────────────────────────────
1. GET  /health  ───────────────────────►  receiver: am I up? is ComfyUI up? disk ok?
2. POST /jobs  (request.json) ──────────►  checks request → queued
                                           runs recipe (ComfyUI or Kokoro) → packages
3. GET  /jobs/<id>  (every 10 s) ───────►  queued / running / done / failed
4. rsync pull ~/assets/jobs/<id>/ ◄──────  files + manifest.json   (read-only key, already built)
5. Stage 1 checks (stage1-check.sh), Stage 2 Homi, Stage 3 integrate
```

It never pushes anything to homi-nas and never touches the internet.

---

## 2. Technology

| Item | Choice | Why |
|---|---|---|
| Language | Python 3.12 | Same as the voice tools |
| Web framework | **FastAPI + uvicorn** | Small, widely used, checks request format automatically, gives a free test page at `/docs` |
| Environment | Own env `~/receiver/venv` (via `uv`) | Separate from ComfyUI and voice envs — nothing can break them |
| Talks to ComfyUI | Its HTTP API (`/prompt`, `/history`, `/free`) | Exactly what we tested |
| Talks to voice tools | Runs `~/voice/say.py` and `~/voice/check.py` with their own envs | Keeps the environments separate |
| Runs as | systemd service `asset-receiver`, user `homidev`, starts after `comfyui` | Same pattern as ComfyUI; survives reboot |

---

## 3. Network and security

- **Port 8190**, LAN only (firewall rule added in network revamp: homi-nas + laptop only).
- **Shared token:** every request must carry header `X-Receiver-Token`. The token lives in one file on each machine (`~/.config/asset-receiver/token`, readable only by its owner). Reason: unlike ComfyUI, the receiver runs scripts — a stranger on the LAN must not be able to trigger jobs.
- Receiver only reads/writes inside `~/assets/`, runs only approved recipes, and never accepts file paths or commands from the request.

---

## 4. Endpoints (4 only)

| Endpoint | Returns |
|---|---|
| `GET /health` | `{receiver: ok, comfyui: ok/down, queue_length, disk_free_gb}` — homi-nas retries up to ~3 min |
| `GET /recipes` | List of **approved** recipes: name, asset type, models, `commercial_ok`, required inputs |
| `POST /jobs` | Accepts `request.json` → `{job_id, state: queued}` or a clear rejection reason |
| `GET /jobs/<job-id>` | `{state, started, finished, error?}` and, when done, the manifest |

Not in V1: cancel, priorities, editing a queued job.

---

## 5. Request format (`request.json`)

```json
{
  "job_id": "20261001-2130-livehealthy-learn-icon-01",
  "project": "livehealthy-learn",
  "commercial": "yes",
  "requested_by": "claude-code@homi-nas",
  "asset_type": "icon",
  "recipe": "app-icon-flat",
  "inputs": {
    "prompt": "a heart with a pulse line",
    "variants": 2
  },
  "notes": "Home-screen icon, brand colours teal/white"
}
```

Voice example: `"asset_type": "voice", "recipe": "voice-en-standard", "inputs": {"script": "...", "glossary": "LiveHealthy HomiLabs", "voice": "af_heart"}`

**Rules checked at submit (rejected immediately, before any GPU time):**
1. Token valid.
2. `job_id` matches `YYYYMMDD-HHMM-<project>-<type>-<nn>` and is not already used.
3. Recipe exists, is approved, and matches `asset_type`.
4. All required inputs present; values within limits (e.g. `variants` 1–4, script ≤ 1,000 characters).
5. **Early licence gate:** if `commercial = yes` and any model in the recipe has `commercial_ok = no` → rejected ("recipe uses non-commercial model X"). Stage 1 on homi-nas checks again (two locks).

---

## 6. Recipes

One folder per recipe in `~/assets/recipes/<name>/`:

| File | Contents |
|---|---|
| `recipe.json` | name, version, asset_type, engine (`comfyui` or `kokoro`), models used, required inputs + limits, output format, post-processing steps, `approved_by`, `approved_date` |
| `workflow.json` | (ComfyUI recipes) the API workflow with placeholders like `{{prompt}}`, `{{seed}}`, `{{prefix}}` |

- A recipe without `approved_by` is ignored.
- The receiver never builds workflows itself — it only fills placeholders in an approved template. New tool = new recipe = Homi's approval (as already locked).

**Machine-readable model list:** `~/assets/models.json` (file, licence, `commercial_ok`, sha256). `MODEL-REGISTER.md` stays the human version; **both are updated together**. The receiver reads `models.json` to fill the manifest and apply the early licence gate — it never guesses a licence.

**First recipes (built with the receiver):**
| Recipe | Engine | Commercial | Purpose |
|---|---|---|---|
| `test-image-cutout` | ComfyUI: SDXL Turbo + BiRefNet | **no** (test only) | Prove the image path |
| `voice-en-standard` | Kokoro `af_heart` + whisper check + loudness −16 LUFS | **yes** | First real, commercial-OK recipe |
| `app-icon-flat` | ComfyUI: commercial model (after NVMe) + BiRefNet | yes | Added in step 8 |

---

## 7. How a job runs

1. **Queue:** one job at a time, first come first served (protects GPU and RAM).
2. **State in files:** `~/assets/jobs/<id>/status.json` (`queued → running → done / failed`). If homidev reboots mid-job, that job is marked `failed: interrupted` at start-up — never left hanging.
3. **Image recipe:** fill template (prefix = job ID, fresh random seed unless given) → send to ComfyUI → wait → move outputs into job folder with clean names → call `/free`.
4. **Voice recipe:** call `/free` first → `say.py` → ffmpeg loudness normalise (−16 LUFS) + trim silence → `check.py` with glossary → result (PASS/FLAG + heard text) goes into the manifest (a FLAG does not fail the job; Homi reviews every voice-over anyway).
5. **Manifest written last.** Its presence means the job is complete. Includes: all fields from the design + `glossary`, `check_result`, recipe version, sha256 per file, `commercial_ok` = strictest of all models used.
6. **Clean-up:** job folders older than 14 days deleted by a daily timer (later sub-step).
7. **Limits:** job timeout 10 min (image) / 3 min (voice) → `failed: timeout`.

---

## 8. Build plan (sub-steps, each verified before the next)

| Sub-step | What | Test |
|---|---|---|
| 9a | Env + skeleton: `/health` only, token check | curl from homi-nas with and without token |
| 9b | `models.json` + recipe loading + `GET /recipes` | lists `test-image-cutout` only when approved |
| 9c | `POST /jobs` validation (no running yet) | good request accepted; 5 bad requests each rejected with right reason |
| 9d | Queue + image engine + packaging + manifest | full image job from homi-nas → pull → stage1-check.sh PASS |
| 9e | Voice engine (`voice-en-standard`) | full voice job → pull → check |
| 9f | systemd service + reboot test + 14-day clean-up | survives reboot; interrupted job marked failed |

Estimated size: about 300–400 lines of Python in total, delivered as complete files.

---

## 9. Decisions for Homi

| # | Decision |
|---|---|
| R1 | FastAPI + uvicorn in its own env `~/receiver/venv` |
| R2 | Port 8190 + shared token in header `X-Receiver-Token` |
| R3 | Four endpoints only (health, recipes, submit, status) |
| R4 | homi-nas (Claude Code) creates the job ID; receiver rejects duplicates |
| R5 | One job at a time; state kept in `status.json` files; interrupted jobs marked failed |
| R6 | Early licence gate at submit + Stage 1 gate on homi-nas (two locks) |
| R7 | New file `~/assets/models.json` (machine register), always updated together with `MODEL-REGISTER.md` |
| R8 | Recipes = approved `recipe.json` + `workflow.json` templates; receiver only fills placeholders |
| R9 | First recipes: `test-image-cutout` (test only) and `voice-en-standard` (commercial-OK); `app-icon-flat` after NVMe |
| R10 | Voice FLAG does not fail a job (Homi reviews every voice-over); manifest records the check result |
| R11 | Build in sub-steps 9a–9f as in section 8 |

**Change to the locked build order (confirmed by Homi 1 Oct):** step 9 (receiver) moves ahead of steps 7–8 (NVMe move, commercial models). After the NVMe move, paths in `models.json` and recipes are updated.
