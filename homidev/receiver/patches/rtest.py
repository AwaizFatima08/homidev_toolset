# rtest.py - step 2 check of receiver v0.11 functions (runs on homidev with the receiver's venv; installs nothing)
import shutil, subprocess, sys
from pathlib import Path
sys.path.insert(0, "/tmp")
shutil.copy(Path.home() / "receiver" / "receiver.py.new", "/tmp/receiver_new.py")
import receiver_new as rt

print("version", rt.VERSION)
print("lms loaded:", rt.lmstudio_loaded())
print("unload:", rt.unload_lmstudio())
print("gpu MiB:", rt.gpu_guard())
src = next(rt.JOBS_DIR.glob("*/*_raw.png"))
shutil.copy(src, "/tmp/t.png")
sig = lambda: subprocess.run(["magick", "identify", "-format", "%#", "/tmp/t.png"], capture_output=True, text=True).stdout
before = sig()
rt.strip_png_metadata(Path("/tmp/t.png"))
after = sig()
left = open("/tmp/t.png", "rb").read().count(b"class_type")
print("pixels identical:", before == after, "| hidden workflow text left:", left)
assert before == after and left == 0
Path("/tmp/t.png").unlink(); Path("/tmp/receiver_new.py").unlink()
print("== STEP 2 OK")
