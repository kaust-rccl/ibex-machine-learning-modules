#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --gpus-per-node=v100:2
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=test-distributed
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

set -euo pipefail

echo "=========================================="
echo "Conda Distributed Test Job"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Partition: ${SLURM_JOB_PARTITION}"
echo "Start Time: $(date)"
echo ""

PROJECT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p "${PROJECT_DIR}/logs"

if [[ -f /etc/profile.d/modules.sh ]]; then
	source /etc/profile.d/modules.sh
fi

module purge
module load rl9-gpustack
module load machine_learning/2026.02

echo "[INFO] Loaded module: machine_learning/2026.02"
echo "[INFO] Project directory: ${PROJECT_DIR}"

if [[ -f "${PROJECT_DIR}/tests/distributed_test_script.py" ]]; then
	TEST_SCRIPT="${PROJECT_DIR}/tests/distributed_test_script.py"
elif [[ -f "${PROJECT_DIR}/bin/distributed_test_script.py" ]]; then
	TEST_SCRIPT="${PROJECT_DIR}/bin/distributed_test_script.py"
else
	echo "[ERROR] distributed_test_script.py not found in tests/ or bin/"
	exit 1
fi

echo "[INFO] Test script: ${TEST_SCRIPT}"
echo ""

nvidia-smi
python -c "import torch; print('torch', torch.__version__, 'cuda devices', torch.cuda.device_count())"

export MASTER_ADDR=127.0.0.1
export MASTER_PORT="${MASTER_PORT:-12355}"
export NCCL_DEBUG=INFO
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-6}"

NPROC_PER_NODE="${SLURM_GPUS_ON_NODE:-2}"

echo "[INFO] MASTER_ADDR=${MASTER_ADDR}"
echo "[INFO] MASTER_PORT=${MASTER_PORT}"
echo "[INFO] NPROC_PER_NODE=${NPROC_PER_NODE}"
echo ""

torchrun --standalone --nproc_per_node="${NPROC_PER_NODE}" "${TEST_SCRIPT}"

EXIT_CODE=$?
echo ""
echo "=========================================="
echo "Distributed test completed with exit code: ${EXIT_CODE}"
echo "End Time: $(date)"
echo "=========================================="

exit ${EXIT_CODE}