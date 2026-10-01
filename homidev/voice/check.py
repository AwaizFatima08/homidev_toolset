# check.py [--json] <audio file> "<expected script>" ["glossary words"]   (DRAFT v0.4, 1 Oct 2026)
# faster-whisper small.en on CPU. Audio decoded by ffmpeg (not PyAV).
# Glossary = project names/terms whisper should expect, e.g. "HomiLabs homidev".
# --json : print one JSON line (used by the receiver) instead of the human-readable lines.
import json, sys, re, difflib, subprocess
import numpy as np
from faster_whisper import WhisperModel

args = sys.argv[1:]
as_json = bool(args) and args[0] == "--json"
if as_json:
    args = args[1:]
audio, expected = args[0], args[1]
glossary = args[2] if len(args) > 2 and args[2].strip() else None

raw = subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-i", audio,
                      "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                     capture_output=True, check=True).stdout
sound = np.frombuffer(raw, np.int16).astype(np.float32) / 32768.0
model = WhisperModel("small.en", device="cpu", compute_type="int8")
segments, info = model.transcribe(sound, beam_size=5, hotwords=glossary)
heard = " ".join(s.text.strip() for s in segments)
norm = lambda t: re.sub(r"[^a-z0-9 ]", "", t.lower()).split()
score = difflib.SequenceMatcher(None, norm(expected), norm(heard)).ratio()
result = "PASS" if score >= 0.90 else "FLAG"

if as_json:
    print(json.dumps({"expected": expected, "heard": heard, "glossary": glossary or "",
                      "match": round(score, 3), "result": result}))
else:
    print("EXPECTED:", expected)
    print("HEARD:   ", heard)
    print("GLOSSARY:", glossary or "(none)")
    print(f"MATCH:    {score:.0%}  ->", "PASS" if result == "PASS" else "FLAG for Homi")
