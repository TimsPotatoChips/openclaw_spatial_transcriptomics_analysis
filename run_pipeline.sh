#!/usr/bin/env bash
#
# run_pipeline.sh — Spatial Transcriptomics pipeline runner (CS298)
#
# Runs the analysis scripts in the required order:
#   1) ensemble_clustering.py
#   2) annotator.py        (uses ovarian_knowledge_base.py)
#   3) ai_agent.py         (needs OPENAI_API_KEY from .env)
#
# Usage:
#   ./run_pipeline.sh              # run all stages in order
#   ./run_pipeline.sh ensemble    # run a single stage (ensemble|annotator|agent)
#
# Aborts immediately if the GEF input file is missing or any stage fails.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

PY="$PROJECT_DIR/.venv/bin/python"
LOG_DIR="$PROJECT_DIR/logs"
RUN_TS="$(date +%Y%m%d_%H%M%S)"

# --- Load secrets / overrides (.env defines OPENAI_API_KEY, optional ST_* vars) ---
if [[ -f "$PROJECT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
fi

# Resolve the GEF input:
#   1) explicit ST_INPUT_GEF wins
#   2) else the expected default filename
#   3) else auto-detect if exactly one *.gef exists in the folder
GEF="${ST_INPUT_GEF:-$PROJECT_DIR/B04372C211.adjusted.cellbin.gef}"
if [[ -z "${ST_INPUT_GEF:-}" && ! -f "$GEF" ]]; then
  shopt -s nullglob
  gef_matches=("$PROJECT_DIR"/*.gef)
  shopt -u nullglob
  if [[ ${#gef_matches[@]} -eq 1 ]]; then
    GEF="${gef_matches[0]}"
  elif [[ ${#gef_matches[@]} -gt 1 ]]; then
    echo "ERROR: multiple .gef files found; set ST_INPUT_GEF to pick one:" >&2
    printf '       %s\n' "${gef_matches[@]}" >&2
    exit 2
  fi
fi

# --- Preflight checks --------------------------------------------------------
if [[ ! -x "$PY" ]]; then
  echo "ERROR: venv Python not found at $PY" >&2
  echo "       Run: /usr/bin/python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt" >&2
  exit 1
fi

if [[ ! -f "$GEF" ]]; then
  echo "ERROR: GEF input file not found:" >&2
  echo "       $GEF" >&2
  echo "       Place the .gef file in $PROJECT_DIR (or set ST_INPUT_GEF) and re-run." >&2
  exit 2
fi

export ST_INPUT_GEF="$GEF"
mkdir -p "$LOG_DIR"

run_stage() {
  local name="$1" script="$2"
  local log="$LOG_DIR/${RUN_TS}_${name}.log"
  echo ">>> [$name] starting: $script"
  echo "    input : $ST_INPUT_GEF"
  echo "    log   : $log"
  local start; start=$(date +%s)
  if "$PY" "$script" >"$log" 2>&1; then
    local dur=$(( $(date +%s) - start ))
    echo "<<< [$name] done in ${dur}s"
  else
    echo "!!! [$name] FAILED — see $log (last lines below):" >&2
    tail -20 "$log" >&2
    exit 3
  fi
}

STAGE="${1:-all}"
echo "=== Spatial Transcriptomics pipeline | run $RUN_TS | stage=$STAGE ==="

case "$STAGE" in
  ensemble)  run_stage ensemble  ensemble_clustering.py ;;
  annotator) run_stage annotator annotator.py ;;
  agent)     run_stage agent     ai_agent.py ;;
  all)
    run_stage ensemble  ensemble_clustering.py
    run_stage annotator annotator.py
    run_stage agent     ai_agent.py
    ;;
  *)
    echo "ERROR: unknown stage '$STAGE' (use: ensemble | annotator | agent | all)" >&2
    exit 1
    ;;
esac

echo "=== pipeline complete ==="
