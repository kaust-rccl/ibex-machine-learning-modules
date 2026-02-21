#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=v100:4
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --partition=batch
#SBATCH --job-name=ml-distributed-training
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Multi-Node Distributed Training with PyTorch DDP
# ==============================================================================
# This example shows how to run distributed training across multiple nodes
# using PyTorch DistributedDataParallel (DDP) with the ML Module container.
# ==============================================================================

set -e

echo "=========================================="
echo "Multi-Node Distributed Training Job"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Number of nodes: $SLURM_NNODES"
echo "GPUs per node: $SLURM_GPUS_PER_NODE"
echo "Total GPUs: $(($SLURM_NNODES * $SLURM_GPUS_PER_NODE))"
echo "Node list: $SLURM_NODELIST"
echo "Master node: $(scontrol show hostname $SLURM_NODELIST | head -n1)"
echo ""

# ==============================================================================
# Configuration
# ==============================================================================

CONTAINER="/ibex/shared/modules/machine-learning/1.0/ml_module.sif"
PROJECT_DIR="$PWD"
DATA_DIR="/ibex/user/$USER/data"
OUTPUT_DIR="/ibex/user/$USER/results/${SLURM_JOB_NAME}-${SLURM_JOB_ID}"

mkdir -p "$OUTPUT_DIR/logs"

TRAINING_SCRIPT="$PROJECT_DIR/examples/train_distributed.py"

# Distributed training parameters
MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n1)
MASTER_PORT=29500
WORLD_SIZE=$(($SLURM_NNODES * $SLURM_GPUS_PER_NODE))

# Bind mounts
BIND_MOUNTS="--bind $PROJECT_DIR:/work"
BIND_MOUNTS="$BIND_MOUNTS --bind $DATA_DIR:/data:ro"
BIND_MOUNTS="$BIND_MOUNTS --bind $OUTPUT_DIR:/output"
BIND_MOUNTS="$BIND_MOUNTS --bind $SLURM_TMPDIR:/tmp"

echo "Master address: $MASTER_ADDR:$MASTER_PORT"
echo "World size: $WORLD_SIZE"
echo ""

# ==============================================================================
# Environment Variables
# ==============================================================================

export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0
export NCCL_NET_GDR_LEVEL=3
export PYTHONUNBUFFERED=1
export CUDA_LAUNCH_BLOCKING=0

# ==============================================================================
# Run Distributed Training with srun
# ==============================================================================

echo "=========================================="
echo "Starting Distributed Training"
echo "=========================================="

srun singularity exec --nv $BIND_MOUNTS "$CONTAINER" \
    python "$TRAINING_SCRIPT" \
        --distributed \
        --backend nccl \
        --init-method "tcp://${MASTER_ADDR}:${MASTER_PORT}" \
        --world-size $WORLD_SIZE \
        --rank \$SLURM_PROCID \
        --local-rank \$SLURM_LOCALID \
        --data-dir /data \
        --output-dir /output \
        --batch-size 256 \
        --epochs 100 \
        --learning-rate 0.001 \
        --sync-bn \
        --gradient-accumulation-steps 4

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Training completed with exit code: $EXIT_CODE"
echo "Output directory: $OUTPUT_DIR"
echo "=========================================="

exit $EXIT_CODE
