# homidev LLM test sheet — Step 12 / L4 (8 Oct 2026)

Purpose: decide where "deep thinking" work should run — on homidev as it is, on homidev with more RAM/GPU, or online. Facts measured by `~/llm-test/run-llm-test-v2.sh` v2.0 (sha256 `aed5070c…`), results in `docs/llm-test/results-20261008-1659/` (copied from homidev). Same 5 prompts to every model via the Ollama API, 8000-token budget, one model on the GPU at a time, thinking on (gpt-oss: reasoning "high").

**Machine:** RTX 5060 Ti 16 GB, 16 GB RAM (one stick). All four models fit on the GPU entirely ("fits GPU" in every row) — nothing spilled into RAM, so L5 (wait for the second stick) did not apply.

## 1. Speed and memory (measured)

| Model | Size on GPU | Licence | tokens/s | Load | Total time, 5 prompts | Hit 8000-token ceiling |
|---|---|---|---|---|---|---|
| gpt-oss:20b (reasoning high) | 12.9 GB | Apache 2.0 | **92** | 10 s | 170 s | 0 of 5 |
| qwen3.5:9b (thinking) | 7.0 GB | Apache 2.0 | 67 | 5 s | 494 s | **3 of 5** (1, 2, 5: no answer at all) |
| deepseek-r1:14b | 10.5 GB | MIT | 43 | 6 s | 378 s | 0 of 5 |
| deepseek-r1:8b (0528, Qwen3 base) | 6.6 GB | MIT | 71 | 4 s | 442 s | **3 of 5** (1, 2, 5) |

Per-prompt times, thinking length and GPU peaks: `summary.tsv` in the results folder.

## 2. Quality (Claude's first grading; Homi's column to fill)

Expected: 1 = 22 patients · 2 = 62.5 mg (half tablet), +38.9 % · 3 = 2/3.

| Prompt | gpt-oss:20b | qwen3.5:9b | deepseek-r1:14b | deepseek-r1:8b | Homi |
|---|---|---|---|---|---|
| 1 Clinic schedule (22) | ✅ 22, clear | ❌ cut off while thinking, no answer | ✅ 22, clear | ❌ cut off, no answer | |
| 2 Dose (62.5 mg, +38.9 %) | ✅ exact | ❌ cut off, no answer | ✅ exact (38.89 %) | ❌ cut off, no answer | |
| 3 Three boxes (2/3) | ✅ with a second counting check | ✅ 2/3 | ✅ 2/3 (Bayes) | ✅ 2/3 | |
| 4 Urdu notice (5 sentences) | 5 sentences, readable, one English term in brackets — **Homi to judge** | answered in Urdu — **Homi to judge** (no cut-off) | ❌ **answered in English** — failed the task | ❌ Urdu is garbled (made-up place name, nonsense phrases) | |
| 5 Dart function + test | ✅ correct, compact, 5 `assert` tests, wraps to next day | ❌ cut off, no code | ✅ correct minute-maths, but only `print` examples, no real test | ❌ cut off, no code | |

**Reading of the results**
- **gpt-oss:20b is the clear winner on this machine**: fastest (mixture-of-experts, ~3.6 B active per token), never ran out of budget, all three maths answers right, usable Dart, acceptable Urdu. It already was the primary chat model (G5, 5 Oct).
- **deepseek-r1:14b is a solid second** for maths/reasoning (all right) and code, but half the speed and **no good for Urdu**.
- **qwen3.5:9b and deepseek-r1:8b think without end**: three of five prompts used the whole 8000-token budget and produced **no answer**. On this hardware they are not reliable for "deep thinking" unless thinking is turned off (`think: false`) — then they become ordinary fast chat models. Qwen 3.5's strengths (vision, 256 K context, Urdu) remain worth a separate, non-thinking test.
- Compared with 5 Oct: Gemma 4 12B remains the Urdu/vision choice; gpt-oss the reasoning choice. Nothing tested today beats either in its role.

## 3. What this means for the hardware / online question (draft — Homi decides)

| Option | What it buys | Evidence from today |
|---|---|---|
| **Keep as is** | gpt-oss:20b at 92 tok/s, DeepSeek 14B at 43 tok/s, all on the GPU | Enough for learning, drafting, code help, Urdu first drafts. Every model tested fits; RAM was not the limit. |
| Second 16 GB stick (ordered) | Lets 27–35 B models spill into RAM without swap (e.g. qwen3.5:27b 17–20 GB) | Spilling models run at CPU-RAM speed (expect < 10 tok/s) — useful for quality tests, not for daily use. |
| Bigger GPU (24–32 GB) | 27–32 B models fully on the GPU at 20–40 tok/s | Only worth it if a 27–32 B model is shown to be clearly better *for Homi's tasks* than gpt-oss:20b. Not shown yet. |
| Online models for hard tasks | Frontier quality on demand, no hardware | The cases where local models failed today (Urdu from DeepSeek, cut-offs) are exactly where an online model would be used. Cheap compared with a GPU. |

Recommendation to critique: **no hardware spending now**. Use gpt-oss:20b locally; Gemma 4 for Urdu/vision; online models for the hardest or longest tasks. Re-test when the second RAM stick is in (qwen3.5:27b) before deciding on a GPU.

## 4. Open follow-ups
- Homi reads the Urdu answers (gpt-oss, qwen3.5) in `*_4-urdu.md` and fills the Homi column.
- Non-thinking run of qwen3.5:9b and deepseek-r1:8b (`think: false`) — are they useful fast chat/vision models?
- LM Studio: same Qwen 3.5 9B GGUF imported there (lmstudio-community Q4_K_M + vision mmproj) to compare tokens/s with Ollama once the download finishes.
- Register: chat models stay outside MODEL-REGISTER (G-decision 5 Oct: they make no assets); listed here with licence instead. L3's "each in MODEL-REGISTER" is therefore **not** applied — Homi to confirm or overrule.
