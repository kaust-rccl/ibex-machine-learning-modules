#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=ml-jupyter-server
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Interactive Jupyter Lab Server with ML Module Container
# ==============================================================================
# This script starts a Jupyter Lab server inside the container.
# After the job starts, you'll need to create an SSH tunnel to access it.
# ==============================================================================

set -e

echo "=========================================="
echo "Jupyter Lab Server Job"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo ""

# ==============================================================================
# Configuration
# ==============================================================================

CONTAINER="/ibex/shared/modules/machine-learning/1.0/ml_module.sif"
# Or use local container:
# CONTAINER="$PWD/ml_module_v1.0.sif"

JUPYTER_PORT=8888
WORK_DIR="/ibex/user/$USER"

# Create notebook directory if it doesn't exist
mkdir -p "$WORK_DIR/notebooks"

# Bind mounts
BIND_MOUNTS="--bind $WORK_DIR:/work"
BIND_MOUNTS="$BIND_MOUNTS --bind $PWD:/workspace"
BIND_MOUNTS="$BIND_MOUNTS --bind $SLURM_TMPDIR:/tmp"

# ==============================================================================
# Generate Jupyter Configuration
# ==============================================================================

JUPYTER_CONFIG_DIR=$(mktemp -d)
cat > "$JUPYTER_CONFIG_DIR/jupyter_lab_config.py" <<EOF
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = $JUPYTER_PORT
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.root_dir = '/work'
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
EOF

BIND_MOUNTS="$BIND_MOUNTS --bind $JUPYTER_CONFIG_DIR:/jupyter-config"
export JUPYTER_CONFIG_DIR=/jupyter-config

# ==============================================================================
# Display Connection Information
# ==============================================================================

COMPUTE_NODE=$(hostname)
GATEWAY="ibex-login.kaust.edu.sa"  # Update with your gateway

echo "=========================================="
echo "Jupyter Lab Connection Information"
echo "=========================================="
echo "Compute node: $COMPUTE_NODE"
echo "Jupyter port: $JUPYTER_PORT"
echo ""
echo "To access Jupyter Lab, run this command on your LOCAL machine:"
echo ""
echo "  ssh -L ${JUPYTER_PORT}:${COMPUTE_NODE}:${JUPYTER_PORT} ${USER}@${GATEWAY}"
echo ""
echo "Then open in your browser:"
echo "  http://localhost:${JUPYTER_PORT}"
echo ""
echo "=========================================="
echo ""

# ==============================================================================
# Start Jupyter Lab
# ==============================================================================

echo "Starting Jupyter Lab server..."
echo ""

# Set environment variables
export PYTHONUNBUFFERED=1

# Start Jupyter Lab in the container
singularity exec --nv $BIND_MOUNTS "$CONTAINER" \
    jupyter lab \
        --ip=0.0.0.0 \
        --port=$JUPYTER_PORT \
        --no-browser \
        --notebook-dir=/work

# Note: The job will run until the time limit or until you manually cancel it
# To stop the server: scancel $SLURM_JOB_ID
