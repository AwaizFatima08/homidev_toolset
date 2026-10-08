# HomiLabs Lottie animations (LT1-LT8, 8 Oct 2026)

Made on homi-nas by Claude Code with python-lottie (AGPL-3 tool; output is HomiLabs' own vector work, no AI model, no attribution).

- Environment: `~/lottie/venv` (python3 -m venv; `pip install -r requirements.txt`).
- One script per animation under `animations/<project>/<name>.py`; it imports `homilottie.py` and ends with `finish(...)`,
  which writes a pipeline-style job folder `~/ai-inbox/<project>/<job-id>/` (JSON + manifest + status + request) and two
  preview PNGs into `~/ai-inbox/<project>/_notes/`.
- Drawing order: scripts add shapes background-first; `finish()` reverses each layer's list because Lottie draws the first shape on top.
- Screen coordinates: y grows downward (the heart was upside down once).
- Checks: `~/ai-inbox/_tools/lottie-check.sh <job>` (fps <= 30, 0.3-10 s, 512x512, <= 50 KB warn / 150 KB fail, no expressions,
  images, text layers, effects; renders frame 0) and the normal `stage1-check.sh`.
- Review: `review-sheet.sh` v1.2 embeds lottie-web 5.13 (MIT, `_tools/lib/lottie.min.js`) so the animations play on the page.
- Integrate: `asset-integrate.sh approve <job> <repo> lottie` copies `<job>_lottie.json` into `assets/lottie/` + register row.
- Flutter: add `lottie: ^3.3.0` to pubspec, declare `assets/lottie/`, then `Lottie.asset('assets/lottie/<name>.json', repeat: true)`.
  Flutter's package renders the Lottie-Android feature set: shapes, fills, strokes, transforms, opacity, trim paths, masks. No expressions.
