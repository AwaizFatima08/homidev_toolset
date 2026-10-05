# homidev Step 10 — Claude Code side of the asset pipeline (DRAFT v0.1)

Date: 5 Oct 2026 · Follows design v1.1 (sections 3–4) · Status: **DRAFT — nothing built until Homi locks E1–E8**

## 1. Goal
Claude Code, working in a project on homi-nas, can ask homidev for an asset, get it back checked, show it to Homi for review, and — only after Homi approves — put it into the project with a register entry.

```
Claude Code (project on homi-nas)
  1. asset-job.sh      submit → wait → pull (read-only key) → Stage 1 checks
  2. Claude looks       views every image itself, notes problems
  3. review sheet       one HTML page per batch for Homi (Stage 2)
  4. Homi decides       in chat: "approve 1,3 — reject 2: too busy"
  5. asset-integrate.sh copy approved files into the repo + ASSET-REGISTER.md row
```

## 2. What exists already (reused, not rebuilt)
| Piece | Where | State |
|---|---|---|
| Receiver v0.6 (submit/status, licence gate, Ollama unload) | homidev | ✅ |
| Recipes `image-zimage-basic` (commercial), `voice-en-standard` (commercial), `test-image-cutout` (test) | homidev | ✅ |
| Read-only pull key `~/.ssh/homidev_pull` + token copy | homi-nas | ✅ |
| `stage1-check.sh` v0.2 | homi-nas `~/ai-inbox/_tools/` | ✅ images; audio checks missing |
| 8a-6 test script (submit → wait → pull → Stage 1) | `~/ai-inbox/_test/8a6/` | rough first version of 10a |

## 3. Parts, built one at a time
| # | Part | What it does |
|---|---|---|
| **10a** | `asset-job.sh` | One command: `asset-job.sh <project> <recipe> <commercial yes/no> <inputs.json>` → health check (retries up to 3 min, homidev may be booting) → makes the job ID (next free NN) → submit → wait → `mkdir -p` + pull → Stage 1 → prints folder + PASS/FAIL. Exit code 0 only on PASS |
| **10b** | `stage1-check.sh` v0.3 | Adds the audio checks (duration > 0, loudness −16 ± 1 LUFS, true peak ≤ −1 dB, whisper result PASS) and moves FAIL jobs to `~/ai-inbox/_rejected/<job>/` with `reason.txt` |
| **10c** | review sheet | `review-sheet.sh <project>` → one self-contained HTML page per batch: thumbnail / audio player, prompt or script, recipe, model, licence, Stage 1 result, Claude's note. **View only** — Homi's decision is given in chat |
| **10d** | `asset-integrate.sh` | Only for approved jobs: copies the files into `<repo>/assets/<subfolder>/`, appends a row to `<repo>/assets/ASSET-REGISTER.md` (file, job ID, recipe, model, licence, sha256, approved by + date); refuses if `commercial_ok ≠ yes` for a commercial project |
| **10e** | Claude Code instructions | A short "How to get assets" section Claude Code reads in every project (rules below), then a pilot with one real project |

## 4. Rules Claude Code must follow (go into 10e)
1. Never integrate an asset Homi has not approved in chat.
2. Commercial projects request `commercial: yes`; the licence gate decides, never Claude.
3. Prompts with people name the audience (e.g. "Pakistani family, modest clothing"); icons ask for solid filled shapes; plain gradients are made in code, not by AI (8a-6 findings).
4. Voice requests always carry a `glossary` (1 Oct finding from step 6).
5. Always human-reviewed: health/medical content, anything for children, images with text or people, every voice-over and music track.
6. One asset type at a time; small batches (≤ 5 jobs).
7. If homidev is unreachable (Windows / Hadi's time), say so and stop — no retries in a loop.

## 5. Decisions for Homi (E1–E8)
- **E1** Build order 10a → 10b → 10c → 10d → 10e, each tested before the next?
- **E2** Tools live in `~/ai-inbox/_tools/` on homi-nas (next to stage1-check.sh), backed up by `homidev-backup.sh`?
- **E3** Review decisions are given **in chat** (no buttons in the HTML page) — simplest, and the chat is the record?
- **E4** Rejected jobs go to `~/ai-inbox/_rejected/<job>/` with `reason.txt`, deleted after 30 days (design v1.1) — the 30-day clean-up itself is **later**, not in step 10?
- **E5** Assets inside a project: `<repo>/assets/` + `<repo>/assets/ASSET-REGISTER.md` (design v1.1)?
- **E6** Claude Code instructions as a **user-level** file on homi-nas (`~/.claude/CLAUDE.md` section), so every project gets the same rules?
- **E7** Where are your project repos on homi-nas? (needed for 10d/10e)
- **E8** Pilot project for 10e — which app needs a real asset soon?

## 6. Out of scope (flagged)
Buttons/forms in the review sheet · automatic 30-day clean-up of `_rejected` · subject-touches-edge image check (needs its own small design) · new recipes (icon, cut-out) — step 11 · SFX/music — 8b/8c.
