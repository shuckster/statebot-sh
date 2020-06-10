#!/bin/sh
# shellcheck disable=SC2016,SC2006,SC2001,SC2181,SC2219,SC2039,SC2086

RERUN_JOB="/tmp/rerun-job.txt"
RERUN_LOG="/tmp/rerun-failures.txt"
RERUN_HISTORY_DIR="history"

HELP="
Usage:
  ./rerun.sh <run-count> <what-you-want-to-run>

Examples:
  ./rerun.sh 100 npm run test-suite
  ./rerun.sh 10 sleep 1

Resume a paused run:
  ./rerun.sh

Pausing a run is done by hitting [CTRL+C]

At the end of a run all unique failures will be printed. If you want
to see the failures before a run is finished, type:

  cat ${RERUN_LOG}

Running ./rerun.sh with args will always start a new run.
"

RERUN_CHART='

  idle ->
    rotate-logs ->
    running ->
    done

  // Hitting CTRL+C will "pause" the current job
  running -> paused -> running

'

perform_transitions ()
{
  local ON=""; local THEN=""

  case $1 in
    'idle->rotate-logs')
      ON="init-run"
      THEN="rotate_logs_and_start_run"
    ;;
    'rotate-logs->running'|'paused->running')
      ON="resume-run"
      THEN="start_or_resume_run"
    ;;
    'running->paused')
      ON="ctrl-c-hit"
      THEN="catch_interrupt"
    ;;
    'running->done')
      ON="finished"
      THEN="all_done"
    ;;
  esac

  echo $ON $THEN
}

#
# Colours for failure messages
#

if [ -t 1 ]
then
  NOCOLOUR="\e[0m"
  ORANGE="\e[0;33m"
  RED="\e[1;31m"
  GREEN="\e[1;32m"
  PURPLE='\e[1;35m'
fi

#
# Command to run, failure-counts, save/load
#

cmd_to_run=""
start_from_run=1
max_runs=0
run_so_far=0
failures=0
unique_failures=0

save_run_position()
{
  echo "$run_so_far!$max_runs!$failures!$unique_failures!$cmd_to_run" > "${RERUN_JOB}"
}

load_run_position()
{
  local rerun_info
  rerun_info=$(cat "${RERUN_JOB}")

  start_from_run=$(echo "${rerun_info}"|awk 'BEGIN { FS="!" } { print $1 }')
  : $((start_from_run+=1))
  max_runs=$(echo "${rerun_info}"|awk 'BEGIN { FS="!" } { print $2 }')
  failures=$(echo "${rerun_info}"|awk 'BEGIN { FS="!" } { print $3 }')
  unique_failures=$(echo "${rerun_info}"|awk 'BEGIN { FS="!" } { print $4 }')
  cmd_to_run=$(echo "${rerun_info}"|awk 'BEGIN { FS="!" } { print $5 }')
}

rotate_logs()
{
  if [ ! -f "${RERUN_LOG}" ]
  then
    return
  fi

  if ! grep -q '[^[:space:]]' "${RERUN_LOG}"
  then
    return
  fi

  # shellcheck disable=SC2046
  mv "${RERUN_LOG}" ./$RERUN_HISTORY_DIR/$(date "+%Y-%m-%d__%H.%M").log
  echo "" > "${RERUN_LOG}"
}

#
# Calculate ETA as a rolling-average of the last 5 runs
#

rolling_idx=0
rollers=""

rolling_avg()
{
  local rolling_max=5
  if [ $rolling_idx -ge $rolling_max ]
  then
    rollers=$(echo "$rollers"|awk '{ print $2 " " $3 " " $4 " " $5 }')
  fi
  rollers="$rollers $1"

  local sum=0
  for next in $rollers
  do
    : $((sum+=next))
  done

  if [ $rolling_idx -lt $rolling_max ]
  then
    : $((rolling_idx+=1))
  fi

  : $((avg=sum/rolling_idx))
  echo "$avg"
}

#
# Calculate and display estimated completion time
#

time_from_seconds()
{
  awk -v seconds="$1" '
  BEGIN {
    h=seconds/3600
    m=(seconds%3600)/60
    s=seconds%60
    printf "%02dh %02dm %02ds\n", h, m, s
  }'
}

eta_from_seconds()
{
  local seconds="$1"
  local eta

  # Sigh...
  if uname | grep -q 'Darwin'
  then
    eta=$(date -j -v+"${seconds}"S '+%H:%M:%S')
  else
    eta=$(awk -v seconds="${seconds}" '
    BEGIN {
      ts = systime()
      format = "%H:%M:%S"
      print strftime(format, ts + seconds)
    }
    ')
  fi

  # shellcheck disable=SC2006,SC2086
  echo "$eta (`time_from_seconds $seconds`)"
}

WHICH_MD5=$(which md5||which md5sum)

add_failure_to_log()
{
  # Before hashing, lets remove anything that changes between identical
  # runs, like time-stamps and durations
  local output_without_cruft
  local output_hash
  output_without_cruft=$(echo "$1"|grep -v "npm ERR!"|grep -v "^\(real\|user\|sys\) "|sed 's/([0-9]*[hms]*)$//'|sed 's/\([0-9]\) passing (.*)$/\1 passing/')
  output_hash=$(echo "$output_without_cruft"|"$WHICH_MD5")

  if ! grep -q "$output_hash" "${RERUN_LOG}"
  then
    : $((unique_failures+=1))
    {
      echo "$output_without_cruft"
      echo ""
      echo "| "
      echo "| ^ UNIQUE FAILURE ${unique_failures}"
      echo "|   HASH: ${output_hash}"
      echo "+--- "
      echo ""
    } >> "${RERUN_LOG}"
  fi

  : $((failures+=1))
}

print_unique_failures()
{
  cat "${RERUN_LOG}"
}

#
# Run/print tests
#

start_time=$(date)
last_run_duration=0

print_single_run()
{
  count="$1"
  seconds=$(echo "$2"|awk 'BEGIN { FS="." } { print $1 }')

  : $((total_duration+=seconds))
  last_run_duration=$seconds
  : $((remaining_tests=max_runs-count))
  avg_duration=$(rolling_avg $last_run_duration)
  : $((estimated_remaining_duration=avg_duration*remaining_tests))

  echo "| Finished run $count of $max_runs:"
  echo ">  Took: $(time_from_seconds $last_run_duration)"

  if [ "$count" != "$max_runs" ]
  then
    echo ">  ~ETA: $(eta_from_seconds $estimated_remaining_duration)"
  fi

  echo ""
}

run_loop()
{
  count=$start_from_run
  while [ $count -le $max_runs ]
  do
    echo "Running $count of $max_runs..."

    local full_output
    full_output="$( (time -p $cmd_to_run) 2>&1)"
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]
    then
      echo "$RED^ FAILED!$NOCOLOUR"
      add_failure_to_log "$full_output"
    fi

    local time_output
    time_output=$(echo "$full_output"|grep "real\s*\d*"|awk '{ print $2 }')
    print_single_run "$count" "$time_output"
    run_so_far=$count
    : $((count+=1))
  done
}

print_run_summary()
{
  if [ "$failures" -ne 0 ]
  then
    echo "$RED+--- "
    echo "| Done, printing unique failures:"
    echo "| "

    echo "$ORANGE"
    print_unique_failures
  else
    echo "$GREEN+--- "
    echo "| Done, without any failures!"
    echo "| "
  fi

  echo "$NOCOLOUR+--- "
  echo "| Started at: $start_time"
  echo "|   Finished: $(date)"
  echo "| Time taken: $(time_from_seconds $total_duration)"

  if [ $run_so_far -ne $max_runs ]
  then
    echo "|   Failures: $failures out of $run_so_far runs ($max_runs max)"
  else
    echo "|   Failures: $failures out of $run_so_far runs"
  fi

  echo "|     Unique: $unique_failures out of $failures total failures"
  echo "| "
}

#
# THEN functions
#

rotate_logs_and_start_run()
{
  rotate_logs
  start_from_run=1
  statebot_emit "resume-run"
}

start_or_resume_run()
{
  run_loop
  statebot_emit "finished"
}

all_done()
{
  print_run_summary
  statebot_reset
  exit "$unique_failures"
}

catch_interrupt()
{
  echo ""
  echo "${PURPLE}[CTRL+C] Manual intervention, pausing..."
  echo "Run again without args to resume: ./rerun.sh$NOCOLOUR"
  echo ""

  save_run_position
  print_run_summary
  exit "$unique_failures"
}

# Import + init Statebot
cd "${0%/*}" || exit 255
# shellcheck disable=SC1091
STATEBOT_LOG_LEVEL=3 . ../../statebot.sh
statebot_init "rerun" "idle" "" "$RERUN_CHART"
trap "statebot_emit ctrl-c-hit" INT

#
# Entry point
#

if [ "$1" = "reset" ]
then
  echo ""
  echo "Resetting..."
  echo ""
  statebot_reset
  exit 255
fi

if [ "$CURRENT_STATE" = "paused" ]
then
  if [ "$1" = "" ]
  then
    load_run_position
    statebot_emit "resume-run"
  else
    statebot_reset
  fi
fi

if [ "$CURRENT_STATE" != "idle" ]
then
  echo ""
  echo "Looks like you're already running something!"
  echo "If you're not, clear the current state using:"
  echo ""
  echo "  ./rerun.sh reset"
  echo ""
  exit 255
fi

if ! echo "$1" | grep -Eq '^[0-9]+$'
then
  echo ""
  echo "Please specify the number of iterations as the first argument"
  echo "$HELP"
  exit 255
fi

max_runs=$1
shift 1
cmd_to_run="${*}"

if [ "$cmd_to_run" = "" ]
then
  echo ""
  echo "Please specify the thing to run"
  echo "$HELP"
  exit 255
fi

statebot_emit "init-run"
