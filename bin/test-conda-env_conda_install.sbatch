#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=test-conda-env
#SBATCH --mail-type=END,FAIL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

#
# Conda ML Environment Testing SLURM Job
#
# This job runs comprehensive tests on the conda ML environment
# Tests all major frameworks and capabilities
#
# Customize:
#   --time: Adjust based on test complexity
#   --gpus-per-node: Change GPU requirements
#   --partition: Change to your preferred partition
#
# To generate a modulefile after successful tests:
#   export MODULESHOME=/path/to/modulefiles
#   export VERSION=2026.01
#   bash bin/generate_modulefile_conda_install.sh
#
# Usage: sbatch bin/test-conda-env_conda_install.sbatch

set -euo pipefail

echo "=========================================="
echo "Conda ML Environment Test Job"
echo "=========================================="
echo "Job ID:        ${SLURM_JOB_ID}"
echo "Node:          $(hostname)"
echo "Partition:     ${SLURM_JOB_PARTITION}"
echo "Start Time:    $(date)"
echo ""

# Initialize conda
export CONDA_PKGS_DIRS="${SLURM_TMPDIR:-.}/.conda_cache"

# Source conda activation
if [[ -f "/ibex/user/${USER}/miniconda3/bin/activate" ]]; then
    source "/ibex/user/${USER}/miniconda3/bin/activate"
elif [[ -f "/opt/conda/etc/profile.d/conda.sh" ]]; then
    source "/opt/conda/etc/profile.d/conda.sh"
else
    echo "ERROR: Could not find conda initialization script"
    exit 1
fi

# Set up paths
export PREFIX="${SLURM_SUBMIT_DIR}"
export ENV_PREFIX="${PREFIX}/env"

echo "[INFO] Project directory: ${PREFIX}"
echo "[INFO] Environment path: ${ENV_PREFIX}"
echo ""

# Check if environment exists
if [[ ! -d "${ENV_PREFIX}" ]]; then
    echo "ERROR: Conda environment not found at ${ENV_PREFIX}"
    echo "Please run: sbatch bin/create-conda-env_conda_install.sbatch"
    exit 1
fi

# Activate the environment
echo "Activating conda environment..."
conda activate "${ENV_PREFIX}"

# Verify activation
echo "Environment activated: ${CONDA_DEFAULT_ENV}"
echo "Python: $(python --version)"
echo ""

# Create logs directory
mkdir -p "${PREFIX}/logs"

# Run tests
echo "=========================================="
echo "Running ML Environment Tests"
echo "=========================================="
echo ""

# Run the test script if it exists in the project
if [[ -f "${PREFIX}/tests/ml_env_test_script.py" ]]; then
    echo "Running ml_env_test_script.py..."
    cd "${PREFIX}"
    python tests/ml_env_test_script.py
    TEST_RESULT=$?
elif [[ -f "${PREFIX}/bin/ml_env_test_script.py" ]]; then
    echo "Running ml_env_test_script.py..."
    cd "${PREFIX}"
    python bin/ml_env_test_script.py
    TEST_RESULT=$?
else
    echo "ml_env_test_script.py not found, running quick verification instead..."
    bash "${PREFIX}/bin/verify_install_conda_install.sh" "${ENV_PREFIX}"
    TEST_RESULT=$?
fi

echo ""
echo "=========================================="
if [[ ${TEST_RESULT} -eq 0 ]]; then
    echo "✓ Tests completed successfully"
else
    echo "⚠ Tests completed with warnings or errors (see output above)"
fi
echo "End Time: $(date)"
echo "=========================================="

exit ${TEST_RESULT}
