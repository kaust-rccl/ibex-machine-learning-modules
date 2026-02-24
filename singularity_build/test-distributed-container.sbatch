#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=v100:2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=32G
#SBATCH --partition=debug
#SBATCH --job-name=test-distributed-container
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Distributed ML Libraries Test - Singularity Container
# ==============================================================================
# Tests distributed computing frameworks in the ML module container:
# - PyTorch Distributed (DDP, torchrun)
# - Dask Distributed
# - Ray Distributed
# - NCCL multi-GPU communication
# ==============================================================================

set -euo pipefail

echo "=========================================="
echo "Distributed ML Libraries Test"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Date: $(date)"
echo "GPUs: $SLURM_GPUS_ON_NODE"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo ""

# Load ML module
module purge
module load rl9-gpustack
module load machine_learning/2026.01

if [[ -z "${ML_CONTAINER_PATH:-}" ]]; then
    echo "[FAIL] ML_CONTAINER_PATH not set"
    exit 1
fi

CONTAINER_PATH="${ML_CONTAINER_PATH}"
echo "[OK] Container: ${CONTAINER_PATH}"
echo ""

# Create test results directory
TEST_DIR="/ibex/user/$USER/ibex-machine-learning-modules/test-results"
mkdir -p "${TEST_DIR}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEST_LOG="${TEST_DIR}/distributed-test-${TIMESTAMP}.log"

echo "Test log: ${TEST_LOG}"
echo ""

# Bind mounts
BIND_MOUNTS="--bind /ibex/user/$USER"
BIND_MOUNTS="${BIND_MOUNTS} --bind $(pwd):/workspace"

# Distributed environment variables
export MASTER_ADDR=127.0.0.1
export MASTER_PORT=12355
export NCCL_DEBUG=INFO
export OMP_NUM_THREADS=6

echo "=========================================="
echo "Starting Container Tests"
echo "=========================================="

singularity exec --nv ${BIND_MOUNTS} "${CONTAINER_PATH}" /bin/bash -lc "

python /workspace/tests/test_env_info.py
echo ''

python /workspace/tests/distributed_test_script.py
echo ''

python /workspace/tests/test_tensorflow_mirrored.py
echo ''

python /workspace/tests/test_mpi.py
echo ''

# ==============================================================================
# Summary
# ==============================================================================
echo '=========================================='
echo 'Test Summary'
echo '=========================================='
echo 'All distributed tests completed'
echo 'Check output above for [PASS]/[FAIL]/[SKIP] status'
echo ''

" 2>&1 | tee "${TEST_LOG}"

echo ""
echo "=========================================="
echo "Test completed"
echo "Log saved to: ${TEST_LOG}"
echo "=========================================="
