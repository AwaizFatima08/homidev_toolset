# homidev_toolset

Asset-generation pipeline: **homi-nas** (Claude Code, dev machine) requests assets from **homidev** (GPU asset engine).

| Folder | Lives on | Contents |
|---|---|---|
| `docs/` | — | Pipeline design v1.1, receiver design v1.0, toolset checklist, voice notes |
| `homidev/receiver/` | homidev `~/receiver/` | `receiver.py` (FastAPI, port 8190) |
| `homidev/voice/` | homidev `~/voice/` | `say.py` (Kokoro TTS), `check.py` (faster-whisper check) |
| `homidev/assets/` | homidev `~/assets/` | `models.json`, `MODEL-REGISTER.md`, approved `recipes/` |
| `homidev/homidev-audit.sh` | homidev `~/` | read-only status check (needs refresh for v1.1) |
| `homi-nas/ai-inbox/_tools/` | homi-nas `~/ai-inbox/_tools/` | Stage 1 check + receiver test scripts |
| `homi-nas/claude/homidev.md` | homi-nas `~/.claude/homidev.md` | Instructions read by Claude Code |

**Never commit:** the receiver token (`~/.config/asset-receiver/token`), SSH keys, model files, or generated assets.
