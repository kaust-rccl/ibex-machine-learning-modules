#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --gpus-per-node=v100:2
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=test-distributed
#SBATCH --mail-type=ALL
#SBATCH --output=bin/%x-%j-slurm.out
#SBATCH --error=bin/%x-%j-slurm.err

export CONDA_PKGS_DIRS=/ibex/user/${USER}/conda_cache
source /ibex/user/${USER}/miniconda3/bin/activate

# entire script fails if a single command fails
set -euo pipefail

PROJECT_DIR="$PWD"
ENV_PREFIX="$PROJECT_DIR"/env
conda activate $ENV_PREFIX

# 
echo "Node: $(hostname)"
nvidia-smi
python -c "import torch, os; print('torch', torch.__version__, 'cuda devices', torch.cuda.device_count())"

# helpful distributed-related env vars / debug
export MASTER_ADDR=127.0.0.1
export MASTER_PORT=12355
export NCCL_DEBUG=INFO
export OMP_NUM_THREADS=6

#python "$PROJECT_DIR"/bin/distributed_test_script.py

torchrun --standalone --nproc_per_node=2 "$PROJECT_DIR"/bin/distributed_test_script.py