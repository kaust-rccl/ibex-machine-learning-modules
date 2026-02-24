#!/bin/bash

#SBATCH --nodes=1 
#SBATCH --gpus-per-node=1 
#SBATCH --time=01:00:00 
#SBATCH --partition=debug 
#SBATCH --mem=32G
#SBATCH --job-name=build
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

bash bin/build-singularity-container.sh
bash bin/test-container-verification.sh 
