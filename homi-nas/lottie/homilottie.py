"""homilottie.py v1.0 (8 Oct 2026) - shared helper for HomiLabs Lottie animations (LT2/LT3).

Every animation script does:   from homilottie import *   ...build an Animation...   finish(an, project, name, brief)
finish() writes the Lottie JSON into a pipeline-style job folder ~/ai-inbox/<project>/<job-id>/ with a manifest.json
that stage1-check.sh / review-sheet.sh / asset-integrate.sh understand, plus two preview PNGs (frame 0 and the middle
frame) next to the job folder in _notes/ (never inside the job folder, so Stage 1 sees no unlisted file).
Feature rules (LT2): shapes, fills, strokes, transforms, opacity, trim paths, masks only; no expressions, images, text, effects.
"""
import hashlib, json, os, sys, datetime, re
from pathlib import Path
from lottie import objects
from lottie.objects import easing
from lottie.nvector import NVector as Point
from lottie.utils.color import Color
from lottie.exporters.core import export_lottie

TOOL = "python-lottie 0.7.2 (homi-nas)"
FPS = 30


def new_animation(seconds: float, size: int = 512, fps: int = FPS, name: str = "") -> objects.Animation:
    an = objects.Animation(round(seconds * fps), fps)
    an.width = an.height = size
    an.name = name
    return an


def rgb(hexstr: str) -> Color:
    h = hexstr.lstrip("#")
    return Color(int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255)


def ease_out():
    return easing.EaseOut()


def ease_in():
    return easing.EaseIn()


def ease_inout():
    return easing.Sigmoid()


def path_from_points(points, closed=False) -> objects.Path:
    """Straight-line path through (x, y) points, in a Path shape."""
    bez = objects.Bezier()
    for x, y in points:
        bez.add_point(Point(x, y))
    bez.closed = closed
    p = objects.Path()
    p.shape.value = bez
    return p


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def finish(an: objects.Animation, project: str, name: str, brief: str, commercial="yes", loop=True) -> Path:
    """Write <job>/<job>_lottie.json + manifest.json + status.json; previews to <project>/_notes/. Returns job folder."""
    assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", project), "project must be lowercase-with-hyphens"
    assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name), "name must be lowercase-with-hyphens"
    inbox = Path.home() / "ai-inbox" / project
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M")
    for n in range(1, 100):
        job_id = f"{stamp}-{project}-lottie-{n:02d}"
        job = inbox / job_id
        if not job.exists():
            break
    job.mkdir(parents=True)
    # Lottie draws the FIRST shape in a layer's list on TOP. Scripts add shapes background-first (natural order),
    # so flip each layer's list here once, right before export.
    for layer in an.layers:
        if hasattr(layer, "shapes"):
            layer.shapes.reverse()
    out = job / f"{job_id}_lottie.json"
    with open(out, "w") as fp:
        export_lottie(an, fp, pretty=False)
    # compact: python-lottie writes floats generously; re-dump with rounded numbers to keep files small
    data = json.loads(out.read_text(), parse_float=lambda s: round(float(s), 3))
    out.write_text(json.dumps(data, separators=(",", ":"), ensure_ascii=False))
    seconds = round(an.out_point / an.frame_rate, 3)
    now = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
    manifest = {
        "job_id": job_id, "project": project, "commercial_project": commercial, "requested_by": "claude-code@homi-nas",
        "asset_type": "lottie", "recipe": "lottie-code", "recipe_version": "1.0", "tool": TOOL,
        "model": ["none"], "model_licence": {"none": "HomiLabs original vector animation (no AI model)"},
        "model_sha256": {"none": "-"}, "commercial_ok": "yes",
        "prompt": brief, "script": None, "seed": None,
        "settings": {"fps": an.frame_rate, "frames": an.out_point, "seconds": seconds, "width": an.width,
                     "height": an.height, "loop": loop, "source_script": os.path.basename(sys.argv[0])},
        "notes": "Made by Claude Code with python-lottie; checked by lottie-check.sh; Homi reviews on the review sheet.",
        "created_at": now, "receiver_version": "n/a (homi-nas, LT1)",
        "files": [{"name": out.name, "sha256": sha256(out), "format": "json", "size": out.stat().st_size,
                   "width": an.width, "height": an.height, "duration_sec": seconds}],
    }
    (job / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
    (job / "status.json").write_text(json.dumps({"job_id": job_id, "state": "done", "submitted": now,
                                                 "updated": now, "finished": now}, indent=2))
    (job / "request.json").write_text(json.dumps({"job_id": job_id, "project": project, "commercial": commercial,
                                                  "requested_by": "claude-code@homi-nas", "asset_type": "lottie",
                                                  "recipe": "lottie-code", "inputs": {"brief": brief}}, indent=2))
    # previews for Claude's own look (frame 0 and the middle frame)
    notes = inbox / "_notes"
    notes.mkdir(exist_ok=True)
    try:
        from lottie.exporters.cairo import export_png
        for tag, frame in (("f0", 0), ("mid", an.out_point // 2)):
            with open(notes / f"{job_id}-{tag}.png", "wb") as fp:
                export_png(an, fp, frame=frame)
    except Exception as e:  # preview is a convenience, never a failure
        print(f"preview render failed: {e}")
    print(f"JOB {job}")
    return job
