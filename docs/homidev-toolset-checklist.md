# homidev Toolset Checklist

Status as of 28 Sep 2026. Follows design **v1.1** (`homidev-asset-pipeline-design.md`). Tick items as they are verified, then commit this file alongside `homidev-setup.md`.

Legend: `[x]` done and verified · `[ ]` pending · *(blocked: …)* waiting on something else

---

## A. Foundation

- [x] NVIDIA 615 open driver loading (Secure Boot DKMS key enrolled via MOK)
- [x] Sleep/suspend disabled (masked) for headless use
- [x] btop, nvtop, earlyoom installed; earlyoom active
- [x] Google Chrome installed (updates via apt)
- [x] System packages upgraded (27 Sep)
- [ ] `homidev-setup.md` up to date and backed up (git + snapshot + Google Drive), done at the end of every session
- [ ] `homidev-audit.sh` refreshed for v1.1 (still checks InvokeAI, piper, kdenlive; should check assets folders, Kokoro, faster-whisper)

## B. AI engines

### ComfyUI (port 8188)
- [x] GPU PyTorch (2.14.0+cu130) replaces CPU build
- [x] Test image generated: SDXL Turbo, 0.29 s after load (SDXL Turbo is **non-commercial**, test use only)
- [x] Runs as systemd service `comfyui`, reachable from homi-nas, survives reboot
- [x] ComfyUI-Manager: built-in, `--enable-manager` in service, security `normal`, torch unchanged (30 Sep) — UI button still to confirm
- [x] Background-removal add-on `ComfyUI_BiRefNet_ll` installed + loads cleanly (30 Sep); only opencv-python + timm added; torch unchanged
- [x] Switched to ComfyUI **built-in** background removal (agreed 30 Sep)
- [x] `birefnet.safetensors` (Comfy-Org, MIT, 424 MB, sha256 `9ab37426…a154`) in `models/background_removal/`
- [x] `~/assets/MODEL-REGISTER.md` placed on homidev (30 Sep); SDXL Turbo file name + sha256 filled in (replace the homidev copy with the updated one)
- [x] Keep `opencv-python` + `timm`: ComfyUI core uses cv2 (`comfy/ldm/sam3/tracker.py`)
- [x] Cut-out test passed with the built-in node (30 Sep): job sent from homi-nas via API, success in ~24 s; output has alpha; correct chain needs **Invert Mask** before Join Image with Alpha
- [x] Removed add-on `ComfyUI_BiRefNet_ll` and parked `ComfyUI-RMBG`; built-in re-tested OK after restart (30 Sep) — **4b closed**
- Lesson: ComfyUI **caches identical jobs** (a repeat returns the old files, nothing new is made). The receiver must give every job a unique `filename_prefix` (= job ID)
- [x] Upscaler: built-in nodes; `RealESRGAN_x4plus.safetensors` (Comfy-Org, BSD-3, 64 MB, sha256 `37f9a931…60bb`) downloaded 30 Sep
- [x] Upscale test passed 30 Sep: 512 → 2048 px, sharp result, slight "smoothed" texture in fur/snow (normal for Real-ESRGAN, fine for app assets) — **step 4 complete**

### Ollama (port 11434)
- [x] Updated (0.34.4), service active
- [x] gpt-oss:20b pulled, 100% GPU (12 GB VRAM); llama3.1:8b removed
- [x] Override file: `OLLAMA_HOST=0.0.0.0:11434`, `OLLAMA_KEEP_ALIVE=2m`, `OLLAMA_CONTEXT_LENGTH=8192`; reachable from homi-nas, survives reboot

### OpenWebUI (port 8080, manual)
- [x] v0.11.4 in `~/open-webui`; data moved out of the venv to `~/open-webui/data` (`DATA_DIR`), integrity check `ok`, admin login works, chats reach gpt-oss
- [x] Start method decided: **B, manual shortcut** `~/.local/bin/webui`
- [ ] Shortcut tested (run `webui`, open from laptop, log in)

## C. Clean-up and CLI helpers (build steps 1–2 ✅)

- [x] Remove InvokeAI (+ `uv cache clean`, 9 GB freed, ComfyUI verified OK)
- [x] Remove Upscayl (AppImage)
- [x] Antigravity: not actually installed
- [x] Remove Claude desktop + 41 QEMU packages + its settings
- [x] Remove RustDesk; remote access = SSH + Chrome Remote Desktop only
- [x] ImageMagick 7.1.1-43 · jq 1.7.1 · exiftool · ffmpeg 7.1.5 (all tested 28 Sep)
- [ ] vtracer: deferred until a real SVG need
- [ ] Tidy home folder:
  - [ ] `sudo apt autoremove` (libxdo3)
  - [ ] Old Chrome Remote Desktop `.deb` files: not in home folder any more, check `~/Downloads`
  - [ ] Delete `homidev-toolset-checklist (1).md` (old copy)
  - [ ] Decide on `start-novnc.sh` (not running; keep or delete)
  - [ ] Check what `specs.html` is (keep or delete)

## D. Audio tools (design v1.1)

- [x] Kokoro TTS (1 Oct): `~/voice/tts`, CPU, voice `af_heart`, clear speech; espeak-ng + en_core_web_sm installed
- [x] faster-whisper `small.en` (1 Oct): `~/voice/stt`, CPU; check.py v0.3 with glossary → 100% PASS
- [ ] Later: try a British/other voice; loudness normalise to −16 LUFS with ffmpeg (Stage 1 audio checks, step 10)
- [ ] Stable Audio Open, SFX *(after NVMe; licence to verify and record)*
- [ ] ACE-Step, music *(after NVMe; licence to verify)*
- Urdu voice: deferred · Piper, Kdenlive: not needed

## E. Storage and the NVMe move (build step 7)

- [x] Debian's boot files are **on the Windows NVMe (`nvme0n1p1`)**, not on `sde`. Cloning `sde` alone will NOT be enough
- [x] Swap: 15 GB partition on the Toshiba HDD (`/dev/sde2`), fine for now
- [ ] Decide move method: clone + create own EFI partition, or fresh install with its own EFI
- [ ] Check the Z690 manual's M.2/SATA lane-sharing table
- [ ] Buy NVMes (consider 1 TB for the models drive); confirm ≥ 465.8 GB for the OS drive
- [ ] Move OS to NVMe #1, boot from it, then retire the Toshiba
- [ ] NVMe #2 mounted for models (fstab by UUID + `nofail`)
- [ ] Swap on NVMe (16–32 GB); retire the HDD swap
- [ ] 8 TB Purple mounted as archive (outputs, old models)
- [ ] Commercial-licence image model (build step 8)

## F. Network (after the revamp)

- [ ] Firewall: only homi-nas + laptop may reach 8188 / 8080 / 11434 / receiver port / SSH
- [ ] Wake-on-LAN
- [ ] Debian as default boot; Windows Update "active hours" on Hadi's side
- [ ] Tailscale (remote access from outside home)

## G. Asset pipeline (build order in design v1.1)

- [x] **Step 3:** folders + rsync + pull key (28 Sep)
  - [x] homidev: `~/assets/jobs`, `~/assets/recipes`; rsync 3.4.1; `/usr/bin/rrsync`
  - [x] homi-nas: `~/ai-inbox/_rejected`; key `~/.ssh/homidev_pull`
  - [x] Key locked: `restrict` + `rrsync -ro ~/assets/jobs`
  - [x] Pull test passed; running commands blocked; pushing blocked
  - [x] Test files and stray `~/ai-inbox` on homidev removed
- [x] Step 4: ComfyUI-Manager, BG removal, upscaler (30 Sep; all built-in, jobs sent from homi-nas via API)
- [x] Step 5: manual end-to-end image test (30 Sep) — generate → package + manifest → pull → Stage 1 draft checks; licence gate rejected SDXL Turbo output for a commercial project as intended
  - [x] homi-nas: `~/ai-inbox/_tools/stage1-check.sh` (draft v0.1), `~/ai-inbox/test/<job-id>/`
  - [ ] Clean up later: `~/ai-inbox/_test/` scratch files (homidev job `20260930-2303-test-image-01` deleted by hand 1 Oct; it had no status.json so the clean-up script would never remove it)
- [x] Step 6: Kokoro + faster-whisper voice test (1 Oct)
- [ ] Step 7: NVMe move
- [ ] Step 8: commercial image model, Stable Audio Open, ACE-Step
- [ ] Step 9: receiver (design `receiver-design.md` v1.0, approved 1 Oct; built before NVMe by Homi's decision)
  - [x] 9a env `~/receiver/venv` (FastAPI+uvicorn), token `~/.config/asset-receiver/token` on both machines, `/health` 200 with token / 401 without
  - [x] 9b `~/assets/models.json` + recipe `test-image-cutout`; `/recipes` shows commercial_ok=no; unapproved recipe ignored
  - [x] 9c `POST /jobs` validation (1 Oct): receiver v0.3 (sha256 `9b3aeddd…d8b9`); 10/10 tests correct incl. licence gate; test script `~/ai-inbox/_tools/receiver-9c-tests.sh`
  - [x] 9d (1 Oct): receiver v0.4 (sha256 `6ff92624…46ae`) — first fully automatic image job `20261001-1050-test-image-01`: submit → running ~3 min (incl. SDXL Turbo load from HDD) → done → pulled → Stage 1 all checks pass; stage1-check.sh updated to v0.2 (request.json/status.json expected)
  - [x] 9e (1 Oct): receiver v0.5 (sha256 `ed9ae0c1…86c0`), check.py v0.4, recipe `voice-en-standard` (WAV + OGG/Opus, trim 0.1 s, −16 LUFS, af_heart only). First voice job: ~60 s, 6.6 s clip, −16.2 LUFS, OGG 60 KB vs WAV 315 KB, whisper 100% with glossary, Stage 1 PASS **as commercial** (first asset through the licence gate). Stage 2: **approved by Homi** (voice good) — **9e closed**
  - [x] 9f systemd service + reboot + 14-day clean-up + one-command backup (plan F1–F4 approved 1 Oct)
    - [x] 9f-1 (1 Oct): `asset-receiver.service` (sha256 `44733fb0…880e1`) enabled; `/health` from homi-nas OK; crash test: killed → back in 5 s with new PID
    - [x] 9f-2 reboot test (no login) + one voice job under the service
      - [x] Receiver up with nobody logged in (1 Oct). Cold-boot timing: reboot 19:57 → receiver 20:01 → ComfyUI ready 20:03 (~6 min total; ComfyUI start ~2.5 min from HDD, mostly loading PyTorch). Expect faster after the NVMe move
      - [x] Voice job `20261001-2006-test-voice-01` under the service: ~60 s, Stage 1 PASS as commercial, whisper 100%, same size/loudness as the morning job (needed `chmod +x` on homi-nas `_tools/*.sh`)
    - [x] 9f-3 daily 14-day clean-up (dry run first)
      - [x] `~/receiver/cleanup-jobs.sh` v1.0 (sha256 `d2e96e6d…`): dry run OK (would delete 0); `--days 0` lists only finished jobs; delete test removed only a fake 2026-01-01 job
      - [x] `asset-cleanup.timer` (daily 03:00, Persistent) enabled 1 Oct; first run logged: DRY RUN, would delete 0, kept 3
      - [ ] ~15 Oct: check the log lists the 1 Oct jobs, then add `--delete` to `asset-cleanup.service` (decision pending Homi)
    - [x] 9f-4 `homidev-backup.sh` v1.0 on homi-nas (sha256 `3aa2c18a…`; normal SSH login; Drive stays manual via Claude). First run 1 Oct: safety checks PASS, commit `cdd2c5a` pushed
- [ ] Step 10: Claude Code side (request, pull with `mkdir -p` first, Stage 1 checks, review sheet)
- [ ] Step 11: further recipes one at a time: image → voice → sfx → music

## H. Later / optional

- [ ] qwen3:14b (test for Urdu content)
- [ ] qwen2.5-coder:14b + Continue in VS Code on homi-nas
- [ ] Docker + NVIDIA Container Toolkit
- [ ] LoRA training (AI-Toolkit or kohya_ss) for consistent app styles
- [ ] Sunshine + Moonlight (GPU remote desktop)
- [ ] RAM upgrade to 64 GB (2 × 32 GB)
