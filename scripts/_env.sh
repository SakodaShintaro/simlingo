# shellcheck shell=bash
# Source from other scripts:  source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"

WORK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export WORK_DIR

CARLA_ROOT="${CARLA_ROOT:-$HOME/CARLA_0.9.16}"
export CARLA_ROOT

export SCENARIO_RUNNER_ROOT="$WORK_DIR/Bench2Drive/scenario_runner"
export LEADERBOARD_ROOT="$WORK_DIR/Bench2Drive/leaderboard"

# $WORK_DIR must precede Bench2Drive/leaderboard so that `import team_code.*`
# resolves to ./team_code (simlingo), not Bench2Drive/leaderboard/team_code.
export PYTHONPATH="$WORK_DIR:$CARLA_ROOT/PythonAPI/carla:$WORK_DIR/Bench2Drive/leaderboard:$WORK_DIR/Bench2Drive/scenario_runner:${PYTHONPATH:-}"

# Resolve checkpoint path. Override by exporting SIMLINGO_CKPT before calling.
if [[ -z "${SIMLINGO_CKPT:-}" ]]; then
    # `huggingface-cli download` is deprecated in huggingface-hub >=0.34 and
    # prints a deprecation banner to stdout that breaks naive capture; use
    # `hf download` and take the last stdout line.
    HF_PATH=$(hf download RenzKa/simlingo 2>/dev/null | tail -n 1)
    SIMLINGO_CKPT=$(find "$HF_PATH" -name "pytorch_model.pt" -not -path "*/blobs/*" | head -n 1)
    export SIMLINGO_CKPT
fi

if [[ ! -f "$SIMLINGO_CKPT" ]]; then
    echo "Checkpoint not found: $SIMLINGO_CKPT" >&2
    echo "Override with: export SIMLINGO_CKPT=/path/to/pytorch_model.pt" >&2
    exit 1
fi
