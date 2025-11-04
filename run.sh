#!/usr/bin/env bash
# run.sh — restart the installed midnight-miner whenever it exits

set -uo pipefail  # (no -e, we don't want the loop to die on errors)

# Use same defaults as install.sh
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
NAME="${NAME:-midnight-miner}"
MINER="${BIN_DIR}/${NAME}"

# Check if binary exists
if [[ ! -x "$MINER" ]]; then
  echo "error: ${MINER} not found or not executable" >&2
  echo "       run install.sh first" >&2
  exit 1
fi

DELAY=2  # default restart delay (seconds)
while getopts "d:" opt; do
  case "$opt" in
    d) DELAY="$OPTARG" ;;
  esac
done
shift $((OPTIND - 1))

# Anything after `--` goes to your program
PROG_ARGS=("$@")

# Stop cleanly on Ctrl+C / kill
trap 'echo; echo "[run_loop] stopping..."; exit 0' SIGINT SIGTERM

LAUNCHES=0
BASE_DELAY="$DELAY"

while :; do
  LAUNCHES=$((LAUNCHES+1))
  echo "[run_loop] $(date) — launch #$LAUNCHES"
  START_TS=$(date +%s)

  "$MINER" "${PROG_ARGS[@]}"
  EXIT_CODE=$?

  DUR=$(( $(date +%s) - START_TS ))
  echo "[run_loop] $(date) — exited with code $EXIT_CODE after ${DUR}s"

  # Exponential backoff if it exits instantly (<1s)
  if (( DUR < 1 )); then
    DELAY=$(( DELAY * 2 ))
    (( DELAY > 30 )) && DELAY=30
  else
    DELAY="$BASE_DELAY"
  fi

  echo "[run_loop] restarting in ${DELAY}s (Ctrl+C to stop)..."
  sleep "$DELAY"
done