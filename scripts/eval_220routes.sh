#!/bin/bash
# Usage: scripts/eval_220routes.sh
#   Loops bench2drive_split/*.xml sequentially. Skips routes with existing result json.
#   Each route call auto-starts and shuts down CARLA (60s startup overhead per route).
#   Env override: PORT, TM_PORT, GPU_RANK, SIMLINGO_CKPT, SIMLINGO_BIAS_CONFIG
#     SIMLINGO_BIAS_CONFIG: optional path to a sensor-bias YAML (configs/bias/*.yaml)
set -euo pipefail

PORT="${PORT:-2020}"
TM_PORT="${TM_PORT:-8020}"
GPU_RANK="${GPU_RANK:-0}"

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"

OUT_DIR="$WORK_DIR/eval_res"
mkdir -p "$OUT_DIR"

ROUTE_FILES=("$WORK_DIR"/leaderboard/data/bench2drive_split/bench2drive_*.xml)
TOTAL=${#ROUTE_FILES[@]}

echo "Total routes: $TOTAL"
echo "Checkpoint:   $SIMLINGO_CKPT"
echo "Bias config:  ${SIMLINGO_BIAS_CONFIG:-(none)}"

IDX=0
for ROUTE_FILE in "${ROUTE_FILES[@]}"; do
    IDX=$((IDX + 1))
    ROUTE_NAME=$(basename "$ROUTE_FILE" .xml)
    ROUTE_ID="${ROUTE_NAME#bench2drive_}"
    RESULT_FILE="$OUT_DIR/${ROUTE_ID}_res.json"

    if [[ -f "$RESULT_FILE" ]]; then
        echo "[$IDX/$TOTAL] Skip $ROUTE_ID (result exists)"
        continue
    fi

    VIZ_DIR="$WORK_DIR/eval_viz/$ROUTE_ID"
    mkdir -p "$VIZ_DIR"
    # trailing slash matters: agent_simlingo.py:212 concatenates SAVE_PATH + save_path_root without separator
    export SAVE_PATH="$VIZ_DIR/"

    echo "[$IDX/$TOTAL] === Route $ROUTE_ID ==="

    # set +e so one failing route does not abort the whole batch
    set +e
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
    RC=$?
    set -e

    if [[ $RC -ne 0 ]]; then
        echo "[$IDX/$TOTAL] Route $ROUTE_ID failed (exit $RC); cleaning up CARLA and continuing"
        bash "$WORK_DIR/Bench2Drive/tools/clean_carla.sh" || true
    fi
done

echo "=== Merging results ==="
python "$WORK_DIR/Bench2Drive/tools/merge_route_json.py" -f "$OUT_DIR"
