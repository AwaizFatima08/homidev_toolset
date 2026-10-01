#!/usr/bin/env bash
# cleanup-jobs.sh - homidev: delete finished job folders older than N days (step 9f-3, v1.0, 1 Oct 2026)
# Lives in ~/receiver/. Run by asset-cleanup.timer once a day.
#
#   cleanup-jobs.sh                 dry run: only LISTS what it would delete (default, safe)
#   cleanup-jobs.sh --delete        really deletes
#   cleanup-jobs.sh --days 3        use 3 days instead of 14 (for tests)
#
# Rules (design F3, approved 1 Oct):
#   - only folders inside ~/assets/jobs whose name starts with a job-ID date: YYYYMMDD-HHMM-
#   - age comes from the date in the job ID, not the file date
#   - never touches jobs that are queued or running, or have no status.json
#   - anything it doesn't understand is reported and left alone
set -u
JOBS="$HOME/assets/jobs"
DAYS=14
DELETE=no

while [ $# -gt 0 ]; do
  case "$1" in
    --delete) DELETE=yes ;;
    --days)   shift; DAYS="${1:-}" ;;
    *) echo "unknown option: $1"; exit 2 ;;
  esac
  shift
done
case "$DAYS" in ''|*[!0-9]*) echo "--days needs a whole number"; exit 2 ;; esac
[ -d "$JOBS" ] || { echo "ERROR: $JOBS not found - nothing done"; exit 1; }

TODAY=$(date +%s)
deleted=0; kept=0; skipped=0
[ "$DELETE" = yes ] && MODE="DELETE" || MODE="DRY RUN"
echo "cleanup-jobs: $MODE, older than $DAYS days, in $JOBS"

for dir in "$JOBS"/*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name=$(basename "$dir")

  # 1. must look like a job ID
  if ! [[ "$name" =~ ^([0-9]{8})-[0-9]{4}- ]]; then
    echo "  SKIP   $name (not a job-ID name)"; skipped=$((skipped+1)); continue
  fi
  day="${BASH_REMATCH[1]}"
  if ! made=$(date -d "$day" +%s 2>/dev/null); then
    echo "  SKIP   $name (bad date in name)"; skipped=$((skipped+1)); continue
  fi
  age=$(( (TODAY - made) / 86400 ))

  if [ "$age" -lt 0 ]; then
    echo "  SKIP   $name (date is in the future)"; skipped=$((skipped+1)); continue
  fi
  if [ "$age" -lt "$DAYS" ]; then
    kept=$((kept+1)); continue
  fi

  # 2. must be finished
  if [ ! -f "$dir/status.json" ]; then
    echo "  SKIP   $name (${age} d, no status.json)"; skipped=$((skipped+1)); continue
  fi
  state=$(jq -r '.state // "unknown"' "$dir/status.json" 2>/dev/null || echo unreadable)
  if [ "$state" != "done" ] && [ "$state" != "failed" ]; then
    echo "  SKIP   $name (${age} d, state: $state)"; skipped=$((skipped+1)); continue
  fi

  # 3. delete (or just say so)
  if [ "$DELETE" = yes ]; then
    rm -rf -- "$dir" && echo "  DELETED $name (${age} d, $state)" && deleted=$((deleted+1))
  else
    echo "  WOULD DELETE $name (${age} d, $state)"; deleted=$((deleted+1))
  fi
done

[ "$DELETE" = yes ] && word="deleted" || word="would delete"
echo "cleanup-jobs: $word $deleted, kept $kept (younger than $DAYS d), skipped $skipped"
