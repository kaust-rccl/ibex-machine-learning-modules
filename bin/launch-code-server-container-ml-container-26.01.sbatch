#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=v100:1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --partition=debug
#SBATCH --job-name=ml-code-server
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Interactive Code Server with Machine Learning Module 2026
# ==============================================================================
# This script launches Visual Studio Code Server inside the ML Module container
# for interactive development and data science work on Ibex HPC cluster.
#
# Features:
# - GPU-accelerated computing with RAPIDS, PyTorch, TensorFlow, JAX
# - Full VS Code IDE in browser with extension support
# - Persistent configuration and extensions
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

preparing_code_server_environment() {
    
    echo "[INFO] Setting up Code Server environment directories..."
    
    for var in CODE_SERVER_CONFIG_DIR CODE_SERVER_DATA_DIR CODE_SERVER_EXTENSIONS_DIR; do
        dir="${!var}"
        if [[ ! -d "$dir" ]]; then
            echo "[INFO] Creating ${var} at: ${dir}"
            mkdir -p "$dir"
        else
            echo "[OK] Found existing ${var} at: ${dir}"
        fi
    done
    
    echo "[OK] Code Server environment prepared"
}

# ==============================================================================
# Job Information
# ==============================================================================

echo "=========================================="
echo "ML Module Code Server (2026)"
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
#module purge
module load rl9-gpustack
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
# Step 3/4: Configure Code Server Environment
# ==============================================================================

echo "=== Step 3/4: Configuring Code Server Environment ==="

# Define Code Server directories in user's high-performance storage
export SCRATCH_DIR="/ibex/user/$USER"
export CODE_SERVER_CONFIG_DIR="${SCRATCH_DIR}/.config/code-server"
export CODE_SERVER_DATA_DIR="${SCRATCH_DIR}/.local/share/code-server"
export CODE_SERVER_EXTENSIONS_DIR="${SCRATCH_DIR}/.vscode-server/extensions"

# XDG directories for code-server
export XDG_CONFIG_HOME="${SCRATCH_DIR}/.config"
export XDG_DATA_HOME="${SCRATCH_DIR}/.local/share"
export XDG_CACHE_HOME="${SCRATCH_DIR}/.cache"

# Create Code Server directories
preparing_code_server_environment
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}"

# Workspace directories
PROJECT_DIR="${SLURM_SUBMIT_DIR}"
WORK_DIR="${SCRATCH_DIR}/projects"
mkdir -p "${WORK_DIR}"

echo "[INFO] Project directory: ${PROJECT_DIR}"
echo "[INFO] Workspace directory: ${WORK_DIR}"
echo "[INFO] Extensions directory: ${CODE_SERVER_EXTENSIONS_DIR}"
echo ""

# ==============================================================================
# Step 4/4: Setup SSH Tunneling and Launch Code Server
# ==============================================================================

echo "=== Step 4/4: Starting Code Server ==="

# Configure runtime + networking
MY_UID=$(id -u)
export XDG_RUNTIME_DIR="/ibex/user/$USER/.run/user/${MY_UID}"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"
COMPUTE_NODE=$(hostname -s)
SUBMIT_HOST=${SLURM_SUBMIT_HOST}
CODE_SERVER_PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

# Display connection instructions
INSTRUCTIONS="
╔════════════════════════════════════════════════════════════════════════════╗
║                   CODE SERVER CONNECTION INSTRUCTIONS                       ║
╚════════════════════════════════════════════════════════════════════════════╝

📋 Connection Steps:

1. Open a NEW terminal on your local machine (laptop/workstation) and run:

   ssh -L localhost:${CODE_SERVER_PORT}:${COMPUTE_NODE}:${CODE_SERVER_PORT} ${USER}@glogin.ibex.kaust.edu.sa 


2. Open your web browser and navigate to:

   http://localhost:${CODE_SERVER_PORT}

3. When finished:
   - Close all VS Code tabs and windows
   - Or cancel this job: scancel ${SLURM_JOB_ID}

💡 TIPS:
   - Install VS Code extensions directly from the Extensions panel
   - Extensions persist in: ${CODE_SERVER_EXTENSIONS_DIR}
   - Terminal in VS Code uses the ML conda environment automatically
   - GPU access available for ML/DL development

⚠️  IMPORTANT: 
   - Keep SSH tunnel active while working
   - Save your work regularly
   - Extensions install to persistent storage

═══════════════════════════════════════════════════════════════════════════

🚀 Starting Code Server on ${COMPUTE_NODE}.ibex.kaust.edu.sa:${CODE_SERVER_PORT}
"

echo -e "${INSTRUCTIONS}"

# Code Server configuration file
CODE_SERVER_CONFIG="${CODE_SERVER_CONFIG_DIR}/config.yaml"
cat > "${CODE_SERVER_CONFIG}" <<EOF
bind-addr: ${COMPUTE_NODE}:${CODE_SERVER_PORT}
auth: none
cert: false
disable-telemetry: true
disable-update-check: true
user-data-dir: ${CODE_SERVER_DATA_DIR}
extensions-dir: ${CODE_SERVER_EXTENSIONS_DIR}
EOF

echo "[OK] Code Server config created: ${CODE_SERVER_CONFIG}"

# Environment variables for Code Server
export PYTHONUNBUFFERED=1

# Bind mounts for container
BIND_MOUNTS="--bind ${SCRATCH_DIR}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${PROJECT_DIR}:/workspace"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${CODE_SERVER_CONFIG_DIR}:${CODE_SERVER_CONFIG_DIR}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${CODE_SERVER_DATA_DIR}:${CODE_SERVER_DATA_DIR}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${CODE_SERVER_EXTENSIONS_DIR}:${CODE_SERVER_EXTENSIONS_DIR}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${XDG_CONFIG_HOME}:${XDG_CONFIG_HOME}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${XDG_DATA_HOME}:${XDG_DATA_HOME}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${XDG_CACHE_HOME}:${XDG_CACHE_HOME}"
BIND_MOUNTS="${BIND_MOUNTS} --bind ${XDG_RUNTIME_DIR}:/run/user/${MY_UID}"

# Use code-server from the container (latest image already includes it)
CODE_SERVER_EXEC="code-server"

# Launch Code Server inside the container
echo "[INFO] Launching Code Server..."
singularity exec --nv ${BIND_MOUNTS} \
    "${CONTAINER_PATH}" \
    /bin/bash -lc "

    # Ensure a valid runtime dir for VS Code IPC
    export XDG_RUNTIME_DIR=/run/user/${MY_UID}
    mkdir -p \"$XDG_RUNTIME_DIR\"
    chmod 700 \"$XDG_RUNTIME_DIR\"

    # Clear any existing VS Code IPC hooks to prevent connecting to old instances
    unset VSCODE_IPC_HOOK_CLI
    unset VSCODE_IPC_HOOK
    
    # Launch code-server listening on TCP port (not socket) for SSH tunneling
    ${CODE_SERVER_EXEC} \
        --verbose \
        --config ${CODE_SERVER_CONFIG} \
        ${PROJECT_DIR}
    "

echo ""
echo "=========================================="
echo "Code Server session ended"
echo "Job completed: $(date)"
echo "=========================================="
