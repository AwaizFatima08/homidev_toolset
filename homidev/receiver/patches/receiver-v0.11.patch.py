#!/usr/bin/env python3
# Builds receiver.py v0.11 from v0.10 (pipeline review D2 + D3, rule L2). Exact-once replacements.
# Usage: receiver-v0.11.patch.py <receiver.py v0.10> <output receiver.py.new>
import sys
src = open(sys.argv[1]).read()
def rep(old, new):
    global src
    assert src.count(old) == 1, (src.count(old), old[:70])
    src = src.replace(old, new)

rep('# receiver.py - homidev asset receiver\n',
'''# receiver.py - homidev asset receiver
# v0.11 (8 Oct 2026) - step 12 / review D2+D3: (1) before every ComfyUI job also unload LM Studio models
#   (lms unload --all), free ComfyUI, then a GPU guard: the job fails clearly if more than GPU_BUSY_MIB is
#   still in use (rule L2: services never run models in parallel). (2) PNG outputs lose ComfyUI's hidden
#   prompt/workflow text chunks (png:exclude-chunk) before fingerprinting, like audio since SFX5.
''')
rep('VERSION = "0.10"', 'VERSION = "0.11"')
rep('OLLAMA_UNLOAD_WAIT_S = 30\n',
'''OLLAMA_UNLOAD_WAIT_S = 30
LMS = HOME / ".lmstudio" / "bin" / "lms"      # LM Studio CLI (step 12); absent = nothing to unload
GPU_BUSY_MIB = 1500                           # more than this in use before a job = someone else holds the GPU
''')
rep('''        if ext in AUDIO_EXTS:
            strip_metadata(dst)          # SFX5: ComfyUI hides the whole workflow in the file
''', '''        if ext in AUDIO_EXTS:
            strip_metadata(dst)          # SFX5: ComfyUI hides the whole workflow in the file
        elif ext == ".png":
            strip_png_metadata(dst)      # D2 (8 Oct): same for images (tEXt "prompt"/"workflow" chunks)
''')
rep('''def sfx_postprocess(job_dir: Path, job_id: str, master: Path, s: dict):''',
'''def strip_png_metadata(path: Path):
    """Re-write a PNG without text chunks (pixels unchanged; colour chunks kept)."""
    tmp = path.with_name(path.stem + ".clean" + path.suffix)
    run_cmd(["magick", path, "-define", "png:exclude-chunk=tEXt,zTXt,iTXt,date,time", tmp],
            60, "strip PNG metadata")
    os.replace(tmp, path)


def sfx_postprocess(job_dir: Path, job_id: str, master: Path, s: dict):''')
rep('''def free_comfyui():
''', '''def lmstudio_loaded() -> list:
    """Names of models LM Studio holds now. No lms / daemon down = nothing loaded."""
    if not LMS.exists():
        return []
    try:
        p = subprocess.run([str(LMS), "ps", "--json"], capture_output=True, text=True, timeout=30)
        return [m.get("identifier") or m.get("modelKey") or str(m) for m in json.loads(p.stdout or "[]")]
    except Exception as e:
        print(f"[receiver] lms ps failed (treated as nothing loaded): {e}", flush=True)
        return []


def unload_lmstudio() -> list:
    """L2 (step 12): LM Studio shares the GPU too, so its models are unloaded before every ComfyUI job."""
    names = lmstudio_loaded()
    if names:
        try:
            subprocess.run([str(LMS), "unload", "--all"], capture_output=True, text=True, timeout=60)
        except Exception as e:
            print(f"[receiver] lms unload failed: {e}", flush=True)
        left = lmstudio_loaded()
        if left:
            raise RuntimeError(f"LM Studio model(s) still loaded: {left}")
        print(f"[receiver] unloaded LM Studio: {names}", flush=True)
    return names


def gpu_used_mib() -> int:
    p = subprocess.run(["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
                       capture_output=True, text=True, timeout=20)
    return int(p.stdout.strip().splitlines()[0])


def gpu_guard() -> int:
    """Rule L2 in code: the GPU must be (nearly) empty before a job starts."""
    used = gpu_used_mib()
    if used > GPU_BUSY_MIB:
        raise RuntimeError(f"GPU busy: {used} MiB in use before the job (limit {GPU_BUSY_MIB}) - "
                           "a model loaded by hand (ComfyUI browser, Ollama, LM Studio)? Unload it and retry")
    return used


def free_comfyui():
''')
rep('''        set_status(job_dir, "running", ollama_unloaded=unload_ollama())   # D6
        try:''', '''        set_status(job_dir, "running", ollama_unloaded=unload_ollama(),   # D6
                   lmstudio_unloaded=unload_lmstudio())                   # L2
        free_comfyui()
        set_status(job_dir, "running", gpu_used_mib_before=gpu_guard())  # L2 guard
        try:''')
open(sys.argv[2], "w").write(src)
print("receiver v0.11 written to", sys.argv[2])
