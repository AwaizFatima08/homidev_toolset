# homidev Toolset Checklist

Status as of 5 Oct 2026. Follows design **v1.1** (`homidev-asset-pipeline-design.md`). Tick items as they are verified, then commit this file alongside `homidev-setup.md`.

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

**Rule (4 Oct):** disk names (`nvme0`, `sde` …) change between boots — they already swapped once. Always identify disks by **model + serial**, never by name. Old notes below that use names are history only.

Hardware as found 4 Oct (board **MSI PRO Z690-A WIFI**, 4× M.2, 6× SATA):
| Disk | Model / serial | Size | Role |
|---|---|---|---|
| NVMe (PCIe 4.0 x4) | WD Blue SN5000 1TB / `25274W802782` | 1 TB | **Windows (Hadi) — never touch.** Also holds Debian's EFI boot files today |
| NVMe in **M2_2** (PCIe 3.0 x4, full speed for this drive) | Samsung 970 EVO Plus 2TB / `S6S2NS0TB11541M` | 2 TB | **NEW, empty** (installed 4 Oct) |
| SATA | TOSHIBA MQ01ABD050 / `68A4S60IS` | 500 GB | current Debian OS disk (was `sde`, now `sdc`) — to confirm |
| SATA | Seagate ST500LT012 / `W0V17ATZ` | 500 GB | ? |
| SATA | WD WD10JPVX / `WD-WXC1A75K7XA4` | 1 TB | ? |
| SATA | WD WD10SPZX / `WD-WXT1A8838CCS` | 1 TB | ? |
| SATA | HGST HTS541010A9E680 / `160812JD10424A16BV4T` | 1 TB | ? |

- [x] Debian's boot files are on the **Windows NVMe (WD SN5000)**, not on the Toshiba. Cloning the Toshiba alone will NOT be enough
- [x] Swap: 15 GB partition on the Toshiba HDD, fine for now
- [x] 2 TB NVMe installed in M2_2 (4 Oct); all 5 SATA disks still visible after install
- [x] 2 TB NVMe health check (4 Oct): critical warning 0, media errors 0, 1% used, 28 °C, firmware 4B2QEXM7 — **but NOT unused: 2,268 power-on hours, 14.5 TB written** (rated ~1,200 TB, so ~1% of its life). Healthy. Bought used from a trusted vendor (Homi, 4 Oct) — readings match a lightly used drive
- [x] 2 TB NVMe extended self-test: **Completed without error** (at 2,268 h)
- [x] 2 TB NVMe erased 5 Oct (`blkdiscard` via by-id path, approved by Homi): previous owner's Windows install gone, drive blank; WD (Windows) and all SATA disks unchanged
- Found 5 Oct: the Toshiba (Debian) has its **own** 487 MB vfat partition (UUID `7139-3D42`) — **unused**: fstab mounts `/boot/efi` from `DCC3-636B` on the WD (Windows) drive
- Numbers 5 Oct (before the move): Debian root 53 GB used of 443 GB; ComfyUI models 7 GB, Ollama 14 GB, Hugging Face cache 1.7 GB → 1 TB system partition is ample
- fstab today: `/` = UUID `b91d7e5b…`, `/boot/efi` = `DCC3-636B` (WD drive), swap = UUID `4db75810…` (Toshiba) — all three change in 7b
- Firmware boot entries 5 Oct: 0000 Windows (WD) · 0002 debian (on WD's EFI, currently used) · **0003 stale** "Windows Boot Manager" pointing at the 970's erased old EFI → remove in 7c; BootOrder lists Windows first — set new debian entry first in 7c
- Found 5 Oct: the other 4 SATA disks hold NTFS data (labels HGST1/HGST2, Transcend, Epic, "Toshiba" on the Seagate) — find out whose data before planning any of them as archive
- Lesson 4–5 Oct: after a reboot the NVMe names swapped again (970 = nvme0 → nvme1); one self-test ran on the WD by mistake (read-only, harmless). All commands now use `/dev/disk/by-id/…<serial>`; controller derived with `readlink -f`
- [ ] 2× 512 GB NVMe on order (4 Oct) — purpose to decide; with them all 4 M.2 slots are full. Check every disk is still visible after installing them (M2_3 / M2_4 can also run SATA mode)
- [x] Layout + move method decided 5 Oct — see design doc step 7 (S1–S7): EFI 1 GiB + swap 32 GiB + system ~1 TB + ~830 GiB unallocated; rsync copy of the Toshiba; own EFI on the 970
- [x] 7a (5 Oct): partitions on the 970 — p1 1 GiB EF00 `homidev-efi` (vfat, label HD-EFI) · p2 32 GiB 8200 `homidev-swap` (UUID `9261597b-9c91-4115-87af-97d441c9eb0b`) · p3 1000 GiB 8300 `homidev-system` (ext4, label hd-system, UUID `e774525b-0f05-43cb-bd98-a6930e1d08e3`) · 830 GiB free after p3
- How homidev boots (Homi, 5 Oct): default = **Windows**; Debian is chosen by pressing **F11** at start (boot menu). Debian runs at night; Hadi reboots into Debian when he finishes. → After a power cut homidev comes up in Windows (receiver unavailable) — known limitation
- [x] 7b copy Debian + bootloader — plan P1–P5 approved 5 Oct (stop services · rsync copy · new IDs in fstab + resume in the copy only · GRUB on the 970's EFI + new boot entry `debian-nvme` · nothing else changes)
  - [x] 7b-1 (5 Oct): services stopped, rsync copy 55.3 GB in 27 min (Toshiba reads ~32 MB/s), exit 0, services restarted; both sides 53G
  - [x] 7b-2 (5 Oct): copy's fstab → system `e774525b…`, EFI `3109-7BAD`, swap `9261597b…`; `resume` → `9261597b…`; backups in the copy's `/root/before-nvme/` (NOT in conf.d — initramfs reads every file there); running system's fstab untouched
  - [x] 7b-3a (5 Oct): chroot → `grub-install --no-nvram` (shim/grub/mm on the 970's EFI, "No error reported"), initramfs rebuilt, `update-grub` (system ID ×12; Toshiba Debian added as extra menu choice)
  - [x] 7b-3b (5 Oct): firmware entry **Boot0001 `debian-nvme`** → 970 EFI `\EFI\debian\shimx64.efi`; BootOrder kept 0000,0002,0003,0001 (Windows still default)
  - [x] 7b-3c (5 Oct): copy unmounted cleanly; running system + services OK
- [ ] 7c boot from the 970, test everything (services, receiver, voice + image job), BIOS boot order
  - [x] 5 Oct: first start via F11 → `debian-nvme`: `/` = nvme…p3 hd-system, `/boot/efi` = nvme…p1 HD-EFI, root=UUID `e774525b…`, SecureBoot enabled, NVIDIA 615.71.09 sees RTX 5060 Ti, all 4 services active, no failed units. **Boot 16.8 s** (kernel 7.8 + userspace 9.0) vs ~3.5 min from the Toshiba
  - [x] swap = nvme1n1p2 32 GB (Toshiba swap no longer used); voice job `20261005-0010-test-voice-01` from homi-nas: **~20 s** (was ~60 s from the HDD), Stage 1 PASS as commercial, whisper 100%, −16.2 LUFS; receiver reports 945.7 GB free
  - [ ] later: decide the old `debian` entry, tell Hadi which entry to pick
  - ⚠️ 5 Oct mistake (Claude's instruction): `efibootmgr -b 0003 -B` deleted the **debian-nvme** entry, not the stale one — after the reboot the firmware had removed the stale entry itself and renumbered debian-nvme to 0003 (BootCurrent: 0003). Boot files on the 970 untouched. **Rule: always list `efibootmgr` first and pick entries by label + partition, never by a number from an earlier session**
  - [x] 5 Oct: `debian-nvme` recreated as Boot0001 (partition `bf99bf22…`, 0x200000 = the 970's 1 GiB EFI); BootOrder 0000,0002,0001 — Windows still default. Note: this MSI firmware renumbers entries on reboot, so in F11 always go by the **name**
  - Recovery recipe if `debian-nvme` ever vanishes from F11: boot the old `debian` (Toshiba, while it is still connected) and re-run the 7b-3b commands
  - [ ] proposal: add a fallback loader on the 970 (`\EFI\BOOT\BOOTX64.EFI`) so it can boot even if the menu entry is lost
- [ ] Move OS to NVMe, boot from it, then retire the Toshiba
- [ ] Models on NVMe (fstab by UUID + `nofail`)
- [ ] Swap on NVMe (16–32 GB); retire the HDD swap
- 8 TB Purple: **dropped for now** (4 Oct) — 3.5" disk hard to fit; the 2.5" SATA disks can serve as archive if needed
- [ ] Commercial-licence image model (build step 8a) — see `homidev-step8a-image-model-comparison.md`; D1–D6 locked 5 Oct: **Z-Image-Turbo** (int8 + fp8 text encoder + VAE, Comfy-Org, Apache 2.0)
  - [x] 8a-1 (5 Oct): pre-checks — ComfyUI 0.37.0 already supports Z-Image + int8 "convrot"; 880 GB free; 11 GiB RAM available; GPU idle
  - [x] 8a-2 (5 Oct): downloaded into `~/model-review/z-image-turbo/` (revision `6fc90a3b…df5`, licence apache-2.0 recorded); all 3 sha256 OK against Hugging Face; ~43 min
  - [x] 8a-3 (5 Oct): MODEL-REGISTER (sha256 `29e1905a…3cde`) + models.json (sha256 `78bf2d4e…cb9f`) updated, backups `*.bak-20261005`; blocked: FLUX.2 klein 9B, FLUX.2 dev, FLUX.1 dev; 3 files moved into `~/ComfyUI/models/`, sha256 re-checked OK in place
  - [ ] 8a-4 first manual test image (API job from homi-nas); check whether the receiver re-reads models.json without restart
  - [ ] 8a-5 receiver v0.6: unload Ollama before every image job (D6) + test
  - [ ] 8a-6 5-prompt quality test, Stage 1 + Stage 2 → 8a closed
  - Lesson 5 Oct: a wrong (old) `models.json` arrived by download under the right name; the fingerprint check caught it. **Rules: check-and-install commands are always chained with `&&` so a failed check stops the copy; small config files can be written on homidev with a heredoc and checked by sha256**

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
- [x] Step 7: NVMe move (5 Oct; boot-entry tidy-up pending, see E)
- [ ] Step 8: commercial image model (8a in progress, see E), Stable Audio Open, ACE-Step
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
