#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=test-conda-env
#SBATCH --mail-type=ALL
#SBATCH --output=bin/%x-%j-slurm.out
#SBATCH --error=bin/%x-%j-slurm.err

export CONDA_PKGS_DIRS=/ibex/user/${USER}/conda_cache
source /ibex/user/${USER}/miniconda3/bin/activate

# entire script fails if a single command fails
set -e

# create the conda environment
PROJECT_DIR="$PWD"
ENV_PREFIX="$PROJECT_DIR"/env
conda activate $ENV_PREFIX

python "$PROJECT_DIR"/bin/ml_env_test_script.py