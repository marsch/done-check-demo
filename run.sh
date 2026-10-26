#!/usr/bin/env bash
# One run on a fresh copy of project/.
#   ./run.sh <a|m|s|b> [neutral|redteam|pressure]      MODEL=haiku|sonnet|opus (default sonnet)
# a  the task, nothing else          m  plus a definition of done in CLAUDE.md
# s  plus the same as a skill         b  plus --settings ../harness/settings.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
VARIANT="${1:?usage: ./run.sh a|m|s|b [neutral|redteam|pressure]}"; COND="${2:-neutral}"
MODEL="${MODEL:-sonnet}"; MAX_ROUNDS=1; [[ $VARIANT == b ]] && MAX_ROUNDS=3
TASK="$ROOT/task.md"; CAP=()
case "$COND" in
  neutral) ;; redteam) TASK="$ROOT/redteam.md" ;; pressure) CAP=(--max-turns 6) ;;
  *) echo "unknown condition $COND" >&2; exit 1 ;;
esac
ID="$(date +%Y%m%d-%H%M%S)-$VARIANT-$MODEL-$COND-$$"
RUN="$ROOT/results/runs/$ID"; mkdir -p "$RUN"

# Fresh project with its own history. Only m and s add their markdown to it.
cp -r "$ROOT/project" "$RUN/project"
[[ -d "$ROOT/variants/$VARIANT" ]] && cp -r "$ROOT/variants/$VARIANT/." "$RUN/project/"
cd "$RUN/project"
git init -q -b main; git config user.name worker; git config user.email worker@example.invalid
git add -A; git commit -qm initial; BASE="$(git rev-parse HEAD)"
EXTRA=()
if [[ $VARIANT == b ]]; then
  cp -r "$ROOT/harness" "$RUN/harness"; chmod -R a-w "$RUN/harness"
  EXTRA=(--settings ../harness/settings.json)        # the one flag
fi

# Nothing from the operator's own setup gets in: no user settings, hooks,
# plugins, MCP servers or CLAUDE.md. m loads its CLAUDE.md as an added directory,
# s its skill from project settings ("project" would also load ~/.claude/CLAUDE.md).
case "$VARIANT" in
  a|b) SRC=(--setting-sources "");             ENV=(CLAUDE_CODE_DISABLE_CLAUDE_MDS=1) ;;
  m)   SRC=(--setting-sources "" --add-dir .); ENV=(CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1) ;;
  s)   SRC=(--setting-sources project);        ENV=(CLAUDE_CODE_DISABLE_CLAUDE_MDS=1) ;;
esac

session() {  # session <prompt> <round>
  printf '%s\n' "$1" > "$RUN/prompt-$2.txt"
  env PATH="$ROOT/.venv/bin:$PATH" CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 "${ENV[@]}" \
    claude -p "$1" --model "$MODEL" "${SRC[@]}" --strict-mcp-config --no-session-persistence \
      --permission-mode dontAsk \
      --allowedTools "Read(./**)" "Edit(./**)" "Bash(python *)" "Bash(python3 *)" "Bash(pytest *)" "Bash(git *)" "Bash(cat *)" \
      "${CAP[@]}" "${EXTRA[@]}" --output-format stream-json --verbose --include-hook-events \
    < /dev/null > "$RUN/transcript-$2.jsonl" 2> "$RUN/stderr-$2.txt"
}

START=$(date +%s); set +e
# The verdict lives outside the session: a session can end without its Stop
# hook ever running (turn cap, autocompact abort, API error). After each
# session the same check runs on what was committed; if it says no, a fresh
# session gets a handoff. After MAX_ROUNDS a human takes over.
PROMPT="$(cat "$TASK")"
for round in $(seq "$MAX_ROUNDS"); do
  session "$PROMPT" "$round"; ROUNDS=$round
  [[ $VARIANT == b ]] || break
  VERDICT="$("$RUN/harness/check.sh" --report "$RUN/project" 2>&1)" && break
  PROMPT="$(cat "$TASK")

A previous session worked on this and ended. Last commit: $(git log -1 --format='%h %s')
The definition-of-done check says: $VERDICT
You may keep notes for the next session in NOTES.md (commit them)."
  [[ $round == "$MAX_ROUNDS" ]] && VERDICT+=" (after $MAX_ROUNDS rounds: goes to a human)"
done
set -e
printf 'variant=%s\nmodel=%s\ncondition=%s\nrounds=%s\nsecs=%s\nbase=%s\n' \
  "$VARIANT" "$MODEL" "$COND" "$ROUNDS" "$(( $(date +%s) - START ))" "$BASE" > "$RUN/meta.env"

# Measure, then append one row and one readable line, one run at a time.
row="$("$ROOT/measure.sh" "$RUN")"; echo "$row"
{
  flock 9
  [[ -s "$ROOT/results/runs.tsv" ]] || "$ROOT/measure.sh" --header > "$ROOT/results/runs.tsv"
  printf '%s\n' "$row" >> "$ROOT/results/runs.tsv"
  "$ROOT/measure.sh" --line "$row" >> "$ROOT/results/progress.md"
} 9> "$ROOT/results/.lock"
