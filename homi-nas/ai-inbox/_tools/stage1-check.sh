#!/usr/bin/env bash
# stage1-check.sh <job-folder> <commercial-project: yes|no>   (v0.5, 7 Oct 2026)
# v0.5 (K1-K6, step 8b-5c): asset_type "sfx" gets its own rules: deliverable 0.02-10 s, mono, true peak
#       -4..-1 dB (above -1 FAIL, below -4 WARN), loudness info only, start silence > 0.1 s WARN, end silence
#       > 0.1 s FAIL, no hidden workflow text in any audio file, manifest postprocess.type = sfx;
#       *_master.* = untouched original: fingerprint + info line only. Voice/image checks unchanged.
# v0.4 (K1): clips < 5 s: loudness within -16 +/- 3 but outside +/- 1 = WARN (loudness is unreliable on very short clips); >= 5 s stays strict
# Lives on homi-nas at ~/ai-inbox/_tools/stage1-check.sh
# v0.3 (step 10b, G1-G6): audio checks measured here with ffmpeg (length > 0.5 s, loudness -16 +/- 1 LUFS,
#       true peak <= -1 dB, <= 0.5 s silence at start and end); whisper mismatch = WARN (Homi decides);
#       result PASS / PASS with warnings / FAIL. Pure checker: never moves or changes files.
# v0.2: receiver bookkeeping files (request.json, status.json) are expected, not "unlisted";
#       status.json must say "done"; list/dict fields printed on one line.
# Known gaps: subject-touches-edge check, Claude visual review (done by Claude Code, step 10e).
set -u
DIR="$1"; COMM="${2:-yes}"
cd "$DIR" || { echo "no such folder: $DIR"; exit 2; }
FAIL=0; WARN=0
ok(){ echo "  PASS  $1"; }
bad(){ echo "  FAIL  $1"; FAIL=1; }
warn(){ echo "  WARN  $1"; WARN=$((WARN+1)); }
echo "Stage 1 checks: $(basename "$DIR")   (commercial project: $COMM)"
if [ -f manifest.json ] && jq empty manifest.json 2>/dev/null; then ok "manifest.json present and valid"; else bad "manifest missing or invalid"; echo "RESULT: FAIL"; exit 1; fi
for k in job_id project asset_type model model_licence commercial_ok created_at; do
  v=$(jq -c ".$k // empty" manifest.json | tr -d '"'); [ -n "$v" ] && ok "field $k = $v" || bad "field $k missing"
done
[ "$(jq -r .job_id manifest.json)" = "$(basename "$DIR")" ] && ok "job_id matches folder name" || bad "job_id does not match folder name"
if [ -f status.json ]; then
  s=$(jq -r .state status.json); [ "$s" = "done" ] && ok "receiver status = done" || bad "receiver status = $s (not done)"
fi
while read -r name sha; do
  if [ ! -f "$name" ]; then bad "$name is missing"; continue; fi
  [ "$(sha256sum "$name" | cut -d' ' -f1)" = "$sha" ] && ok "$name fingerprint matches" || bad "$name fingerprint MISMATCH"
  echo "        $(file -b "$name")"
done < <(jq -r '.files[] | "\(.name) \(.sha256)"' manifest.json)
extra=$(comm -23 <(ls | grep -v -x -E 'manifest.json|request.json|status.json' | sort) <(jq -r '.files[].name' manifest.json | sort))
[ -z "$extra" ] && ok "no unlisted files" || bad "unlisted files: $(echo $extra)"
for c in $(jq -r '.files[].name' manifest.json | grep _cutout); do
  file -b "$c" | grep -q RGBA && ok "$c has transparency" || bad "$c has NO transparency"
done

TYPE=$(jq -r .asset_type manifest.json)
# ---- audio (G1): measured here, not copied from the manifest (voice and other non-sfx audio)
[ "$TYPE" != "sfx" ] && for a in $(jq -r '.files[].name' manifest.json | grep -E '\.(wav|ogg|mp3)$'); do
  [ -f "$a" ] || continue
  if ! command -v ffmpeg >/dev/null || ! command -v ffprobe >/dev/null; then bad "$a: ffmpeg/ffprobe not installed on this machine"; continue; fi
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$a")
  awk -v d="$dur" 'BEGIN{exit !(d>0.5)}' && ok "$a length ${dur}s" || bad "$a too short (${dur:-?}s)"
  meter=$(ffmpeg -nostdin -hide_banner -i "$a" -af ebur128=peak=true -f null - 2>&1)
  lufs=$(echo "$meter" | grep -oP 'I:\s+\K-?[0-9.]+(?= LUFS)' | tail -n1)
  peak=$(echo "$meter" | grep -oP 'Peak:\s+\K(-?[0-9.]+|-inf)(?= dBFS)' | tail -n1)
  if awk -v l="$lufs" 'BEGIN{exit !(l!="" && l>=-17 && l<=-15)}'; then ok "$a loudness $lufs LUFS"
  elif awk -v l="$lufs" -v d="$dur" 'BEGIN{exit !(l!="" && d<5 && l>=-19 && l<=-13)}'; then warn "$a loudness $lufs LUFS (short clip ${dur}s: outside -16 +/- 1, within +/- 3 -> listen)"
  else bad "$a loudness ${lufs:-?} LUFS (target -16 +/- 1; short clips +/- 3)"; fi
  awk -v p="$peak" 'BEGIN{exit !(p=="-inf" || (p!="" && p<=-1.0))}' && ok "$a true peak $peak dBFS" || bad "$a true peak ${peak:-?} dBFS (limit -1)"
  sd=$(ffmpeg -nostdin -hide_banner -i "$a" -af silencedetect=noise=-50dB:d=0.5 -f null - 2>&1)
  lead=$(echo "$sd" | grep -oP 'silence_start: \K-?[0-9.]+' | head -n1)
  last=$(echo "$sd" | grep -oP 'silence_(start|end)' | tail -n1)
  lend=$(echo "$sd" | grep -oP 'silence_end: \K[0-9.]+' | tail -n1)
  if [ -n "$lead" ] && awk -v s="$lead" 'BEGIN{exit !(s<0.05)}'; then bad "$a starts with >= 0.5 s of silence"; else ok "$a no long silence at start"; fi
  if [ "$last" = "silence_start" ] || { [ -n "$lend" ] && awk -v e="$lend" -v d="$dur" 'BEGIN{exit !(d-e<0.05)}'; }; then bad "$a ends with >= 0.5 s of silence"; else ok "$a no long silence at end"; fi
done

# ---- sound effects (K1-K6): own rules, peak-based, measured here
if [ "$TYPE" = "sfx" ]; then
  if [ "$(jq -r '.postprocess.type // empty' manifest.json)" = "sfx" ]; then
    ok "sfx clean-up ran (gain $(jq -r .postprocess.gain_db manifest.json) dB, sound $(jq -r .postprocess.trimmed_duration_sec manifest.json) s)"
  else bad "manifest: postprocess.type is not sfx (clean-up did not run)"; fi
  deliver=0
  for a in $(jq -r '.files[].name' manifest.json | grep -E '\.(ogg|flac|wav|mp3)$'); do
    [ -f "$a" ] || continue
    if ! command -v ffmpeg >/dev/null || ! command -v ffprobe >/dev/null; then bad "$a: ffmpeg/ffprobe not installed on this machine"; continue; fi
    if grep -qa 'class_type' "$a" || ffprobe -v error -show_entries format_tags:stream_tags -of default=nw=1 "$a" | grep -qiE '^TAG:(prompt|workflow)='; then
      bad "$a contains hidden workflow info"; else ok "$a no hidden workflow info"; fi
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$a")
    ch=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$a")
    case "$a" in *_master.*) echo "        master (original, not judged on level): ${dur}s, ${ch} channel(s)"; continue ;; esac
    deliver=$((deliver+1))
    awk -v d="$dur" 'BEGIN{exit !(d>=0.02 && d<=10)}' && ok "$a length ${dur}s" || bad "$a length ${dur:-?}s (allowed 0.02-10 s)"
    [ "$ch" = "1" ] && ok "$a mono" || bad "$a has ${ch:-?} channels (must be mono)"
    meter=$(ffmpeg -nostdin -hide_banner -i "$a" -af ebur128=peak=true -f null - 2>&1)
    lufs=$(echo "$meter" | grep -oP 'I:\s+\K-?[0-9.]+(?= LUFS)' | tail -n1)
    peak=$(echo "$meter" | grep -oP 'Peak:\s+\K(-?[0-9.]+|-inf)(?= dBFS)' | tail -n1)
    if [ -z "$peak" ] || [ "$peak" = "-inf" ]; then bad "$a is silent (no peak)"
    elif awk -v p="$peak" 'BEGIN{exit !(p>-1.0)}'; then bad "$a true peak $peak dBFS (above -1)"
    elif awk -v p="$peak" 'BEGIN{exit !(p<-4.0)}'; then warn "$a true peak $peak dBFS (below -4: quiet -> listen)"
    else ok "$a true peak $peak dBFS"; fi
    echo "        loudness ${lufs:-?} LUFS (info only for sfx)"
    sd=$(ffmpeg -nostdin -hide_banner -i "$a" -af silencedetect=noise=-50dB:d=0.1 -f null - 2>&1)
    lead=$(echo "$sd" | grep -oP 'silence_start: \K-?[0-9.]+' | head -n1)
    last=$(echo "$sd" | grep -oP 'silence_(start|end)' | tail -n1)
    lend=$(echo "$sd" | grep -oP 'silence_end: \K[0-9.]+' | tail -n1)
    if [ -n "$lead" ] && awk -v s="$lead" 'BEGIN{exit !(s<0.05)}'; then warn "$a starts with > 0.1 s of silence"; else ok "$a no silence at start"; fi
    if [ "$last" = "silence_start" ] || { [ -n "$lend" ] && awk -v e="$lend" -v d="$dur" 'BEGIN{exit !(d-e<0.05)}'; }; then bad "$a ends with > 0.1 s of silence (trim did not run?)"; else ok "$a no silence at end"; fi
  done
  [ "$deliver" -ge 1 ] && ok "$deliver sfx deliverable(s) checked" || bad "no sfx deliverable (OGG) in job"
fi

# ---- voice script check (G2): mismatch is a warning for Homi, not a failure
if [ "$(jq -r .asset_type manifest.json)" = "voice" ]; then
  r=$(jq -r '.script_check.result // empty' manifest.json)
  if [ "$r" = "PASS" ]; then ok "whisper heard the script (match $(jq -r .script_check.match manifest.json))"
  elif [ -z "$r" ]; then warn "no whisper script check in manifest"
  else warn "whisper mismatch (match $(jq -r .script_check.match manifest.json)): heard \"$(jq -r .script_check.heard manifest.json)\""; fi
fi

LIC=$(jq -r .commercial_ok manifest.json)
if [ "$COMM" = "yes" ] && [ "$LIC" != "yes" ]; then bad "LICENCE GATE: commercial project, but commercial_ok = $LIC"; else ok "licence gate"; fi
if [ $FAIL -ne 0 ]; then echo "RESULT: FAIL"
elif [ $WARN -gt 0 ]; then echo "RESULT: PASS with $WARN warning(s) -> Stage 2 (human review), see WARN lines"
else echo "RESULT: PASS -> ready for Stage 2 (human review)"; fi
exit $FAIL
