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
export PACKAGE="${PACKAGE:-machine_learning}"
export SRCDIR="${SOFTWARE_SOURCE_DIRECTORY}/${PACKAGE}"
export VERSION="${VERSION:-2026.02}"
export MODULESHOME="${SOFTWARE_SOURCE_DIRECTORY}/modulefiles/applications/${PACKAGE}"

# PREFIX is the working directory where repo will be cloned
export PREFIX="${SRCDIR}/${VERSION}"
export ENV_FOLDER_SUFFIX="rl9_cuda12.9_py3.12_env"
export ENV_PREFIX="${PREFIX}/${ENV_FOLDER_SUFFIX}"
export SRC_REPO="${SRC_REPO:-https://github.com/D-Barradas/ibex-machine-learning-modules.git}"

echo "[INFO] Software directory: ${SOFTWARE_SOURCE_DIRECTORY}"
echo "[INFO] Package name: ${PACKAGE}"
echo "[INFO] Version: ${VERSION}"
echo "[INFO] Working directory (PREFIX): ${PREFIX}"
echo "[INFO] Final env location (ENV_PREFIX): ${ENV_PREFIX}"
echo "[INFO] Repository: ${SRC_REPO}"
echo "[INFO] Conda cache: ${CONDA_PKGS_DIRS}"
echo ""

# Create necessary directories for PREFIX
mkdir -p "${PREFIX}"
mkdir -p "${PREFIX}/logs"

# Run the installation from SLURM_SUBMIT_DIR
echo \"Starting installation at $(date)...\"
echo \"==========================================\"

# ========================== STEP 1: CLONE REPOSITORY ==========================
echo "[INFO] STEP 1: Create the environment directory..."
echo "========================================================================="
mkdir -p "${ENV_PREFIX}"

# ========================== STEP 2: CLONE REPOSITORY ==========================
echo "[INFO] STEP 2: Cloning repository into the environment directory..."
echo "========================================================================="

# Check for git command availability
command -v git >/dev/null 2>&1 || { 
    echo "$PACKAGE - git is required but not installed - installation failed"
    exit 1
}

# Clone the repository
if ! git clone "${SRC_REPO}" -b "machine-learning-${VERSION}" "${ENV_PREFIX}" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Repository clone failed"
    echo "$PACKAGE - repository clone failure - installation failed"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Repository cloned successfully"
echo ""


# ========================== STEP 3: run_install ==========================
echo "[INFO] STEP 3: Running installation script..."
echo "========================================================================="
if bash "${ENV_PREFIX}/bin/run_install_conda_install.sh" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Installation completed successfully"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Installation failed"
    echo "$PACKAGE - installation script failure - installation failed"
    exit 1
fi  

echo "=========================================="
echo "Installation finished at $(date)"
echo "=========================================="

# ========================== STEP 4: create the module file ==========================
echo "[INFO] STEP 4: Creating module file..."
echo "========================================================================="
if bash "${PREFIX}/bin/generate_modulefile_conda_install.sh" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Module file created successfully"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Module file creation failed"
    echo "$PACKAGE - module file creation failure - installation failed"
    exit 1
fi