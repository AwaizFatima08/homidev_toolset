# homidev voice scripts (backup copies) — 1 Oct 2026

Location on homidev: `~/voice/`
- `tts/` — Python 3.12 env: CPU torch 2.14.1+cpu, kokoro 0.9.4, transformers 4.57.6 (pinned `>=4.40,<5`), soundfile, en_core_web_sm 3.8.0
- `stt/` — Python 3.12 env: faster-whisper 1.2.1, ctranslate2 4.8.2 (no torch)
- Models in `~/.cache/huggingface/hub` (see MODEL-REGISTER.md)

Install notes (lessons):
- Kokoro without a pin resolves to transformers 4.12 (2021) → always pin `transformers>=4.40,<5`.
- Kokoro/misaki tries to auto-download `en_core_web_sm` via uv and fails outside an activated env → install it explicitly from the official spaCy release.
- faster-whisper 1.2.1 + PyAV 19 clash (`metadata_errors`) → decode audio with ffmpeg instead of PyAV.

## say.py (DRAFT v0.1)

```python
# say.py "<text>" <out.wav> [voice]   (DRAFT v0.1) - Kokoro TTS on CPU
import sys, numpy as np, soundfile as sf
from kokoro import KPipeline
text, out = sys.argv[1], sys.argv[2]
voice = sys.argv[3] if len(sys.argv) > 3 else "af_heart"
pipe = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")   # "a" = American English
parts = [a.cpu().numpy() if hasattr(a, "cpu") else a for _, _, a in pipe(text, voice=voice)]
sf.write(out, np.concatenate(parts), 24000)
print("saved", out)
```

Run: `~/voice/tts/bin/python ~/voice/say.py "text" out.wav`

## check.py — SUPERSEDED by v0.4 (separate file `check.py`, adds `--json` for the receiver). v0.3 kept below for reference.

```python
# check.py <audio file> "<expected script>" ["glossary words"]   (DRAFT v0.3)
# faster-whisper small.en on CPU. Audio decoded by ffmpeg (not PyAV).
# Glossary = project names/terms whisper should expect, e.g. "HomiLabs homidev".
import sys, re, difflib, subprocess
import numpy as np
from faster_whisper import WhisperModel
audio, expected = sys.argv[1], sys.argv[2]
glossary = sys.argv[3] if len(sys.argv) > 3 else None
raw = subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-i", audio,
                      "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                     capture_output=True, check=True).stdout
sound = np.frombuffer(raw, np.int16).astype(np.float32) / 32768.0
model = WhisperModel("small.en", device="cpu", compute_type="int8")
segments, info = model.transcribe(sound, beam_size=5, hotwords=glossary)
heard = " ".join(s.text.strip() for s in segments)
norm = lambda t: re.sub(r"[^a-z0-9 ]", "", t.lower()).split()
score = difflib.SequenceMatcher(None, norm(expected), norm(heard)).ratio()
print("EXPECTED:", expected)
print("HEARD:   ", heard)
print("GLOSSARY:", glossary or "(none)")
print(f"MATCH:    {score:.0%}  ->", "PASS" if score >= 0.90 else "FLAG for Homi")
```

Run: `~/voice/stt/bin/python ~/voice/check.py file.wav "script" "Glossary Words"`

Test result 1 Oct: 6 s clip generated in 8.4 s (first run); check in 2.4 s; without glossary 85% (brand names misheard), with glossary "HomiLabs homidev" 100% PASS.
