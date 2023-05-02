#!/bin/bash
module load cudnn/8.8.1-cuda11.8.0 

export CONDA_PKGS_DIRS=/ibex/user/${USER}/conda_cache
source /ibex/user/${USER}/miniconda3/bin/activate

# entire script fails if a single command fails
set -e

# create the conda environment
PROJECT_DIR="$PWD"
ENV_PREFIX="$PROJECT_DIR"/env
mamba env create --prefix $ENV_PREFIX --file "$PROJECT_DIR"/environment.yml --force
