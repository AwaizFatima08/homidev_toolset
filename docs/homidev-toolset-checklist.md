# homidev Toolset Checklist

Status as of 8 Oct 2026. Follows design **v1.1** (`homidev-asset-pipeline-design.md`). Tick items as they are verified, then commit this file alongside `homidev-setup.md`.

Legend: `[x]` done and verified · `[ ]` pending · *(blocked: …)* waiting on something else

---

## A. Foundation

- [x] NVIDIA 615 open driver loading (Secure Boot DKMS key enrolled via MOK)
- [x] Sleep/suspend disabled (masked) for headless use
- [x] btop, nvtop, earlyoom installed; earlyoom active
- [x] Google Chrome installed (updates via apt)
- [x] System packages upgraded (27 Sep)
- [ ] `homidev-setup.md` up to date and backed up (git + snapshot + Google Drive), done at the end of every session
- [x] `homidev-audit.sh` v2.1 (5 Oct, sha256 `4249212a…4f47`, A1–A4 locked: read-only, `--hashes` option, unregistered model = FAIL, exit 1 on FAIL): 36 PASS incl. all model sha256; in backup (commit `8603e1f`); old v1 kept as `.bak-20261005`

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
- [x] gemma4:12b-it-qat added 5 Oct (7.2 GB, Apache 2.0) — side test, see `llm-test-2026-10-05.md`; G5 = keep both, gpt-oss primary, Gemma for Urdu/medical/images
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
- [x] Sound effects (8b, **closed 7 Oct**) and music (8c, **closed 8 Oct**): see `homidev-step8bc-audio-comparison.md` v0.6 — **P1–P7 locked 6 Oct**: Stable Audio 3 Small-SFX (8b) then Small-Music (8c); ACE-Step 1.5 reserve; MusicGen blocked
  - [x] 8b-1 (6 Oct): read-only pre-check PASS — ComfyUI 0.37.0 already supports Stable Audio 3 (`sa3.py`), **no ComfyUI update**; torch 2.14.0+cu130 True (first try failed only because the shell sat in deleted `/tmp/zrec`)
  - [x] 8b-2 (6 Oct): `stable_audio_3_small_sfx.safetensors` + `t5gemma_b_b_ul2.safetensors` in `~/model-review/stable-audio-3/` (~13 min), both sha256 OK; LICENSE.md, SOURCE.txt, SHA256SUMS kept there. Q1–Q6 locked
  - [x] 8b-3a (6 Oct): Stability registration done 6 Oct (HomiLabs Solutions SMC Pvt Ltd, contact Humayun Shahzad); MODEL-REGISTER.md `4118d485…6ec4` + models.json `7e6e9d0d…22ed`; backups `*.bak-20261006` = originals; MusicGen blocked
  - [x] 8b-3b (6 Oct): both models in `~/ComfyUI/models/` (`mv -n`), sha256 OK before + after against models.json; review folder keeps licence record — **8b-3 closed**
  - [x] 8b-4 (7 Oct): T1–T7 locked; `sfx-test.sh` v1 on homi-nas; 3 test sounds via ComfyUI API, 5 s each; findings: trailing ~1 s silence, really mono, levels −14…−2 dB peak, fine prompt details ignored, workflow hidden in FLAC metadata. **SFX0–SFX8 locked** (mono, trim, peak −3 dB, FLAC master + Opus 64k, strip metadata, 3 versions per sound)
  - [x] 8b-5a (7 Oct): receiver **v0.7** (sha256 `de10a598…7afd`, backup `receiver.py.bak-20261007` = v0.6): audio outputs + sfx clean-up + int min/max; sandbox-tested; image regression PASS on homidev
  - [x] 8b-5b (7 Oct): recipe `sfx-ui-basic` v1.0 installed on homidev (recipe.json `bfd19982…d3d8`, workflow.json `04bba283…b2ac`); /recipes: commercial_ok yes, 0 skipped. Lesson: first paste ran on homi-nas by mistake (harmless) → **every paste now starts with a hostname check**
  - [x] 8b-5c (7 Oct): `stage1-check.sh` **v0.5** installed on homi-nas (sha256 `3ebb7e9a…568d`, backup `.bak-20261007` = v0.4); K1–K6; image test job still PASS
  - [x] 8b-5d (7 Oct): first real sfx jobs end-to-end `20261007-1709-test-sfx-01..03` (button tap, seeds 3001–3003): all PASS with 1 WARN each — **0.31–0.35 s silence before the click** (would feel laggy). D1–D3 locked
  - [x] 8b-6 (7 Oct): receiver **v0.8** (sha256 `0081529c…3748`, backup `receiver.py.bak-v0.7`; optional start trim `lead_keep_s`, recipes without it byte-identical to v0.7) + recipe `sfx-ui-basic` **v1.1** (`cb08f549…4fbb`, `lead_keep_s` 0.01; backup `~/assets/recipe-sfx-ui-basic-v1.0.json.bak`). Re-run `20261007-2120-test-sfx-01..03`: 0.78–0.82 s, pause before click < 0.01 s, **all Stage 1 PASS, no WARN**. Same seed → identical master audio (reproducible). **Homi's Stage 2 pick: tap 02. 8b closed.**
  - [x] 8c-1 (7 Oct): `stable_audio_3_small_music.safetensors` downloaded into `~/model-review/stable-audio-3/small-music/` (8 min), sha256 `da85866b…4b64` OK; licence byte-identical to Small-SFX (same 6 Oct registration). M1–M6 locked
  - [x] 8c-2 (7 Oct): MODEL-REGISTER `9f2fdd87…8888` + models.json `f1699315…6125` (backups `*.bak-8c`); model moved to `~/ComfyUI/models/checkpoints/`, sha256 OK before + after. S1–S4 locked
  - [x] 8c-3 (7 Oct): `~/ai-inbox/_test/8c3/music-test.sh` v1 (`38984c05…`); 3 × 30 s loops, **5 s each**, real stereo, endings (fade/stop) → not loops by themselves; clipping in 02/03 (inaudible). N1–N5 locked; Homi: quality great, demo joins acceptable
  - [x] 8c-4 (8 Oct): MU0–MU8 locked. Receiver **v0.9** (`05908d0e…`, backup `receiver.py.bak-v0.8`): music loop clean-up; recipe **`music-loop-basic` v1.0** (recipe.json `7b56f758…`, workflow.json `c3ddd55f…`); `stage1-check.sh` **v0.6** (`d23243c3…`, backup `.bak-v0.5`): music rules; image/voice/sfx unchanged
  - [x] 8c-5 (8 Oct): first real music jobs: 2 of 3 FAILED Stage 1 (OGG header said 21.41 s, audio 21.33 s) → cause: loudness "dynamic" mode + direct OGG encode. F1–F3 locked → receiver **v0.9.1** (`be613986…`, backup `receiver.py.bak-v0.9`): WAV first, then OGG; records loudness mode. Re-run `20261008-1050-test-music-01..03`: **all PASS**. **Homi's Stage 2 pick: loop 03. 8c closed.**
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
  - [x] Hadi told to pick `debian-nvme` (5 Oct)
  - [ ] ~19 Oct: decide the old `debian` entry together with the Toshiba
  - ⚠️ 5 Oct mistake (Claude's instruction): `efibootmgr -b 0003 -B` deleted the **debian-nvme** entry, not the stale one — after the reboot the firmware had removed the stale entry itself and renumbered debian-nvme to 0003 (BootCurrent: 0003). Boot files on the 970 untouched. **Rule: always list `efibootmgr` first and pick entries by label + partition, never by a number from an earlier session**
  - [x] 5 Oct: `debian-nvme` recreated as Boot0001 (partition `bf99bf22…`, 0x200000 = the 970's 1 GiB EFI); BootOrder 0000,0002,0001 — Windows still default. Note: this MSI firmware renumbers entries on reboot, so in F11 always go by the **name**
  - Recovery recipe if `debian-nvme` ever vanishes from F11: boot the old `debian` (Toshiba, while it is still connected) and re-run the 7b-3b commands
  - [ ] proposal: add a fallback loader on the 970 (`\EFI\BOOT\BOOTX64.EFI`) so it can boot even if the menu entry is lost
- [ ] Move OS to NVMe, boot from it, then retire the Toshiba
- [ ] Models on NVMe (fstab by UUID + `nofail`)
- [ ] Swap on NVMe (16–32 GB); retire the HDD swap
- 8 TB Purple: **dropped for now** (4 Oct) — 3.5" disk hard to fit; the 2.5" SATA disks can serve as archive if needed
- [x] Commercial-licence image model (build step 8a, **closed 5 Oct**) — see `homidev-step8a-image-model-comparison.md`; D1–D6 locked 5 Oct: **Z-Image-Turbo** (int8 + fp8 text encoder + VAE, Comfy-Org, Apache 2.0)
  - [x] 8a-1 (5 Oct): pre-checks — ComfyUI 0.37.0 already supports Z-Image + int8 "convrot"; 880 GB free; 11 GiB RAM available; GPU idle
  - [x] 8a-2 (5 Oct): downloaded into `~/model-review/z-image-turbo/` (revision `6fc90a3b…df5`, licence apache-2.0 recorded); all 3 sha256 OK against Hugging Face; ~43 min
  - [x] 8a-3 (5 Oct): MODEL-REGISTER (sha256 `29e1905a…3cde`) + models.json (sha256 `78bf2d4e…cb9f`) updated, backups `*.bak-20261005`; blocked: FLUX.2 klein 9B, FLUX.2 dev, FLUX.1 dev; 3 files moved into `~/ComfyUI/models/`, sha256 re-checked OK in place
  - [x] 8a-4 (5 Oct): first Z-Image image via ComfyUI API from homi-nas (`~/ai-inbox/_test/8a4/`, job `20261005-1649-test-image-01`): **31 s incl. first model load**, 1024×1024 PNG, int8 loads fine; settings: CLIPLoader `lumina2`, AuraFlow shift 3, 9 steps, cfg 1, `res_multistep`/`simple`. Visual check PASS (one centred flat apple, no text/shadow) + Homi Stage 2 OK. Finding: faint off-white rounded-square "icon tile" in the background → `app-icon-flat` recipe needs background removal and "no frame, no border" in the prompt
  - Receiver re-reads models.json and recipes on every request (`load_recipes()`), so no restart is needed after register changes (read in code, 5 Oct)
  - [x] 8a-5 (5 Oct): receiver **v0.6** (sha256 `0b3be3ff…3b3e`, backup `receiver.py.bak-20261005` = v0.5): before every ComfyUI job, unloads all Ollama models (waits ≤ 30 s, job fails if one stays); recorded as `ollama_unloaded` in status.json. Tests: (a) Gemma loaded → unloaded, job done ✅ (b) nothing loaded → `[]`, done ✅ (c) voice job unaffected, whisper 1.0 PASS ✅ (d) restart + /health v0.6 ✅. Known limitation (accepted): a chat started *during* an image job can still load a model
  - [x] 8a-6 (5 Oct): recipe **`image-zimage-basic` v1.0** (Z1–Z7: 3 Z-Image models, inputs prompt+seed, no negative prompt, 1024×1024, output `raw`) → receiver: commercial_ok = yes (first commercial-OK image recipe). 5-prompt test (T1–T4, seeds 1001–1005) through the full pipeline from homi-nas: submit → receiver → pull with read-only key → stage1-check.sh: **5/5 PASS, 10–12 s each**; Homi Stage 2: approve all
  - Findings 8a-6: (1) people default to East Asian — recipes with people must name the audience (e.g. "Pakistani family, modest clothing"); (2) icons came out as line-art and the faint icon tile remains — icon recipes need "solid filled shapes" + background removal; (3) text rendering excellent ("LiveHealthy" spelled perfectly); (4) plain gradients show slight banding — make gradients in app code, not AI
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
- [x] Step 8 (**closed 8 Oct**): commercial image model (8a, Z-Image-Turbo), sound effects (8b, Stable Audio 3 Small-SFX), music (8c, Stable Audio 3 Small-Music; ACE-Step 1.5 stays reserve)
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
- [x] Step 10: Claude Code side (**closed 6 Oct**) — design `homidev-step10-design.md` v0.1, E1–E8 locked 5 Oct (repos: `/mnt/storage/projects`; pilot = small test repo, to confirm at 10d)
  - [x] 10a (5 Oct): `~/ai-inbox/_tools/asset-job.sh` (F1–F6): health retry 3 min → recipe type lookup → job ID next free NN → submit → wait → `mkdir -p` + pull → Stage 1; exit 0/1/2/3. Tests: commercial image PASS · licence gate refused (exit 3) · wrong input refused (exit 3) · voice PASS (empty glossary is refused by the receiver → rule: never send an empty glossary)
  - [x] 10b (5 Oct): ffmpeg 5.1.9 installed on homi-nas (1 package); `stage1-check.sh` **v0.4** (sha256 `32f8f3a1…076a`, G1–G6 + K1): audio measured on homi-nas (length, loudness −16 ± 1, true peak ≤ −1 dB, ≤ 0.5 s silence at start/end), whisper mismatch = WARN, PASS / PASS with warnings / FAIL; K1: clips < 5 s within ±3 LUFS = WARN (2.08 s clip measured −17.8). `asset-job.sh` **v1.1** (sha256 `1c86fcc4…de27`): Stage 1 FAIL → `~/ai-inbox/_rejected/<job>/` + reason.txt (tested with a mock). Backups `*.bak-20261005`
  - [x] 10c (5 Oct): `review-sheet.sh` v1.0 (sha256 `45ff0ac8…a396`, L1–L7): one self-contained HTML page per batch (images + OGG players embedded, prompt/script, seed, licences, fresh Stage 1 result with WARN/FAIL lines, Claude's note from `~/ai-inbox/<project>/_notes/<job>.txt`); view only, decisions in chat. Tested: 5-image page (3.6 MB) + voice page, desktop and phone width
  - Later (step 11): voice recipe v1.1 with a gentle limiter so short clips reach −16 LUFS
  - [x] 10d (6 Oct): `asset-integrate.sh` v1.0 (sha256 `53a384a9…2505`, M1–M8): `approve <job> <repo> <subfolder>` (Stage 1 again, licence, git repo required, images → all PNG, voice → OGG only, never overwrite, ASSET-REGISTER.md row, job → `_integrated/`, no commit) and `reject <job> "<reason>"` (→ `_rejected/` + reason.txt). 7 tests passed
  - [x] 10e (6 Oct): `~/.claude/homidev.md` v2 (7-step workflow, recipes, prompt rules, Do-not list; old file `homidev.md.bak-20261006`), then v2.1 after the pilot. **Pilot** in `/mnt/storage/projects/asset-pilot` (new Claude Code session, plain request "flat app icon for a water-reminder app"): asked first, 3 jobs, accurate notes, review sheet, waited; Homi: approve 1, reject 2 (tile with white margin), reject 3 (hands read as an L); integrated; Claude Code asked before the repo's first commit → commit `4548109` on `main`
  - Pilot findings → homidev.md v2.1: full-bleed background avoids the icon tile; one `asset-job.sh` call per job; ask Homi before a repo's first commit or under an unexpected git identity
  - [x] Git identity on homi-nas commits as "Awaiz Fatima": **resolved 6 Oct — deliberate** (Awaiz-managed account); no change
- [ ] Step 11: further recipes one at a time: image → voice → sfx → music (**planned items 11a–11c done 8 Oct**)
  - [x] **11a voice limiter (8 Oct, VL1–VL6):** cause reproduced (one-pass loudnorm can't lift short, quiet, peaky clips: 2.4 s test → −29.8 LUFS). Receiver **v0.10** (`0e911ecc…`, backup `receiver.py.bak-v0.9.1`): recipes with `leveller: limiter` → measure → gain → limiter −2 dB at 4× sample rate → re-measure (≤ 4 rounds, ±0.5 LU; fails if > +20 dB needed or not within ±1). Recipe **`voice-en-standard` v0.2** (`ee4d58c1…`, backup `~/assets/recipe-voice-en-standard-v0.1.json.bak`). v0.1 recipe output identical to v0.9.1. Real jobs `20261008-1218-test-voice-01` (the 7 Oct line: −23.5 → **−16.5 LUFS**), `1219-test-voice-01/02`: all Stage 1 PASS, true peak −1.8…−2.0 dB, no flattened peaks, whisper 100 %. **Homi: "all pieces sound natural".**
  - [x] **11b (8 Oct, A1–A3):** `asset-integrate.sh` **v1.1** (`767c2689…`, backup `.bak-v1.0`): Stability AI Community Licence → one-time "Powered by Stability AI" line in `<repo>/assets/ATTRIBUTION.md` + printed reminder, never blocks; sfx/music already integrated OGG-only (proved: image/voice/sfx/music into a test repo, results identical to v1.0 apart from attribution). `review-sheet.sh` **v1.1** (`1ce2bf4a…`, backup `.bak-v1.0`): music players loop; music cards show BPM · bars · loop length
  - [x] **11c (8 Oct, A4):** `~/.claude/homidev.md` **v2.2** (`83a4b91a…`, backup `homidev.md.bak-v2.1`): sfx + music recipes, 3-versions rule, audio notes ("Homi must listen"), audio subfolders, Attribution rule (check About screen before any release build), SFX7/MU7 prompt rules
  - [ ] Q5 follow-up: when the first app ships with homidev sounds, Homi checks the About screen by hand once
  - [ ] Music: if a loop ever sounds "squashed", use the same limiter as voice v1.1 instead of loudnorm's dynamic mode; if a join lands off the beat, consider BPM detection (new tool → own decision)
  - [ ] Optional later: voice tolerance ±0.3 LU (11a jobs landed −16.2…−16.5; ±0.5 accepted)
  - [ ] Note for sfx prompts: the model adds a faint sound near the asked length (D2: left in, inaudible) — ask for a shorter length (e.g. 'Length: 0.3 seconds') if a file must be tiny

## G2. Step 12 — homidev max: LLM workbench (design v1.2; **L1–L6 locked 7 Oct**, starts after 8c)

Purpose (Homi): experiment with LLMs and use the results to decide on hardware upgrades or online resources. Stay within boundaries; Claude may hold Homi anytime.

- [ ] L1 New track "Step 12", added to design v1.2
- [ ] L2 LM Studio installed; receiver extended to unload LM Studio models before every job (like Ollama); until then auto-unload timer on and LM Studio closed when done. **Rule in code: services never run models in parallel**
- [ ] L3 Qwen + DeepSeek models sized for 16 GB VRAM, versions chosen at planning; each in MODEL-REGISTER with licence + sha256
- [ ] L4 "Deep thinking" compared fairly: same prompts on gpt-oss (high reasoning), Qwen (thinking on), DeepSeek-R1
- [ ] L5 Models that spill into system RAM wait for the second Corsair stick
- [ ] L6 Homi sends the full "max" wishlist → one ordered plan
- [ ] Test sheet: per model record speed (tokens/s), VRAM used, fits on GPU or spills, quality score → basis for the hardware / cloud decision

**Step 12 session 1 (8 Oct 2026 evening, Claude Code, S12-1..S12-6 agreed):**
  - [x] homi-nas → homidev key login (`ssh-copy-id`, Homi's decision: both machines private)
  - [x] L2 LM Studio headless (llmster 0.0.25-1, CUDA 12 engine) in `~/.lmstudio`, server 127.0.0.1:1234, JIT TTL 600 s (`settings.json.bak-install`); daemon does **not** start on boot (`lms daemon up && lms server start`). Model `qwen3.5-9b` (lmstudio-community Q4_K_M + vision mmproj, sha256 OK, `~/model-review/lmstudio/qwen3.5-9b/`); LM Studio's own proxy download crawled at 445 KB/s → fetched from HF directly and `lms import --copy`; stale download job cleared (`download-jobs-info.json.bak-20261008`). Load 4 s, 7.1 GB, unload OK.
  - [x] L3 Ollama: `qwen3.5:9b` (Apache 2.0, 5.8 GB GPU, 67 tok/s) · `deepseek-r1:14b` (MIT, 10.5 GB, 43 tok/s) · `deepseek-r1:8b` (MIT, 6.6 GB, 71 tok/s). All fit the GPU → L5 not needed. Chat models **not** in MODEL-REGISTER (G decision 5 Oct) — Homi to confirm vs L3.
  - [x] L4 fair test: `~/llm-test/run-llm-test-v2.sh` v2.0 (`aed5070c…`), results `results-20261008-1659` (copied to `docs/llm-test/`), sheet `docs/homidev-llm-test-sheet.md`. gpt-oss:20b clear winner; qwen3.5:9b + deepseek-r1:8b hit the 8000-token ceiling on 3/5 prompts (no answer); deepseek-r1:14b answered the Urdu prompt in English. Homi: Urdu column + hardware decision open.
  - [x] S12-4 video test: Wan 2.2 TI2V-5B + VAE + UMT5 fp8 (Comfy-Org repackage, Apache 2.0, sha256 OK, `~/model-review/wan2.2/` keeps LICENSE/SOURCE/SHA256SUMS) → ComfyUI folders; models.json (`fababc10…`, 15 entries) + MODEL-REGISTER.md (`72f4e3b1…`) rows added, backups `.bak-20261008`. Test clip 01 (832×480, 49 f, 20 steps, 74 s, 14.7 GB peak): style right, almost no motion. API workflow in `homidev/wan22-test/`. **Still "tests only" — design v1.1 line unchanged until Homi decides.**
  - [x] Pipeline review `docs/homidev-pipeline-review-2026-10-08.md` (D1–D4, W1–W5, T1–T8). Fixed today: **stage1-check v0.7** (`d9da6f97…`, PNG hidden-workflow FAIL/WARN by receiver version, size vs manifest, alpha WARN), **asset-job v1.2** (`b386213e…`, 15-min wait, "still running" message), **asset-pull v1.0** (`2e2459e0…`); backups `.bak-v0.6` / `.bak-v1.1`. **Receiver v0.11** built + tested on homidev, installed by Homi's sudo paste (see below). homidev.md **v2.3** (backup `.bak-v2.2`).
  - [x] Wan test clip 02 (1280×704, 121 f = 5 s, 20 steps, seed 20261008): **538 s render**, 11.1 GB GPU, RAM 9 of 15 GB. Clean ECG-style line now; heart beats but **zooms out instead of in**, faint ghost heart in the background. Frame + API workflow in `homidev/wan22-test/`. Decision for Homi: keep tests only / recipe (T5).
  - [x] T6 `homidev-audit.sh` **v2.2** (`f4aa3561…`, backup `.bak-v2.1`): section 11b — LM Studio daemon/loaded/bind, Ollama loaded, bind addresses of 8188/11434. Run: 44 pass · 2 warn (D4) · 1 fail: firmware renamed the 970 entry `debian-nvme` → `debian` again (BootCurrent 0003 = partition bf99bf22, so it boots fine); relabel paste given to Homi (sudo).
  - [x] T4 draft `icon-cutout-basic` v0.1-draft in `~/assets/recipes-draft/` (approved_by empty → receiver ignores; copy in repo `homidev/assets/recipes-draft/`). Z-Image + BiRefNet → InvertMask → JoinImageWithAlpha, outputs raw + cutout. Needs Homi: approve, move to `recipes/`, 3 test icons.
  - [x] **D4 done by Homi (8 Oct 21:50):** `comfyui.service` `--listen 127.0.0.1`, Ollama drop-in `OLLAMA_HOST=127.0.0.1:11434` (backups `*.bak-20261008`). Verified: no answer from the LAN on 8188/11434, receiver 8190 unchanged, audit 11b all PASS (46 pass · 0 warn). ComfyUI page now via Remote Desktop or `ssh -L 8188:127.0.0.1:8188 homidev@192.168.100.123`.
  - [x] Boot entry (9 Oct, Homi's paste): `efibootmgr -L` cannot rename, so recreated → **Boot0001 `debian-nvme`** (970 p1, bf99bf22), BootOrder 0000,0002,0001 (Windows default), old duplicate 0003 deleted. Lesson for checklist E: the MSI firmware drops custom labels on reboot now and then; the audit catches it, fix = recreate by partition (never rename).
  - [x] **Decisions 9 Oct (Homi):** T4 `icon-cutout-basic` **approved → v1.0 live** (6 recipes, 0 problems); LT4 first Lottie app = **echostep**; hardware: **no investment now, same hardware**; Urdu: **gpt-oss good**, Qwen second; chat models **in MODEL-REGISTER.md** as offline backup (new section; not in models.json; backup `MODEL-REGISTER.md.bak-20261009`)
  - [x] **V1 decision (Homi, 8 Oct 22:05): video stays tests only; Wan 2.2 5B stays installed; real use only in a special case with Homi's per-request approval (like GIFs) — and then T5 (recipe + Stage 1 video rules + review-sheet player) comes first.** Sensible uses if ever: full-frame flat background loop behind a splash/onboarding screen; image-to-video from an already approved illustration (start_image). Not for icon/button/loader animations (no alpha, no vector) — those stay code/Lottie.
  - [x] **Receiver v0.11 installed by Homi (8 Oct 21:05, sha `a2d03b6a…`, backup `receiver.py.bak-v0.10`).** Proof job `20261008-2108-test-image-01` (image-zimage-basic, seed 11011): LM Studio model loaded on purpose beforehand → status.json `lmstudio_unloaded: [qwen3.5-9b]`, `gpu_used_mib_before: 476`; PNG has only IHDR/cHRM/bKGD/IDAT/IEND (hidden workflow gone); Stage 1 v0.7 PASS incl. 'no hidden workflow info' + size check; 13 s.
  - [x] T8 `homidev-backup.sh` v1.1 (`483e1a45…`, backup `.bak-v1.0`): delete-guard (stops on any staged deletion unless `--allow-delete`). Session backup: git `c10773c` (no D lines), local snapshot `~/homidev_toolset-snapshots/homidev_toolset-2026-10-08-step12-c10773c.tar.gz`, Drive folder "2026-10-08 homidev step 12 backup (session 1: LM Studio, LLMs, Wan test, review)".
  - [ ] T4 icon cut-out recipe · T6 audit v2.2 · T5 video recipe only after Homi's decision

## G3. Step 13 — Lottie animations on homi-nas (LT1–LT8 agreed 8 Oct 2026, option A: homi-nas, not homidev)

- [x] LT2 env `~/lottie/venv` (python-lottie 0.7.2 AGPL-3 tool, cairosvg, pillow); helper `~/lottie/homilottie.py` v1.0 (job folder + manifest + previews; reverses shape order; copies in repo `homi-nas/lottie/`)
- [x] LT3 `lottie-check.sh` v1.0 (`acc4e57b…`); `review-sheet.sh` **v1.2** (`b562edaa…`, backup `.bak-v1.1`): embedded lottie-web 5.13 (MIT, `_tools/lib/lottie.min.js` sha `2eb76297…`), loop per manifest, click to replay; `asset-integrate.sh` **v1.2** (`121afcc0…`, backup `.bak-v1.1`): lottie → `*_lottie.json`, re-runs lottie-check
- [x] LT5 first batch (project `test`): `20261008-2150-test-lottie-01` success-tick (1.2 s, once) · `20261008-2152-test-lottie-01` heartbeat-loader (1.6 s loop) · `20261008-2150-test-lottie-03` empty-state (4 s loop). All lottie-check + Stage 1 PASS, 1–4 KB each. Lessons: Lottie draws the first shape on top (fixed in `finish()`); screen y grows downward (heart was upside down). Review sheet `~/ai-inbox/test/review-20261008-2152.html` — **Homi: all three approved (8 Oct 22:25)** → `asset-integrate.sh approve … lottie` ×3 into `/mnt/storage/projects/asset-pilot/assets/lottie/` (register rows added, jobs moved to `_integrated/`), committed there
- [x] LT6 `homidev.md` **v2.4** (backup `.bak-v2.3`): Lottie paragraph
- [ ] LT4 first real app: Homi names the app; add `lottie` package, `assets/lottie/`, usage note
- [ ] LT8 optional: homidev `lottie-render` engine (rlottie, JSON in → frames out) only if the browser preview ever misleads

## G4. Step 14 — helper tools S1–S11 (agreed 9 Oct 2026; Homi: S1–S6, S8–S11; S7 dated 15 Oct)

- [x] S4 homi-nas key in homidev `authorized_keys` locked with `from="192.168.100.122"` (backup `authorized_keys.bak-20261009`); fresh login OK, pull key still `rrsync -ro`
- [x] S2 `homidev-status.sh` v1.0 — one-screen state (receiver, GPU, loaded LLMs, services, jobs, last audit)
- [x] S1 `receiver-regression.sh` v1.0 — 5 golden jobs in project `regress` (fixed seeds 77001–77004 + fixed voice line); baseline `~/ai-inbox/_regression/golden.json` recorded 8 Oct 23:59 on receiver v0.11 (all 5 PASS); compare run 9 Oct 00:02 showed **voice is not bit-exact** (Kokoro on CPU: 28 bytes, 0.1 LU) → v1.0 final compares voice by tolerance (loudness/peak ±0.5 dB, length ±0.2 s, gain ±0.5 dB, whisper result), ComfyUI outputs by sha256 (image/icon/sfx/music were bit-identical). Baseline re-recorded 00:06, compare: **5/5 identical**. Golden copy in repo `homi-nas/ai-inbox/_regression/golden.json`
- [x] S5 `release-check.sh` v1.0 — registered assets exist + declared in pubspec, lottie package present for .json, every ATTRIBUTION credit found in lib/ or store text (echostep: PASS with 1 warning, no register yet)
- [x] S3 boot audit as **user** units (no sudo: linger already on): `homidev-audit.service` + `.timer` (OnBootSec=2min) → `~/audit-logs/<date>.txt`, 60-day retention; first log 2026-10-08_2358: 47 pass · 0 fail
- [x] S11 `lmstudio.service` user unit (daemon up + server start at boot; `ExecStop` daemon down)
- [x] S6 `ask-homidev.sh` v1.0 — gpt-oss:20b over SSH (Ollama is local-only), refuses while an asset job runs; test answer 94 tok/s
- [x] S10 `model-update-check.sh` v1.0 — Ollama manifest digest vs registry (`ollama-content-digest` header), LM Studio versions, dated licence reminders (October = Stability AI DUE); all 5 chat models current on 9 Oct
- [x] S8 voices: `am_michael`, `bm_george`, `bf_emma`, `af_bella` downloaded (sha256 OK, `~/model-review/kokoro-voices/`, Apache 2.0), copied into the Kokoro snapshot; samples page listened to → **Homi approved all four (9 Oct)** → recipe **`voice-en-standard` v0.3** (5 `choices`, backup `recipe-voice-en-standard-v0.2.json.bak`), `models.json` 19 entries + 4 MODEL-REGISTER rows (backups `.bak-20261009`/`b`); proof job with `am_michael` through the pipeline (see line below); regression golden re-recorded for recipe v0.3
- [x] Icon cut-outs: **Homi approved all three (9 Oct)** → `asset-pilot/assets/icons/` (raw + cutout each), commit `ffc4374`
- [ ] S9 upscale recipe (Real-ESRGAN ×4): **blocked by design** — the receiver accepts text/int inputs only and ComfyUI's `LoadImage` reads from its input folder; needs receiver v0.12 "image input" (base64 in `inputs`, size cap, written to `ComfyUI/input/<job>.png`). Decision for Homi (see chat 9 Oct)
- [x] **LM Studio GUI (LG1–LG5, 9 Oct 2026, Homi's request):** official AppImage 0.4.25-1 (1.01 GB, our sha `eca46744…`, `~/model-review/lmstudio/desktop/SOURCE.txt`) → `~/Applications/LM-Studio.AppImage`; wrapper `lm-studio-gui.sh` v1.1 (daemon down → GUI → server up after 25 s → on close daemon + server back); `~/.local/share/applications/lm-studio.desktop` + icon; **XFCE dock (panel-2) launcher plugin-19** between the existing launchers. Tested: window opens, API on 1234 while open (2 models visible), `lms load/ps/unload` work against the GUI engine (LG4), after close llmster + server are back. Lesson: never `pkill -f` a pattern that appears in your own command line (killed the ssh twice); kill the PID from `lms daemon status` instead. LG3: no auto-update key in settings.json — Homi unticks update checks in the GUI's App Settings if shown
- [ ] S7 (15 Oct) clean-up `--delete` + ComfyUI output folder

## H. Later / optional

- [x] ~~qwen3:14b (test for Urdu content)~~ — not needed for now: Gemma 4 12B writes good Urdu (5 Oct)
- [ ] qwen2.5-coder:14b + Continue in VS Code on homi-nas
- [ ] Docker + NVIDIA Container Toolkit
- [ ] LoRA training (AI-Toolkit or kohya_ss) for consistent app styles
- [ ] Sunshine + Moonlight (GPU remote desktop)
- [ ] RAM: SK hynix stick (not detected) **removed 7 Oct**; Homi is buying a second **Corsair CMK16GX5M1B5200Z40** (check the full part number matches); after fitting: check both seen, then one overnight memtest86+ run
- [ ] RAM upgrade to 64 GB (2 × 32 GB)
- [ ] `homidev-backup.sh`: delete-guard (stop if a commit would delete tracked docs) — after the 7 Oct checklist-deletion slip
- [ ] Tidy `~/model-review/z-image-turbo/` (keep licence record only)
