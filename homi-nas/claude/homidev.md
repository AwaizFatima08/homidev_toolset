# homidev — asset engine (read by Claude Code on homi-nas)

Last updated: 5 Oct 2026. Full designs on homi-nas: `~/homidev_toolset/docs/homidev-asset-pipeline-design.md` (v1.1, LOCKED) and `~/homidev_toolset/docs/receiver-design.md` (v1.0).

## What it is
- Separate GPU machine on the LAN: `192.168.100.123`, user `homidev`. RTX 5060 Ti 16 GB, 16 GB RAM.
- Makes assets for projects: **images/graphics, English voice-overs, sound effects, background music**.
- NOT for: video, Urdu voice (deferred), pipeline text. Small UI animations are made by you (Claude Code) as code/Lottie, only where required. GIFs only with Homi's approval per request.
- **Only available at night when Homi boots it into Debian.** Always check it is up first; never assume.

## Current status (important)
- A **receiver** exists (v0.5, port 8190, token in `~/.config/asset-receiver/token`), and it now runs as a service that starts on boot (`asset-receiver`), but the Claude Code side (build step 10) is **not built or approved yet**.
- Approved recipes so far: `test-image-cutout` (SDXL Turbo = **non-commercial, tests only**) and `voice-en-standard` (Kokoro, commercial-OK).
- So, until step 10 is approved: **do not request assets from homidev on your own.** When a project needs an asset, write the request (type, purpose, size/duration, style, glossary for voice, where it goes) into the project's task notes and tell Homi.
- Never use SDXL Turbo output in a commercial project.

## Services (LAN only; ComfyUI and Ollama have no authentication)
| Service | Address | Notes |
|---|---|---|
| ComfyUI | `http://192.168.100.123:8188` | `/system_stats` = health check. Debian now runs from NVMe (since 5 Oct) and boots in ~20 s; give ComfyUI ~1–2 min after boot and retry for up to ~5 min |
| Ollama | `http://192.168.100.123:11434` | gpt-oss:20b; first load took ~8.5 min from the old HDD, now on NVMe (new time not yet measured) |
| Receiver | `http://192.168.100.123:8190` | needs header `X-Receiver-Token`; `/health`, `/recipes`, `POST /jobs`, `/jobs/<id>` |

## Pulling finished files (works now)
- Read-only key: `~/.ssh/homidev_pull`. It can ONLY read `~/assets/jobs` on homidev. Never use it for anything else.
- Always create the folder first, and use a path relative to `~/assets/jobs`:
```bash
mkdir -p ~/ai-inbox/<project>/<job-id>
rsync -av -e "ssh -i ~/.ssh/homidev_pull" homidev@192.168.100.123:<job-id>/ ~/ai-inbox/<project>/<job-id>/
```

## Rules for every asset
1. Job ID: `YYYYMMDD-HHMM-<project>-<type>-<nn>`; types: `image`, `icon`, `voice`, `sfx`, `music`, `gif`.
2. Files land in `~/ai-inbox/<project>/<job-id>/` first, never straight into a project.
3. **Licence gate:** commercial projects only accept assets with `commercial_ok = yes` in `manifest.json`.
4. Stage 1 checks (you): manifest + sha256, licence, image size/format/transparency, audio duration / about −16 LUFS / no clipping / no silence, voice script match, view every image.
5. Stage 2 (Homi) always reviews: health/medical content, anything for children, images with text or people, every voice-over, every music track, every GIF.
6. Stage 3 (you): move approved files to project `assets/`, add a line to `assets/ASSET-REGISTER.md` (file, job ID, recipe, model, licence, approval date). Rejected files go to `~/ai-inbox/_rejected/` with the reason.
7. Pick tools only from the approved recipe list (`GET /recipes` on the receiver). A new tool or recipe needs Homi's approval.
