#!/usr/bin/env python3
# Builds review-sheet.sh v1.2 from v1.1 (LT3): Lottie animations play on the page (lottie-web 5.13, MIT, embedded).
import sys
src = open(sys.argv[1]).read()
def rep(old, new):
    global src
    assert src.count(old) == 1, old[:60]
    src = src.replace(old, new)

rep("# review-sheet.sh v1.1 (8 Oct 2026) — step 10c: one self-contained HTML review page per batch (L1-L7)\n",
    "# review-sheet.sh v1.2 (8 Oct 2026) — LT3: Lottie jobs (*_lottie.json) play on the page via an embedded lottie-web\n"
    "#       player (~/ai-inbox/_tools/lib/lottie.min.js, MIT); loops per manifest settings.loop; chip shows fps/length.\n"
    "# v1.1 (8 Oct 2026) — step 10c: one self-contained HTML review page per batch (L1-L7)\n")
rep('BASE="$HOME/ai-inbox/$PROJECT"; S1="$HOME/ai-inbox/_tools/stage1-check.sh"',
    'BASE="$HOME/ai-inbox/$PROJECT"; S1="$HOME/ai-inbox/_tools/stage1-check.sh"; LW="$HOME/ai-inbox/_tools/lib/lottie.min.js"; NEEDLW=0')
rep('echo "<p class=\\"sub\\">${#JOBS[@]} job(s) · made $(date \'+%d %b %Y, %H:%M\') on homi-nas · review-sheet.sh v1.1</p>"',
    'echo "<p class=\\"sub\\">${#JOBS[@]} job(s) · made $(date \'+%d %b %Y, %H:%M\') on homi-nas · review-sheet.sh v1.2</p>"')
rep('''      *.wav) jq -e '.files[].name|select(endswith(".ogg"))' "$M" >/dev/null || echo "<audio controls src=\\"data:audio/wav;base64,$(base64 -w0 "$D/$f")\\"></audio>";;
    esac''',
'''      *.wav) jq -e '.files[].name|select(endswith(".ogg"))' "$M" >/dev/null || echo "<audio controls src=\\"data:audio/wav;base64,$(base64 -w0 "$D/$f")\\"></audio>";;
      *_lottie.json) NEEDLW=1; LP=$(jq -r 'if .settings.loop == false then "false" else "true" end' "$M")
        echo "<div class=\\"lottie\\" data-loop=\\"$LP\\" id=\\"lt$n\\"></div><script type=\\"application/json\\" id=\\"ltd$n\\">$(cat "$D/$f")</script>"
        echo "<p class=\\"k\\">Animation: $(jq -r '"\\(.settings.fps) fps · \\(.settings.seconds) s · \\(.settings.width)x\\(.settings.height) · " + (if .settings.loop == false then "plays once (click to replay)" else "loops" end)' "$M")</p>";;
    esac''')
rep('''.note{border-left:3px solid var(--line);padding:4px 10px;margin:4px 0 0;white-space:pre-wrap}''',
    '''.note{border-left:3px solid var(--line);padding:4px 10px;margin:4px 0 0;white-space:pre-wrap}
.lottie{width:100%;aspect-ratio:1;border-radius:8px;border:1px solid var(--line);background:repeating-conic-gradient(#ccc 0 25%,#fff 0 50%) 0 0/16px 16px;cursor:pointer}''')
rep('''cat <<'FOOT'
<footer>''', '''if [ "$NEEDLW" = 1 ] && [ -f "$LW" ]; then
  echo "<script>"; cat "$LW"; echo "</script>"
  cat <<'LJS'
<script>document.querySelectorAll('.lottie').forEach(function(el){var d=JSON.parse(document.getElementById('ltd'+el.id.slice(2)).textContent);
var a=lottie.loadAnimation({container:el,renderer:'svg',loop:el.dataset.loop==='true',autoplay:true,animationData:d});el.addEventListener('click',function(){a.goToAndPlay(0,true);});});</script>
LJS
fi
cat <<'FOOT'
<footer>''')
open(sys.argv[2], "w").write(src)
print("review-sheet.sh v1.2 written to", sys.argv[2])
