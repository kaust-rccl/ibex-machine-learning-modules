#!/bin/bash
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=6  
#SBATCH --mem=64G
#SBATCH --partition=debug 
#SBATCH --job-name=launch-jupyter-server
#SBATCH --mail-type=ALL
#SBATCH --output=bin/%x-%j-slurm.out
#SBATCH --error=bin/%x-%j-slurm.err

# setup the environment
module purge
module load machine_learning

# setup ssh tunneling 
export XDG_RUNTIME_DIR=/tmp IBEX_NODE=$(hostname -s)  
JUPYTER_PORT=$SLURM_STEP_RESV_PORTS

echo "
To connect to the compute node ${IBEX_NODE} on Ibex running your Jupyter server, 
you need to create an ssh tunnel from your local machine to login node on Ibex 
using the following command.

ssh -L ${JUPYTER_PORT}:${IBEX_NODE}:${JUPYTER_PORT} ${USER}@glogin.ibex.kaust.edu.sa 

Next, you need to copy the second url provided below and paste it into the browser 
on your local machine.
" >&2

# launch jupyter server
jupyter ${1:-lab} --no-browser --port=${JUPYTER_PORT} --ip=${IBEX_NODE}