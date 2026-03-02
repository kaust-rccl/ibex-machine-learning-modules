#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=debug
#SBATCH --job-name=test-conda-env
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

set -euo pipefail
echo "=========================================="
echo "Conda ML Environment Test Job"
echo "=========================================="
echo "Job ID:        ${SLURM_JOB_ID}"
echo "Node:          $(hostname)"
echo "Partition:     ${SLURM_JOB_PARTITION}"
echo "Start Time:    $(date)"
echo ""
# export CONDA_PKGS_DIRS=/ibex/user/${USER}/conda_cache
# source /ibex/user/${USER}/miniconda3/bin/activate

PROJECT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p "${PROJECT_DIR}/logs"

# Initialize module system
if [[ -f /etc/profile.d/modules.sh ]]; then
    source /etc/profile.d/modules.sh
fi
echo "=========================================="
echo "Loading modules..."
echo "=========================================="

module purge
module load rl9-gpustack
module load machine_learning/2026.02

echo "[INFO] Loaded module: machine_learning/2026.02"
echo "[INFO] Project directory: ${PROJECT_DIR}"
echo "[INFO] GPUs allocated: ${SLURM_GPUS_ON_NODE:-N/A}"
echo "[INFO] CPUs per GPU: ${SLURM_CPUS_PER_GPU:-N/A}"
echo ""

# Locate test script
TEST_SCRIPT=""
if [[ -f "${PROJECT_DIR}/tests/ml_env_test_script.py" ]]; then
    TEST_SCRIPT="${PROJECT_DIR}/tests/ml_env_test_script.py"
elif [[ -f "${PROJECT_DIR}/bin/ml_env_test_script.py" ]]; then
    TEST_SCRIPT="${PROJECT_DIR}/bin/ml_env_test_script.py"
else
    echo "[ERROR] Could not find ml_env_test_script.py in tests/ or bin/"
    exit 1
fi

echo "[INFO] Running test script: ${TEST_SCRIPT}"
echo ""

python "${TEST_SCRIPT}"

EXIT_CODE=$?
echo ""
echo "=========================================="
echo "ML environment test completed with exit code: ${EXIT_CODE}"
echo "End Time: $(date)"
echo "=========================================="

exit ${EXIT_CODE}