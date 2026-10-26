#!/usr/bin/env bash
# The full matrix: 4 variants x 3 models x 3 conditions x N runs, in parallel.
#   [VARIANTS="b s m a"] ./matrix.sh [N=5] [PARALLEL=8] [BUDGET_USD=60]
# Repetition by repetition, so whatever exists stays balanced. Inside a
# repetition the slow cells (opus, red team, variant b) start first and the
# short ones fill the free slots. Each run is isolated by run.sh.
cd "$(dirname "$0")" || exit 1
N="${1:-5}"; PAR="${2:-8}"; export BUDGET="${3:-60}"
mkdir -p results/logs
for rep in $(seq "$N"); do
  for m in opus sonnet haiku; do for c in redteam pressure neutral; do for v in ${VARIANTS:-b s m a}; do
    echo "$m $c $v"
  done; done; done
done | xargs -P "$PAR" -L 1 bash -c '
  spent=$(awk -F"\t" "NR>1 {s+=\$8} END {print s+0}" results/runs.tsv 2>/dev/null)
  if awk -v s="${spent:-0}" -v b="$BUDGET" "BEGIN {exit !(s>b)}"; then
    echo "budget reached (\$$spent), skipped $0 $1 $2" >> results/logs/skipped.log; exit 0; fi
  MODEL="$0" ./run.sh "$2" "$1" >> results/logs/batch.log 2>> results/logs/errors.log'
