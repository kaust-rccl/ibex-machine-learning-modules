#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=conda-env-create
#SBATCH --mail-type=END,FAIL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

#
# Conda Environment Creation SLURM Job
#
# This job creates the conda ML environment on a compute node
# Useful for building environments that require GPU resources during setup
#
# Customize:
#   --time: Adjust if environment creation takes longer
#   --mem, --cpus-per-gpu: Adjust based on your resources
#   --partition: Change to your preferred partition
#
# Usage: sbatch bin/create-conda-env_conda_install.sbatch

set -euo pipefail

echo "=========================================="
echo "Conda ML Environment Creation Job"
echo "=========================================="
echo "Job ID:        ${SLURM_JOB_ID}"
echo "Node:          $(hostname)"
echo "Partition:     ${SLURM_JOB_PARTITION}"
echo "Start Time:    $(date)"
echo ""

# Initialize conda
export CONDA_PKGS_DIRS="${SLURM_TMPDIR:-.}/.conda_cache"
mkdir -p "$CONDA_PKGS_DIRS"

# Source conda activation
if [[ -f "/ibex/user/${USER}/miniconda3/bin/activate" ]]; then
    source "/ibex/user/${USER}/miniconda3/bin/activate"
elif [[ -f "/opt/conda/etc/profile.d/conda.sh" ]]; then
    source "/opt/conda/etc/profile.d/conda.sh"
else
    echo "ERROR: Could not find conda initialization script"
    exit 1
fi

# Set up environment variables for installation script

export SOFTWARE_SOURCE_DIRECTORY="/sw/rl9g"
export MODULESHOME="/sw/rl9g/modulefiles/applications/machine_learning"
export PACKAGE="machine_learning"
export SRCDIR="${SOFTWARE_SOURCE_DIRECTORY}/${PACKAGE}"

export PREFIX="${SRCDIR}/${VERSION}"
export ENV_FOLDER_SUFFIX="rl9_cuda12.9_py3.12_env"
export ENV_PREFIX="${PREFIX}/${ENV_FOLDER_SUFFIX}"
export PACKAGE="${PACKAGE:-machine_learning}"
export VERSION="${VERSION:-2026.02}"
export SRC_REPO="${SRC_REPO:-https://github.com/D-Barradas/ibex-machine-learning-modules.git}"





echo "[INFO] Project directory: ${PREFIX}"
echo "[INFO] Environment path: ${ENV_PREFIX}"
echo "[INFO] Package name: ${PACKAGE}"
echo "[INFO] Version: ${VERSION}"
echo "[INFO] Repository: ${SRC_REPO}"
echo "[INFO] Conda cache: ${CONDA_PKGS_DIRS}"
echo ""

# Create necessary directories
mkdir -p "${PREFIX}/logs"
mkdir -p "$(dirname "${ENV_PREFIX}")"

# Run the installation
echo "Starting installation at $(date)..."
echo "=========================================="
if bash "${PREFIX}/bin/run_install_conda_install.sh"; then
    echo ""
    echo "=========================================="
    echo "✓ Environment created successfully"
    echo "End Time: $(date)"
    echo "=========================================="
    
    # Quick verification
    echo ""
    echo "Running quick verification..."
    bash "${PREFIX}/bin/verify_install_conda_install.sh" "${ENV_PREFIX}" || true
    
    # Optional: Generate modulefile
    if [[ "${GENERATE_MODULEFILE:-0}" == "1" ]]; then
        echo ""
        echo "Generating modulefile..."
        export MODULESHOME="${MODULESHOME:-.modulefiles}"
        
        if bash "${PREFIX}/bin/generate_modulefile_conda_install.sh"; then
            echo "✓ Modulefile generated"
        else
            echo "⚠ Modulefile generation failed (non-critical)"
        fi
    fi
    
    exit 0
else
    echo ""
    echo "=========================================="
    echo "✗ Environment creation failed"
    echo "End Time: $(date)"
    echo "=========================================="
    exit 1
fi
