# receiver.py - homidev asset receiver
# v0.5 (2 Oct 2026) - step 9e: + voice engine (Kokoro -> trim/loudness -> WAV+OGG -> whisper check)
# v0.4 - step 9d: real jobs for ComfyUI recipes
#   POST /jobs validates -> creates ~/assets/jobs/<id>/ -> queue (one job at a time)
#   worker fills the approved workflow template, runs ComfyUI, moves outputs,
#   calls /free, writes manifest.json LAST. GET /jobs/<id> shows progress.
# Runs from ~/receiver with:  venv/bin/uvicorn receiver:app --host 0.0.0.0 --port 8190
import hashlib
import json
import os
import queue
import re
import secrets
import shutil
import subprocess
import tempfile
import threading
import time
import urllib.error
import urllib.request
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path
from typing import Literal

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

VERSION = "0.5"
HOME = Path.home()
ASSETS = HOME / "assets"
JOBS_DIR = ASSETS / "jobs"
MODELS_FILE = ASSETS / "models.json"
RECIPES_DIR = ASSETS / "recipes"
TOKEN_FILE = HOME / ".config" / "asset-receiver" / "token"
COMFY = "http://127.0.0.1:8188"
COMFY_OUTPUT = HOME / "ComfyUI" / "output"
ENGINES = {"comfyui", "kokoro"}
ASSET_TYPES = {"image", "icon", "voice", "sfx", "music", "gif"}
PROJECT_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
JOB_ID_SAFE = re.compile(r"^[a-z0-9-]{10,120}$")
IMAGE_TIMEOUT_S = 600
VOICE_TIMEOUT_S = 180
VOICE_DIR = HOME / "voice"
TTS_PY = VOICE_DIR / "tts" / "bin" / "python"
STT_PY = VOICE_DIR / "stt" / "bin" / "python"
MIN_FREE_GB = 5

# --- token: refuse to start without a proper one ---
try:
    TOKEN = TOKEN_FILE.read_text().strip()
except FileNotFoundError:
    raise SystemExit(f"Token file missing: {TOKEN_FILE}")
if len(TOKEN) < 32:
    raise SystemExit(f"Token in {TOKEN_FILE} is too short")


def check_token(x_receiver_token: str = Header(default="")):
    if not secrets.compare_digest(x_receiver_token.encode(), TOKEN.encode()):
        raise HTTPException(status_code=401, detail="invalid or missing X-Receiver-Token")


# ---------------------------------------------------------------- small helpers
def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def write_json(path: Path, data: dict):
    """Write atomically: a half-written status or manifest can never be read."""
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    os.replace(tmp, path)


def set_status(job_dir: Path, state: str, **extra):
    f = job_dir / "status.json"
    st = json.loads(f.read_text()) if f.exists() else {}
    st.update(state=state, updated=now(), **extra)
    write_json(f, st)
    print(f"[receiver] {job_dir.name}: {state} {extra.get('error', '')}", flush=True)


def comfy_get(path: str, timeout: int = 5):
    with urllib.request.urlopen(f"{COMFY}{path}", timeout=timeout) as r:
        return json.load(r)


def comfy_post(path: str, body: dict, timeout: int = 10):
    req = urllib.request.Request(f"{COMFY}{path}", data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:   # ComfyUI explains rejections in the body
        raise RuntimeError(f"ComfyUI {path} answered {e.code}: {e.read().decode(errors='replace')[:400]}")


def comfyui_status() -> str:
    try:
        return "ok (" + comfy_get("/system_stats", 3)["system"]["comfyui_version"] + ")"
    except Exception:
        return "down"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for block in iter(lambda: fh.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def image_info(path: Path) -> dict:
    out = subprocess.run(["magick", "identify", "-format", "%w %h %A", str(path)],
                         capture_output=True, text=True, check=True).stdout.split()
    return {"width": int(out[0]), "height": int(out[1]), "alpha": out[2]}


# ---------------------------------------------------------------- models and recipes
def load_models() -> dict:
    """Read the machine model register. A broken register means no recipe may run."""
    return json.loads(MODELS_FILE.read_text())["models"]


def load_recipes() -> tuple[dict, list]:
    """Return (approved recipes, list of problems). Files are re-read on every call,
    so new or changed recipes need no restart."""
    try:
        models = load_models()
    except Exception as e:
        return {}, [f"models.json unreadable: {e}"]
    recipes, problems = {}, []
    if not RECIPES_DIR.is_dir():
        return {}, [f"recipes folder missing: {RECIPES_DIR}"]
    for d in sorted(p for p in RECIPES_DIR.iterdir() if p.is_dir()):
        try:
            r = json.loads((d / "recipe.json").read_text())
        except Exception as e:
            problems.append(f"{d.name}: recipe.json unreadable ({e})")
            continue
        if not r.get("approved_by"):
            problems.append(f"{d.name}: not approved - ignored")
            continue
        if r.get("name") != d.name:
            problems.append(f"{d.name}: name in recipe.json does not match folder")
            continue
        if r.get("engine") not in ENGINES:
            problems.append(f"{d.name}: unknown engine {r.get('engine')!r}")
            continue
        unknown = [m for m in r.get("models", []) if m not in models]
        if unknown:
            problems.append(f"{d.name}: models not in models.json: {unknown}")
            continue
        absent = [m for m in r["models"] if not (HOME / models[m]["file"]).exists()]
        if absent:
            problems.append(f"{d.name}: model files missing on disk: {absent}")
            continue
        if r["engine"] == "comfyui":
            try:
                json.loads((d / "workflow.json").read_text())
            except Exception as e:
                problems.append(f"{d.name}: workflow.json unreadable ({e})")
                continue
        # strictest licence wins
        r["commercial_ok"] = "yes" if all(models[m]["commercial_ok"] == "yes" for m in r["models"]) else "no"
        r["model_licences"] = {m: models[m]["licence"] for m in r["models"]}
        r["model_sha256"] = {m: models[m]["sha256"] for m in r["models"]}
        recipes[d.name] = r
    return recipes, problems


# ---------------------------------------------------------------- job requests
class JobRequest(BaseModel):
    job_id: str = Field(max_length=120)
    project: str = Field(max_length=40)
    commercial: Literal["yes", "no"]
    requested_by: str = Field(max_length=100)
    asset_type: str
    recipe: str = Field(max_length=60)
    inputs: dict = {}
    notes: str = Field(default="", max_length=1000)


def reject(status: int, reason: str):
    raise HTTPException(status_code=status, detail=reason)


def validate_job(req: JobRequest) -> dict:
    """All submit-time rules from receiver-design.md section 5. Returns the recipe and
    the final inputs (defaults filled in). Raises HTTPException with a clear reason."""
    # rule 2: project, asset type, job ID format and uniqueness
    if not PROJECT_RE.match(req.project):
        reject(422, "project must be lowercase letters/digits with single hyphens, e.g. livehealthy-learn")
    if req.asset_type not in ASSET_TYPES:
        reject(422, f"asset_type must be one of {sorted(ASSET_TYPES)}")
    pattern = rf"^(\d{{8}})-(\d{{4}})-{re.escape(req.project)}-{re.escape(req.asset_type)}-(\d{{2}})$"
    m = re.match(pattern, req.job_id)
    if not m:
        reject(422, f"job_id must look like YYYYMMDD-HHMM-{req.project}-{req.asset_type}-NN")
    try:
        datetime.strptime(m.group(1) + m.group(2), "%Y%m%d%H%M")
    except ValueError:
        reject(422, "job_id contains an impossible date or time")
    if (JOBS_DIR / req.job_id).exists():
        reject(409, f"job_id {req.job_id} already used")

    # rule 3: recipe exists, approved, matches asset type
    recipes, _ = load_recipes()
    recipe = recipes.get(req.recipe)
    if recipe is None:
        reject(422, f"unknown or unapproved recipe {req.recipe!r}; approved: {sorted(recipes)}")
    if recipe["asset_type"] != req.asset_type:
        reject(422, f"recipe {req.recipe} makes {recipe['asset_type']!r}, not {req.asset_type!r}")

    # rule 4: inputs - no unknown keys, required present, limits respected
    spec = recipe.get("inputs", {})
    unknown = sorted(set(req.inputs) - set(spec))
    if unknown:
        reject(422, f"unknown inputs {unknown}; allowed: {sorted(spec)}")
    final = {}
    for name, rule in spec.items():
        if name not in req.inputs:
            if rule.get("required"):
                reject(422, f"missing required input {name!r}")
            if "default" in rule:
                final[name] = rule["default"]
            continue
        value = req.inputs[name]
        if "choices" in rule and value not in rule["choices"]:
            reject(422, f"input {name!r} must be one of {rule['choices']}")
        if rule.get("type") == "int":
            if not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= 2**53:
                reject(422, f"input {name!r} must be a whole number from 0 to 2^53")
        else:
            if not isinstance(value, str) or not value.strip():
                reject(422, f"input {name!r} must be non-empty text")
            if len(value) > rule.get("max_length", 1000):
                reject(422, f"input {name!r} is longer than {rule.get('max_length', 1000)} characters")
        final[name] = value

    # rule 5: early licence gate
    if req.commercial == "yes" and recipe["commercial_ok"] != "yes":
        reject(422, f"LICENCE GATE: commercial project, but recipe {req.recipe} is not commercial-OK "
                    f"(models: {recipe['model_licences']})")

    # practical checks: engine reachable, enough disk
    if recipe["engine"] == "comfyui" and comfyui_status() == "down":
        reject(503, "ComfyUI is not reachable - try again in a minute")
    if shutil.disk_usage(ASSETS).free / 1e9 < MIN_FREE_GB:
        reject(503, f"less than {MIN_FREE_GB} GB free on homidev")
    return {"recipe": recipe, "inputs": final}


# ---------------------------------------------------------------- the worker
JOB_QUEUE: "queue.Queue[str]" = queue.Queue()
CURRENT = {"job": None}


def fill_template(node, values: dict):
    """Replace {{name}} placeholders inside the workflow. A value that is exactly
    "{{name}}" gets the real type (e.g. seed stays a number). Works on Python
    objects, never on raw JSON text, so prompts cannot break the workflow."""
    if isinstance(node, dict):
        return {k: fill_template(v, values) for k, v in node.items()}
    if isinstance(node, list):
        return [fill_template(v, values) for v in node]
    if isinstance(node, str):
        whole = re.fullmatch(r"\{\{(\w+)\}\}", node)
        if whole and whole.group(1) in values:
            return values[whole.group(1)]
        return re.sub(r"\{\{(\w+)\}\}", lambda m: str(values.get(m.group(1), m.group(0))), node)
    return node


def run_comfyui(job_dir: Path, req: dict, recipe: dict) -> dict:
    job_id = req["job_id"]
    inputs = dict(req["inputs"])
    if "seed" in recipe.get("inputs", {}) and "seed" not in inputs:
        inputs["seed"] = secrets.randbelow(2**32)
    values = {**inputs, "prefix": job_id}
    template = json.loads((RECIPES_DIR / recipe["name"] / "workflow.json").read_text())
    # check the TEMPLATE (not the filled result), so user text containing {{...}} is harmless
    needed = set(re.findall(r"\{\{(\w+)\}\}", json.dumps(template)))
    missing = sorted(needed - set(values))
    if missing:
        raise RuntimeError(f"workflow placeholders without a value: {missing}")
    workflow = fill_template(template, values)

    answer = comfy_post("/prompt", {"prompt": workflow, "client_id": "asset-receiver"})
    if answer.get("node_errors"):
        raise RuntimeError(f"ComfyUI rejected workflow: {answer['node_errors']}")
    pid = answer["prompt_id"]
    set_status(job_dir, "running", comfyui_prompt_id=pid)

    started = time.time()
    while True:
        if time.time() - started > IMAGE_TIMEOUT_S:
            try:
                comfy_post("/queue", {"delete": [pid]})
                comfy_post("/interrupt", {})
            except Exception:
                pass
            raise RuntimeError(f"timeout after {IMAGE_TIMEOUT_S} s")
        hist = comfy_get(f"/history/{pid}").get(pid)
        if hist and hist.get("status", {}).get("completed") is not None and \
                hist["status"].get("status_str") in ("success", "error"):
            break
        time.sleep(2)
    if hist["status"]["status_str"] != "success":
        raise RuntimeError(f"ComfyUI error: {hist['status'].get('messages', '')}"[:500])

    # collect outputs and move them into the job folder with clean names
    produced = [img for out in hist.get("outputs", {}).values() for img in out.get("images", [])
                if img.get("type") == "output"]
    files = []
    for variant in recipe["outputs"]:
        match = [i for i in produced if i["filename"].startswith(f"{job_id}_{variant}_")]
        if len(match) != 1:
            raise RuntimeError(f"expected 1 '{variant}' output, ComfyUI produced {len(match)}")
        src = COMFY_OUTPUT / match[0].get("subfolder", "") / match[0]["filename"]
        ext = src.suffix.lower()
        dst = job_dir / f"{job_id}_{variant}{ext}"
        shutil.move(str(src), str(dst))
        files.append({"name": dst.name, "sha256": sha256(dst), "format": ext.lstrip("."),
                      "size": dst.stat().st_size, **image_info(dst)})
    return {"inputs": inputs, "files": files,
            "tool": "ComfyUI " + comfyui_status().removeprefix("ok (").rstrip(")")}


def run_cmd(cmd: list, timeout: int, what: str) -> subprocess.CompletedProcess:
    try:
        p = subprocess.run([str(c) for c in cmd], capture_output=True, text=True,
                           timeout=timeout, cwd=VOICE_DIR)
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"{what}: timeout after {timeout} s")
    if p.returncode != 0:
        raise RuntimeError(f"{what} failed: {(p.stderr or p.stdout).strip()[-400:]}")
    return p


def audio_info(path: Path) -> dict:
    probe = json.loads(run_cmd(["ffprobe", "-v", "error", "-show_entries",
                                "stream=sample_rate,channels:format=duration", "-of", "json", path],
                               60, "ffprobe").stdout)
    meter = run_cmd(["ffmpeg", "-nostdin", "-hide_banner", "-i", path, "-af", "ebur128=peak=true",
                     "-f", "null", "-"], 60, "loudness measurement").stderr
    lufs = re.findall(r"I:\s+(-?[\d.]+) LUFS", meter)
    peak = re.findall(r"Peak:\s+(-?[\d.]+|-inf) dBFS", meter)
    stream = probe["streams"][0]
    return {"duration_sec": round(float(probe["format"]["duration"]), 2),
            "sample_rate": int(stream["sample_rate"]), "channels": stream.get("channels"),
            "loudness_lufs": float(lufs[-1]) if lufs else None,
            "true_peak_db": float(peak[-1]) if peak and peak[-1] != "-inf" else None}


def run_kokoro(job_dir: Path, req: dict, recipe: dict) -> dict:
    job_id, inputs = req["job_id"], dict(req["inputs"])
    s = recipe.get("settings", {})
    keep, lufs, tp = s.get("trim_silence_keep_s", 0.1), s.get("loudness_lufs", -16), s.get("true_peak_db", -1.5)
    wav = job_dir / f"{job_id}_voice.wav"
    ogg = job_dir / f"{job_id}_voice.ogg"
    started = time.time()
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        # 1. speech (Kokoro, CPU, own environment)
        run_cmd([TTS_PY, VOICE_DIR / "say.py", inputs["script"], raw, inputs.get("voice", "af_heart")],
                VOICE_TIMEOUT_S, "Kokoro speech")
        # 2. trim silence at both ends (keep a little), normalise loudness -> WAV master
        trim = f"silenceremove=start_periods=1:start_threshold=-50dB:start_silence={keep}"
        chain = f"{trim},areverse,{trim},areverse,loudnorm=I={lufs}:TP={tp}:LRA=11"
        run_cmd(["ffmpeg", "-nostdin", "-v", "error", "-y", "-i", raw, "-af", chain,
                 "-ar", "24000", "-ac", "1", "-c:a", "pcm_s16le", wav], 120, "trim + loudness")
    # 3. small app copy (Opus in OGG)
    run_cmd(["ffmpeg", "-nostdin", "-v", "error", "-y", "-i", wav, "-c:a", "libopus", "-b:a", "64k", ogg],
            120, "OGG encode")
    # 4. does it say the right words? (faster-whisper, CPU, own environment)
    left = max(30, VOICE_TIMEOUT_S - int(time.time() - started))
    out = run_cmd([STT_PY, VOICE_DIR / "check.py", "--json", wav, inputs["script"], inputs.get("glossary", "")],
                  left, "whisper check").stdout.strip().splitlines()
    check = json.loads(out[-1])
    files = []
    for f in (wav, ogg):
        files.append({"name": f.name, "sha256": sha256(f), "format": f.suffix.lstrip("."),
                      "size": f.stat().st_size, **audio_info(f)})
    return {"inputs": inputs, "files": files, "check": check,
            "tool": "Kokoro 0.9.4 (CPU) + ffmpeg + faster-whisper small.en"}


def free_comfyui():
    try:
        comfy_post("/free", {"unload_models": True, "free_memory": True})
    except Exception as e:
        print(f"[receiver] /free failed: {e}", flush=True)


def run_job(job_id: str):
    job_dir = JOBS_DIR / job_id
    req = json.loads((job_dir / "request.json").read_text())
    recipes, _ = load_recipes()
    recipe = recipes.get(req["recipe"])
    if recipe is None:
        raise RuntimeError(f"recipe {req['recipe']} no longer approved or available")
    set_status(job_dir, "running", started=now())
    if recipe["engine"] == "comfyui":
        try:
            result = run_comfyui(job_dir, req, recipe)
        finally:
            free_comfyui()
    elif recipe["engine"] == "kokoro":
        free_comfyui()          # memory rule: free ComfyUI before any voice job
        result = run_kokoro(job_dir, req, recipe)
    else:
        raise RuntimeError(f"engine {recipe['engine']} not supported")

    manifest = {
        "job_id": job_id,
        "project": req["project"],
        "commercial_project": req["commercial"],
        "requested_by": req["requested_by"],
        "asset_type": req["asset_type"],
        "recipe": recipe["name"],
        "recipe_version": recipe.get("version"),
        "tool": result["tool"],
        "model": recipe["models"],
        "model_licence": recipe["model_licences"],
        "model_sha256": recipe["model_sha256"],
        "commercial_ok": recipe["commercial_ok"],
        "prompt": result["inputs"].get("prompt"),
        "negative_prompt": result["inputs"].get("negative_prompt"),
        "seed": result["inputs"].get("seed"),
        "script": result["inputs"].get("script"),
        "glossary": result["inputs"].get("glossary"),
        "voice": result["inputs"].get("voice"),
        "script_check": result.get("check"),
        "settings": {**result["inputs"], **recipe.get("settings", {})},
        "notes": req.get("notes", ""),
        "created_at": now(),
        "receiver_version": VERSION,
        "files": result["files"],
    }
    write_json(job_dir / "manifest.json", manifest)   # written LAST = job complete
    set_status(job_dir, "done", finished=now())


def worker():
    while True:
        job_id = JOB_QUEUE.get()
        CURRENT["job"] = job_id
        try:
            run_job(job_id)
        except Exception as e:
            try:
                set_status(JOBS_DIR / job_id, "failed", finished=now(), error=str(e)[:500])
            except Exception:
                pass
        finally:
            CURRENT["job"] = None
            JOB_QUEUE.task_done()


def recover_jobs():
    """At start-up: a job left 'running' was interrupted -> failed.
    Jobs still 'queued' never started -> queued again, oldest first."""
    waiting = []
    for st_file in JOBS_DIR.glob("*/status.json"):
        try:
            st = json.loads(st_file.read_text())
        except Exception:
            continue
        if st.get("state") == "running":
            set_status(st_file.parent, "failed", finished=now(), error="interrupted (receiver restarted)")
        elif st.get("state") == "queued":
            waiting.append((st.get("submitted", ""), st_file.parent.name))
    for _, job_id in sorted(waiting):
        JOB_QUEUE.put(job_id)


@asynccontextmanager
async def lifespan(app):
    JOBS_DIR.mkdir(parents=True, exist_ok=True)
    recover_jobs()
    threading.Thread(target=worker, daemon=True, name="job-worker").start()
    yield


app = FastAPI(title="homidev asset receiver", version=VERSION, lifespan=lifespan)


# ---------------------------------------------------------------- endpoints
@app.get("/health", dependencies=[Depends(check_token)])
def health():
    free_gb = shutil.disk_usage(ASSETS).free / 1e9
    recipes, problems = load_recipes()
    return {
        "receiver": f"ok (v{VERSION})",
        "comfyui": comfyui_status(),
        "queue_length": JOB_QUEUE.qsize(),
        "running": CURRENT["job"],
        "disk_free_gb": round(free_gb, 1),
        "approved_recipes": len(recipes),
        "recipe_problems": len(problems),
    }


@app.get("/recipes", dependencies=[Depends(check_token)])
def recipes():
    recipes, problems = load_recipes()
    keep = ("name", "version", "asset_type", "engine", "models", "model_licences",
            "commercial_ok", "inputs", "outputs", "approved_by", "approved_date", "notes")
    return {
        "recipes": [{k: r.get(k) for k in keep} for r in recipes.values()],
        "skipped": problems,
    }


@app.post("/jobs", dependencies=[Depends(check_token)])
def submit_job(req: JobRequest):
    checked = validate_job(req)
    job_dir = JOBS_DIR / req.job_id
    try:
        job_dir.mkdir(parents=True, exist_ok=False)
    except FileExistsError:
        reject(409, f"job_id {req.job_id} already used")
    request = req.model_dump()
    request["inputs"] = checked["inputs"]
    write_json(job_dir / "request.json", request)
    write_json(job_dir / "status.json", {"job_id": req.job_id, "state": "queued",
                                         "submitted": now(), "updated": now()})
    JOB_QUEUE.put(req.job_id)
    return {"job_id": req.job_id, "state": "queued",
            "position": JOB_QUEUE.qsize(), "commercial_ok": checked["recipe"]["commercial_ok"]}


@app.get("/jobs/{job_id}", dependencies=[Depends(check_token)])
def job_status(job_id: str):
    if not JOB_ID_SAFE.match(job_id):
        reject(422, "malformed job_id")
    job_dir = JOBS_DIR / job_id
    if not (job_dir / "status.json").exists():
        reject(404, f"no job {job_id}")
    st = json.loads((job_dir / "status.json").read_text())
    if st.get("state") == "done" and (job_dir / "manifest.json").exists():
        st["manifest"] = json.loads((job_dir / "manifest.json").read_text())
    return st
