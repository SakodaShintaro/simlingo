#!/bin/bash
# Usage: scripts/eval_1route.sh [ROUTE_ID]
#   ROUTE_ID: 00..219 (default: 00)
#   Env override: PORT, TM_PORT, GPU_RANK, SIMLINGO_CKPT, SIMLINGO_BIAS_CONFIG
#     SIMLINGO_BIAS_CONFIG: optional path to a sensor-bias YAML (configs/bias/*.yaml)
set -euo pipefail

ROUTE_ID="${1:-00}"
PORT="${PORT:-2020}"
TM_PORT="${TM_PORT:-8020}"
GPU_RANK="${GPU_RANK:-0}"

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"

ROUTE_FILE="$WORK_DIR/leaderboard/data/bench2drive_split/bench2drive_$ROUTE_ID.xml"
if [[ ! -f "$ROUTE_FILE" ]]; then
    echo "Route file not found: $ROUTE_FILE" >&2
    exit 1
fi

OUT_DIR="$WORK_DIR/eval_res"
VIZ_DIR="$WORK_DIR/eval_viz/$ROUTE_ID"
RESULT_FILE="$OUT_DIR/${ROUTE_ID}_res.json"

mkdir -p "$OUT_DIR" "$VIZ_DIR"
# trailing slash matters: agent_simlingo.py:212 concatenates SAVE_PATH + save_path_root without separator
export SAVE_PATH="$VIZ_DIR/"

echo "=== Route $ROUTE_ID ==="
echo "Checkpoint:  $SIMLINGO_CKPT"
echo "Result:      $RESULT_FILE"
echo "Port:        $PORT (TM: $TM_PORT) GPU: $GPU_RANK"
echo "Bias config: ${SIMLINGO_BIAS_CONFIG:-(none)}"

python "$LEADERBOARD_ROOT/leaderboard/leaderboard_evaluator.py" \
    --routes="$ROUTE_FILE" \
    --repetitions=1 \
    --track=SENSORS \
    --checkpoint="$RESULT_FILE" \
    --agent="$WORK_DIR/team_code/agent_simlingo.py" \
    --agent-config="$SIMLINGO_CKPT" \
    --traffic-manager-seed=1 \
    --port="$PORT" \
    --traffic-manager-port="$TM_PORT" \
    --gpu-rank="$GPU_RANK" \
    --timeout=600
