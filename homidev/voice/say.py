# say.py "<text>" <out.wav> [voice]   (DRAFT v0.1) - Kokoro TTS on CPU
import sys, numpy as np, soundfile as sf
from kokoro import KPipeline
text, out = sys.argv[1], sys.argv[2]
voice = sys.argv[3] if len(sys.argv) > 3 else "af_heart"
pipe = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")   # "a" = American English
parts = [a.cpu().numpy() if hasattr(a, "cpu") else a for _, _, a in pipe(text, voice=voice)]
sf.write(out, np.concatenate(parts), 24000)
print("saved", out)
