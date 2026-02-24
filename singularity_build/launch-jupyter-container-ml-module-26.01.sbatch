#!/bin/bash -l
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=v100:2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --partition=debug
#SBATCH --job-name=ml-jupyter-lab
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Interactive Jupyter Lab Server with Machine Learning Module 2026
# ==============================================================================
# This script launches a Jupyter Lab server inside the ML Module container
# for interactive data science and machine learning work on Ibex HPC cluster.
#
# Features:
# - GPU-accelerated computing with RAPIDS, PyTorch, TensorFlow, JAX
# - Persistent Jupyter configuration and runtime directories
# - Automatic container validation
# - Clear SSH tunneling instructions
# - Production-ready for HPC environments
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Helper Function Definitions
# ==============================================================================

checking_container_image() {
    
    # Check if image exists
    if [[ ! -f "${CONTAINER_PATH}" ]]; then
        echo "[FAIL] Container not found at: ${CONTAINER_PATH}"
        echo "[INFO] Please verify the machine_learning module is loaded correctly"
        echo "[INFO] Or build the container using: bash bin/setup_install.sh"
        exit 1
    fi
    
    echo "[OK] Found container: ${CONTAINER_PATH}"
    
    # Validate container integrity
    if singularity inspect "${CONTAINER_PATH}" > /dev/null 2>&1; then
        echo "[OK] Container validation successful"
    else
        echo "[FAIL] Container is corrupted or invalid"
        echo "[INFO] Please rebuild the container"
        exit 1
    fi
}

preparing_jupyter_environment() {
    
    echo "[INFO] Setting up Jupyter environment directories..."
    
    for var in JUPYTER_CONFIG_DIR JUPYTER_DATA_DIR JUPYTER_RUNTIME_DIR IPYTHONDIR; do
        dir="${!var}"
        if [[ ! -d "$dir" ]]; then
            echo "[INFO] Creating ${var} at: ${dir}"
            mkdir -p "$dir"
        else
            echo "[OK] Found existing ${var} at: ${dir}"
        fi
    done
    
    echo "[OK] Jupyter environment prepared"
}

# ==============================================================================
# Job Information
# ==============================================================================

echo "=========================================="
echo "ML Module Jupyter Lab Server (2026)"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Date: $(date)"
echo "User: $USER"
echo "GPUs allocated: $SLURM_GPUS_ON_NODE"
echo "CPUs allocated: $SLURM_CPUS_PER_TASK"
echo "Memory allocated: $SLURM_MEM_PER_NODE MB"
echo ""

# ==============================================================================
# Step 1/4: Load Machine Learning Module
# ==============================================================================

echo "=== Step 1/4: Loading Machine Learning Module ==="
module purge
module load machine_learning/2026.01

# Verify module loaded correctly
if [[ -z "${ML_CONTAINER_PATH:-}" ]]; then
    echo "[FAIL] ML_CONTAINER_PATH not set. Module load failed."
    echo "[INFO] Available modules:"
    module avail machine_learning
    exit 1
fi

CONTAINER_PATH="${ML_CONTAINER_PATH}"
echo "[OK] Machine learning module loaded"
echo "[INFO] Container: ${CONTAINER_PATH}"
echo ""

# ==============================================================================
# Step 2/4: Validate Container Image
# ==============================================================================

echo "=== Step 2/4: Validating Container Image ==="
checking_container_image
echo ""

# ==============================================================================
# Step 3/4: Configure Jupyter Environment
# ==============================================================================

echo "=== Step 3/4: Configuring Jupyter Environment ==="

# Define Jupyter directories in user's high-performance storage
export SCRATCH_DIR="/ibex/user/$USER"
export JUPYTER_CONFIG_DIR="${SCRATCH_DIR}/.jupyter"
export JUPYTER_DATA_DIR="${SCRATCH_DIR}/.local/share/jupyter"
export JUPYTER_RUNTIME_DIR="${SCRATCH_DIR}/.local/share/jupyter/runtime"
export IPYTHONDIR="${SCRATCH_DIR}/.ipython"

# Create Jupyter directories
preparing_jupyter_environment

# Workspace directories
WORK_DIR="${SCRATCH_DIR}/notebooks"
PROJECT_DIR="${SLURM_SUBMIT_DIR}"
mkdir -p "${WORK_DIR}"

echo "[INFO] Notebook directory: ${WORK_DIR}"
echo ""

# ==============================================================================
# Step 4/4: Setup SSH Tunneling and Launch Jupyter Lab
# ==============================================================================

echo "=== Step 4/4: Starting Jupyter Lab Server ==="

# Configure networking
export XDG_RUNTIME_DIR=/tmp
COMPUTE_NODE=$(hostname -s)
SUBMIT_HOST=${SLURM_SUBMIT_HOST}
JUPYTER_PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

# Display connection instructions
INSTRUCTIONS="
╔════════════════════════════════════════════════════════════════════════════╗
║                  JUPYTER LAB CONNECTION INSTRUCTIONS                        ║
╚════════════════════════════════════════════════════════════════════════════╝

📋 Connection Steps:

1. Open a NEW terminal on your local machine (laptop/workstation) and run:

   ssh -L ${JUPYTER_PORT}:${COMPUTE_NODE}.ibex.kaust.edu.sa:${JUPYTER_PORT} ${USER}@glogin.ibex.kaust.edu.sa

2. Copy the Jupyter URL below (starting with http://127.0.0.1:${JUPYTER_PORT}) 
   and paste it into your web browser

3. When finished:
   - Shutdown Jupyter properly: File → Shut Down
   - Or cancel this job: scancel ${SLURM_JOB_ID}

⚠️  IMPORTANT: Always shutdown Jupyter gracefully to avoid data loss

═══════════════════════════════════════════════════════════════════════════

🚀 Starting Jupyter Lab on ${COMPUTE_NODE}.ibex.kaust.edu.sa:${JUPYTER_PORT}
"

echo -e "${INSTRUCTIONS}"

# Environment variables for Jupyter
export PYTHONUNBUFFERED=1

# Bind mounts for container
BIND_MOUNTS="--bind ${SCRATCH_DIR}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${PROJECT_DIR}:/workspace"

# Launch Jupyter Lab inside the container
singularity exec --nv ${BIND_MOUNTS} \
    "${CONTAINER_PATH}" \
    /bin/bash -lc "
    jupyter ${1:-lab} \
        --no-browser \
        --port=${JUPYTER_PORT} \
        --port-retries=0 \
        --ip=${COMPUTE_NODE}.ibex.kaust.edu.sa \
        --notebook-dir=${WORK_DIR} \
        --NotebookApp.custom_display_url='http://127.0.0.1:${JUPYTER_PORT}/lab'
    "

echo ""
echo "=========================================="
echo "Jupyter Lab session ended"
echo "Job completed: $(date)"
echo "=========================================="
