#!/usr/bin/env python3
# Builds asset-job.sh v1.2 from v1.1 (pipeline review D1). Exact-once replacements.
import sys
src = open(sys.argv[1]).read()
def rep(old, new):
    global src
    assert src.count(old) == 1, old[:70]
    src = src.replace(old, new)

rep('# asset-job.sh v1.1 (5 Oct 2026) — step 10b',
    '# asset-job.sh v1.2 (8 Oct 2026) — review D1: wait 15 min (receiver timeout 10 min + queue/unload); on timeout\n'
    '#   the job is NOT failed - it may still finish on homidev; pull it later with asset-pull.sh <project> <job-id>\n'
    '# v1.1 (5 Oct 2026) — step 10b')
rep('''# F4: wait up to 10 min
for _ in $(seq 1 120); do''', '''# F4: wait up to 15 min (receiver gives a job 10 min + up to 30 s unload + queue time)
for _ in $(seq 1 180); do''')
rep('''[ "$S" = "done" ] || end 2 "FAIL job $J state=$S: $(curl -s -m 10 -H "$HDR" "$R/jobs/$J" | jq -r '.error // "timeout after 10 min"')"''',
'''if [ "$S" != "done" ] && [ "$S" != failed ]; then
  end 2 "FAIL gave up waiting after 15 min; job $J is still '$S' on homidev - check later with: asset-pull.sh $PROJECT $J"
fi
[ "$S" = "done" ] || end 2 "FAIL job $J state=$S: $(curl -s -m 10 -H "$HDR" "$R/jobs/$J" | jq -r '.error // "no error text"')"''')
open(sys.argv[2], "w").write(src)
print("asset-job.sh v1.2 written to", sys.argv[2])
