# homidev pipeline review — 8 Oct 2026 (Claude Code, read-only)

Reviewed: receiver v0.10 (762 lines, homidev copy identical to the git copy), all 5 recipes + workflows, `cleanup-jobs.sh`, the 4 systemd units, `homidev-audit.sh` v2.1, voice helpers, and the homi-nas tools `asset-job.sh` v1.1, `stage1-check.sh` v0.6, `review-sheet.sh` v1.1, `asset-integrate.sh` v1.1, `homidev-backup.sh` v1.0. Live checks on both machines (no changes made).

Overall: the pipeline is solid. Validation, licence gates (two locks), atomic status/manifest files, restart recovery, one-job queue and the audio clean-ups are all correct as designed. I found **no crash bugs**. Below: 4 real defects, 5 weaknesses, then tool proposals.

## A. Defects (should be fixed) — status 8 Oct 22:00: D1 fixed (asset-job v1.2 + asset-pull), D2 + D3 fixed (receiver v0.11, proven), D4 fixed (local-only binds)

| # | Where | What | Effect | Fix |
|---|---|---|---|---|
| D1 | `asset-job.sh` line 45 | Waits at most 10 min (120 × 5 s), the same as the receiver's own 10-min timeout — but the clock on homi-nas also counts queue time, Ollama unload (up to 30 s) and clean-up. | A slow or queued job can finish on homidev **after** homi-nas gave up: homi-nas prints `FAIL job … state=running`, the files stay unpulled on homidev, and there is no tool to pull them later. | Wait 15 min (receiver timeout + 5), and on timeout print the job ID with "still running on homidev — pull later with asset-pull.sh" (new tool T1). |
| D2 | receiver `run_comfyui` + `stage1-check.sh` | Images are **not** stripped of ComfyUI metadata. Checked `20261007-1401-test-image-01_raw.png`: a `tEXt` chunk `prompt` (1.2 KB) holds the whole workflow (model file names, seed, prompt). Audio has had this check since SFX5; images never got it. | Every PNG integrated into an app ships the internal prompt and workflow. Not a licence problem, but it leaks internal detail and wastes bytes. | Receiver v0.11: `magick <png> -strip` (or re-save without text chunks) for image outputs; Stage 1: FAIL if a PNG has a `prompt`/`workflow` text chunk (same rule as audio). |
| D3 | receiver | Only **Ollama** is unloaded before a ComfyUI job. LM Studio (installed today, port 1234) is not, and nothing checks the GPU for *any* other user (e.g. a job started by hand in the ComfyUI browser UI). | With a 9 GB LLM in LM Studio and an image job, both fight for 16 GB → slow swap or CUDA out-of-memory → job fails with an unclear error. This is the known L2 item. | Receiver v0.11: before every ComfyUI job also run `lms unload --all` (if `lms` exists), then read `nvidia-smi` and **fail clearly** if more than ~1.5 GB is still in use. Rule in code: services never run models in parallel. |
| D4 | homidev services | ComfyUI (8188, with `--enable-manager`) and Ollama (11434) listen on **all interfaces with no password**. Confirmed from homi-nas: `/system_stats` answers without any token. No host firewall (`ufw` not installed; `sudo` needs a password so I could not read nftables). The design relies on the router rule "homi-nas + laptop only". | Anyone who gets onto the LAN (guest Wi-Fi, a phone) can run workflows, delete queue items, and the Manager can install add-ons. The receiver's token protects only the receiver. | Smallest fix: ComfyUI `--listen 127.0.0.1` (the receiver talks locally; Homi's browser UI then via SSH tunnel or Remote Desktop), Ollama `OLLAMA_HOST=127.0.0.1` unless OpenWebUI on another machine needs it. Alternative: a host firewall (nftables) allowing only homi-nas and the laptop. Needs Homi's choice and a `sudo` paste. |

## B. Weaknesses (worth doing, not urgent)

| # | Where | Note |
|---|---|---|
| W1 | `stage1-check.sh` images | No image rules at all beyond fingerprint + cutout alpha: no size check (recipe says 1024×1024), no "normal image has no alpha", no format check. Proposed: read the expected size from the manifest's recipe and FAIL on mismatch. |
| W2 | `cleanup-jobs.sh` | Still dry run (by design until ~15 Oct). 34 job folders, 23 MB — harmless. Also `~/ComfyUI/output` keeps 15 MB of test leftovers from failed/aborted runs that the clean-up never touches. Add: delete `~/ComfyUI/output/*` files older than 14 days. |
| W3 | `homidev-backup.sh` | No delete-guard (open item 3 from the resume note, the 7 Oct checklist slip). Also docs are copied by hand — easy to forget. |
| W4 | LM Studio vs Ollama idle timers | Ollama unloads after 2 min (`OLLAMA_KEEP_ALIVE=2m`); I set LM Studio to 10 min. Consider 2 min for both, so a forgotten LLM never blocks an asset job for long. LM Studio's daemon does not start on boot (nothing to unload after a reboot, so that is safe). |
| W5 | `voice-en-standard` recipe | `glossary` is optional (default "") in the recipe, but `homidev.md` says "required, never empty". The receiver would accept an empty glossary. Either make it `required: true` in the recipe (v0.3) or leave the stricter rule to Claude. Cosmetic: `asset-job.sh` sends `requested_by: claude-code`, design says `claude-code@homi-nas`. |

Checked and fine: token comparison is constant-time; job IDs validated before any path use; template filling works on JSON objects so prompts cannot inject nodes; `{{…}}` in user text is harmless; atomic writes; interrupted jobs → failed on restart; the music loop maths (bars × 240/bpm, 75 % window, crossfade) and Stage 1's MU6 checks agree; limiter rounds logic correct; `earlyoom` running; pull key still locked to `rrsync -ro`.

## C. Tools proposed (for Homi to order)

| # | Tool | Why | Size |
|---|---|---|---|
| T1 | `asset-pull.sh <project> <job-id>` (homi-nas) | Re-pull a finished job (after D1 timeouts, a network drop, or a session that ended). Same pull key, same Stage 1 step. | small |
| T2 | Receiver **v0.11** | D2 + D3 in one version: strip image metadata; unload LM Studio; GPU-free guard with a clear error. | medium |
| T3 | `stage1-check.sh` v0.7 | Image rules (W1) + PNG hidden-workflow FAIL (D2). | small |
| T4 | Recipe `icon-cutout-basic` | Transparent PNG icons: Z-Image → BiRefNet → Invert Mask → Join Alpha (chain proven in step 4). Open item 2. | small (recipe only) |
| T5 | Recipe `video-wan22-basic` + Stage 1 video rules + review-sheet video player + integrate `.mp4/.webm` | Only **after** today's Wan 2.2 5B test clip is judged by Homi and the "no video" line in design v1.1 is changed by Homi. Stage 1: length, fps, size, no hidden workflow, file size cap for apps. | medium |
| T6 | `homidev-audit.sh` v2.2 | Add: LM Studio daemon state + "no model loaded", port 1234 local-only, Wan files registered, ComfyUI/Ollama bind addresses (D4). | small |
| T7 | `llm-test` sheet → `docs/homidev-llm-test-sheet.md` | The L4 test output turned into the hardware-vs-cloud decision table (tokens/s, GPU MiB, fits/spills, Homi's quality marks). | small, after the test |
| T8 | `homidev-backup.sh` v1.1 | Delete-guard (stop if the commit would delete tracked docs) + copy `docs/` automatically. | small |

Suggested order: T2 (D3 matters as soon as LM Studio is used) → T3 + T1 → D4 decision → T6 → T4 → T8 → T5 → T7.
