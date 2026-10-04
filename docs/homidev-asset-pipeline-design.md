# homidev Asset Pipeline — Design v1.1 (LOCKED 28 Sep 2026 — all 4 decisions in section 6 confirmed by Homi)

**Supersedes:** v1.0 (28 Sep). **Change in v1.1:** audio added back (English voice-overs, sound effects, music); Urdu voice deferred, not dropped; vtracer proposed as deferred.
**Roles:** homi-nas = dev machine (Claude Code) · homidev = asset engine (GPU) · Homi = final approver
**Change control:** any change must be proposed, critiqued and confirmed by Homi before it takes effect.

---

## 1. Scope

| In scope (V1) | Out of scope / deferred |
|---|---|
| **Images & graphics:** icons, illustrations, backgrounds, pictures | **Video generation** (none on homidev) |
| **English voice-overs** | **Urdu voice** (deferred until a good, commercial-OK voice exists) |
| **Sound effects** (UI sounds, game sounds) | Pipeline text generation |
| **Background music** (short loops) | |
| **GIF:** extreme cases only, Homi's approval per request | |

**Animations** are made by **Claude Code on homi-nas, only where required** (Lottie/code), not by homidev.

**Principles**
- Free tools only, initially. *Free to use ≠ commercial use allowed.* Every model passes the licence gate (section 4).
- Only tools that can be driven automatically (API / command line) are part of the pipeline.
- LAN only; homi-nas pulls (Option A); one request format; approved recipe list; one asset type at a time.

---

## 2. Toolset

### 2.1 Images & graphics
| Purpose | Tool | Status |
|---|---|---|
| Generation engine | ComfyUI (service, port 8188) | ✅ |
| Image model | One free, commercial-licence model (candidates: FLUX.1-schnell, SDXL base, Z-Image; licence verified at download) | ❌ after NVMe |
| Background removal | **BiRefNet**, ComfyUI built-in nodes; test passed 30 Sep (API job from homi-nas, ~24 s incl. first model load). **Chain: Remove Background → Invert Mask → Join Image with Alpha** (without Invert Mask the subject is cut out instead of the background) | ✅ |
| Upscaling | Built-in nodes + `RealESRGAN_x4plus.safetensors` (BSD-3), 4×; tested 30 Sep | ✅ |
| Resize / convert / icon sets / GIF assembly | ImageMagick | ✅ |
| SVG → PNG | Inkscape CLI | ✅ |
| Raster → SVG | vtracer | ⏸ proposed: deferred until a real SVG need |

### 2.2 Audio
| Purpose | Tool | Licence (verify at install) | Status |
|---|---|---|---|
| English voice-overs | **Kokoro TTS** (CPU, `~/voice/tts`) | Apache 2.0, commercial OK | ✅ 1 Oct |
| Voice check (does it say the right words?) | **faster-whisper** `small.en` (CPU, `~/voice/stt`) | MIT | ✅ 1 Oct |
| Sound effects | **Stable Audio Open** via ComfyUI | Stability AI Community Licence: free below a revenue threshold; **must be verified and recorded** | ❌ |
| Background music | **ACE-Step** via ComfyUI | Apache 2.0 (verify) | ❌ after NVMe |
| Trim, fade, loudness normalise, convert (OGG/MP3/WAV) | ffmpeg | LGPL/GPL (tool only) | ✅ |

**Voice setup (agreed 30 Sep):** separate environment `~/voice/` (Python 3.12 via `uv`, independent of ComfyUI); Kokoro TTS (`hexgrad/Kokoro-82M`, Apache 2.0, English voices) and faster-whisper `small.en` (MIT) run on the **CPU**, leaving the GPU to ComfyUI/Ollama; `espeak-ng` (GPL-3, tool only) installed for pronunciation.
**Memory rule (agreed 30 Sep):** homi-nas calls ComfyUI `POST /free {"unload_models":true,"free_memory":true}` after each image job and always before a voice job (tested: available RAM 3.5 → 10 GB).

### 2.3 Shared
| Purpose | Tool | Status |
|---|---|---|
| Metadata (prompt, model, licence) into files | exiftool | ✅ |
| JSON manifests | jq | ✅ |
| Job receiver (submit/status) | `~/receiver/receiver.py` (FastAPI, port 8190, token) — v0.5: image + voice engines | ✅ systemd service `asset-receiver` (starts on boot, restarts on crash) — 9f, 1 Oct |

### 2.3a Add-on and model rules (agreed 30 Sep)
- **ComfyUI-Manager:** built-in, switched on with `--enable-manager`; security level `normal` (never `weak`).
- **Add-on review:** download new add-ons into `~/node-review/` first (never straight into `custom_nodes`), read `requirements.txt`, run `pip install --dry-run`; install only if `torch`, `torchvision` and `numpy` are untouched. After every install, re-check `torch` = `2.14.0+cu130 True`.
- **Smallest add-on wins:** prefer single-purpose add-ons (ComfyUI-RMBG rejected: ~45 packages, both `onnxruntime` and `onnxruntime-gpu`).
- **Blocked models (non-commercial):** BRIA RMBG-2.0 (CC BY-NC 4.0) · SDXL Turbo (tests only).
- **No cloud API nodes (agreed 30 Sep):** ComfyUI's paid/cloud nodes (Magnific, Recraft, Wavespeed, Flux video and any other "API node") are never used in the pipeline — they cost money and send data off the LAN. Recipes may use local nodes only.
- **Prefer `.safetensors`** model files; `.pth` only from an official release, recorded in the register.
- **Model register (agreed 30 Sep):** `~/assets/MODEL-REGISTER.md` on homidev lists every installed model (source, licence, commercial_ok, sha256, date). No entry = not allowed. The receiver fills the manifest's `model_licence` / `commercial_ok` from it.
- **Background removal switched to built-in (agreed 30 Sep):** ComfyUI's own nodes + `models/background_removal/birefnet.safetensors` (Comfy-Org, MIT). The `ComfyUI_BiRefNet_ll` add-on stays only as a fallback until the cut-out test passes, then is removed.

### 2.4 Kept outside the pipeline (manual)
Krita, GIMP · Blender · Ollama + OpenWebUI (`webui`)

### 2.5 Removed (28 Sep)
InvokeAI · Upscayl · Claude desktop (+ QEMU) · RustDesk · (Antigravity was not installed)

---

## 3. File transfer protocol (unchanged from v1.0)

- **Receiver API (HTTP, LAN):** health, submit job, status
- **rsync over SSH, pulled by homi-nas:** finished files (resumable, verified)

```
1. GET  /health          (retry up to ~3 min; HDD boot is slow)
2. POST /jobs {request.json}
3. GET  /jobs/<id>       (poll every 10 s) → queued / running / done / failed
4. rsync pull ~/assets/jobs/<id>/  → files + manifest.json
5. verify sha256
6. place in ~/ai-inbox/<project>/<job-id>/   (homidev deletes jobs after 14 days)
```

| Machine | Path | Purpose |
|---|---|---|
| homidev | `~/assets/jobs/<job-id>/` | request.json, outputs, manifest.json |
| homidev | `~/assets/recipes/` | approved recipes |
| homi-nas | `~/ai-inbox/<project>/<job-id>/` | pulled, awaiting review |
| homi-nas | `~/ai-inbox/_rejected/` | rejected + reason (30 days) |
| project repo | `assets/` + `assets/ASSET-REGISTER.md` | approved, integrated |

- Job ID: `YYYYMMDD-HHMM-<project>-<type>-<nn>`; files: `<job-id>_<variant>.<ext>`
- **The job ID is always the ComfyUI `filename_prefix`.** ComfyUI caches identical jobs and returns the old files (seen in testing 30 Sep); a unique prefix per job avoids silently reusing an earlier asset.
- Types: `image`, `icon`, `voice`, `sfx`, `music`, `gif`
- **manifest.json:** `job_id, project, requested_by, asset_type, recipe, tool, model, model_licence, commercial_ok, prompt/script, negative_prompt, seed, voice (audio), glossary (voice), settings, created_at, duration_sec, files[] {name, sha256, format, size, width/height or duration/sample_rate/loudness_lufs}`
- Security: dedicated read-only SSH pull key; LAN only; firewall allows homi-nas + laptop

### 3.1 Pull key (built and tested 28 Sep 2026)
| Item | Setting |
|---|---|
| Key (homi-nas) | `~/.ssh/homidev_pull` (ed25519, **no passphrase**, so automation can use it) |
| Lock (homidev `authorized_keys`) | `restrict,command="/usr/bin/rrsync -ro /home/homidev/assets/jobs"` |
| What it can do | Read files under `~/assets/jobs` only |
| Tested as blocked | Running commands (`SSH_ORIGINAL_COMMAND does not run rsync`) · pushing files (`sending to read-only server is not allowed`) |
| Pull command | `rsync -av -e "ssh -i ~/.ssh/homidev_pull" homidev@192.168.100.123:<job-id>/ ~/ai-inbox/<project>/<job-id>/` |

**Rules**
- **One key, one job.** The pull key is never reused for anything else, and the `restrict` lock is never removed. The no-passphrase choice is safe only because of the lock.
- Remote paths are **relative** to `~/assets/jobs` (`<job-id>/`, not `/home/homidev/...`).
- The pull script must run `mkdir -p ~/ai-inbox/<project>/<job-id>` **before** rsync. rsync creates only the last folder, so the first job of a new project fails without this (found in testing).

---

## 4. File review protocol

### Stage 1: Automatic checks (Claude Code, every job)
| Check | Applies to | On failure |
|---|---|---|
| Manifest complete, sha256 matches | all | re-pull once, then reject |
| **Licence gate:** `commercial_ok = yes` for commercial projects | all | reject, never integrate |
| Dimensions, format, transparency, all icon sizes present | images/icons | auto-fix if trivial, else reject |
| Duration, sample rate, **loudness (target about −16 LUFS)**, no clipping, no silence at start/end | audio | auto-fix with ffmpeg if trivial, else reject |
| **Voice script match:** faster-whisper transcribes and compares with the requested script | voice | flag for Homi |
| Content sanity: Claude views every image | images | flag for Homi |

### Stage 2: Human review (Homi)
- Review sheet per batch: thumbnails, **audio players**, prompt/script, model, licence → ✅ / ❌ + reason
- **Always human-reviewed:** health/medical content, anything for children, images with text or people, **every voice-over and music track**, every GIF
- Project assets are reviewed with the project review; standalone assets are reviewed independently

### Stage 3: Integration (Claude Code)
Move approved files to project `assets/`; add to `ASSET-REGISTER.md` (file, job ID, recipe, model, licence, approval date). Rejection reasons improve recipes.

**States:** `requested → generated → pulled → auto-checked → approved / rejected → integrated`

---

## 5. Build order
1. ✅ Clean-up (InvokeAI, Upscayl, Claude desktop, RustDesk)
2. ✅ CLI helpers: ImageMagick, jq, exiftool, ffmpeg (vtracer deferred)
3. ✅ Pipeline folders + rsync + SSH pull key + `ai-inbox` (28 Sep; pull and both blocks tested, see 3.1)
4. ✅ ComfyUI-Manager, background removal, upscaler (30 Sep; all built-in ComfyUI nodes, tested by API job from homi-nas)
5. ✅ Manual end-to-end test with one image (30 Sep): job `20260930-2303-test-image-01` sent from homi-nas → generated + cut out on homidev → packaged with manifest → pulled with read-only key → Stage 1 draft script (`~/ai-inbox/_tools/stage1-check.sh`) PASS as non-commercial, correctly **rejected by the licence gate** as commercial.
   Findings: (a) combined models → **strictest licence wins** for `commercial_ok`; (b) Stage 1 can pass an image that misses the brief (SDXL Turbo made a pattern, not one centred apple) → Stage 2 and Claude's visual check are essential; (c) recipe `app-icon-flat` needs "single isolated object, empty space around" in the prompt and a **subject-touches-edge** check.
6. ✅ Kokoro TTS + faster-whisper, manual voice test (1 Oct): 6 s clip made on CPU in ~8 s; whisper check in 2.4 s; 100% match with glossary. **Voice requests must carry a `glossary`** (app/brand/medical names) — without it, made-up names drop the score (85%) and trigger false flags. Scripts: `~/voice/say.py`, `~/voice/check.py` (see voice-scripts.md).
   **Order change (Homi, 1 Oct):** step 9 (receiver) is built next, before steps 7–8, using test models; paths updated after the NVMe move. Receiver design: `receiver-design.md`.
7. ✅ **NVMe move** (done 5 Oct: boots from the 970 in 16.8 s, voice job ~20 s instead of ~60 s; tidy-up of boot entries pending) — decisions locked 5 Oct (Homi):
   - S1 Drive: Samsung 970 EVO Plus 2 TB (serial `S6S2NS0TB11541M`, bought used, self-test passed, erased 5 Oct). Always addressed by `/dev/disk/by-id/…`, never by `nvme0/1`.
   - S2 Layout, in this order: **EFI 1 GiB** · **swap 32 GiB** · **system ~1 TB** (Debian + models, ext4) · **~830 GiB left unallocated** (later: storage / working files / assets). Free space sits right after the system partition so the system can be grown into it.
   - S3 Move = **file copy (rsync) of the running Toshiba Debian** onto the system partition, then GRUB on the 970's own EFI → Debian no longer depends on the Windows drive. Nothing reinstalled.
   - S4 Toshiba stays connected and untouched as fallback for some time after the move.
   - S5 The 2× 512 GB NVMe (on order) stay unplugged until a real use is planned.
   - S6 Backup disk decided later (a free 1 TB SATA disk or the 8 TB, after physical rearrangement).
   - S7 Role: homidev is a **workhorse only**; all projects live on homi-nas.
8. Commercial-licence image model; Stable Audio Open (SFX); ACE-Step (music)
9. ✅ Receiver (design `receiver-design.md` v1.0). 9a–9e ✅ (1 Oct): health/token, recipes, validation, automatic image jobs, voice recipe `voice-en-standard` (first commercial-OK asset). 9f ✅ (1 Oct): `asset-receiver` service + reboot test with no login (cold boot to ComfyUI ready ≈ 6 min from HDD); daily `asset-cleanup.timer` (14 days, by job-ID date, only done/failed jobs; **dry run until ~15 Oct**, then `--delete` on Homi's OK); `homidev-backup.sh` on homi-nas (copies homidev config + homi-nas tools into git, blocks token/keys/big files, asks before commit). Recipe `app-icon-flat` after step 8
10. Claude Code side: request, pull, Stage 1 checks, review sheet
11. Further recipes one at a time: image → voice → sfx → music; GIF only when first genuinely needed

## 6. Decisions for Homi (to lock v1.1)
1. Scope as in section 1 (images + all 3 audio types; Urdu deferred; no video; animations by Claude Code)?
2. Audio tools: Kokoro, faster-whisper, Stable Audio Open (licence to verify), ACE-Step?
3. vtracer deferred until a real SVG need?
4. Build order as in section 5?
