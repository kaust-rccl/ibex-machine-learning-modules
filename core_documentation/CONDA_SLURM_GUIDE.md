# Conda SLURM Deployment Guide

**Guide for using conda ML environment via SLURM job scheduler on HPC clusters**

---

## 📋 Overview

SLURM (Simple Linux Utility for Resource Management) is the job scheduler for HPC clusters. Using conda environments with SLURM allows efficient resource allocation and batch processing of ML workloads.

### When to Use SLURM with Conda

**Use SLURM If:**
- ✓ Running on shared HPC cluster
- ✓ Need GPU/compute resources
- ✓ Running long jobs (> 30 minutes)
- ✓ Running multiple jobs
- ✓ Want resource fairness and queue management

**Use Direct Conda If:**
- ✓ Quick testing (< 5 minutes)
- ✓ Interactive work
- ✓ Development/debugging
- ✓ On personal workstation

---

## 🚀 Quick Start: SLURM Jobs

### Step 1: Create Conda Environment via SLURM

```bash
# Navigate to project root
cd /ibex/user/barradd/ibex-machine-learning-modules

# Submit environment creation job
sbatch bin/create-conda-env_conda_install.sbatch

# Expected output:
# Submitted batch job 45234567
```

### Step 2: Monitor Job Progress

```bash
# Check job status
squeue -u ${USER}

# Output:
#  JOBID PARTITION     NAME     USER ST       TIME  NODES CPUS GRES
#  45234567      batch conda-e+   user  R       5:32      1    4 gpu:1

# View live output
tail -f logs/conda-env-create-45234567-slurm.err

# Get job info
scontrol show job 45234567
```

### Step 3: Test When Complete

```bash
# Once job finishes (Status: CA, CD, CF, or NF)
sbatch bin/test-conda-env_conda_install.sbatch

# Check results
cat logs/test-conda-env_conda_install-*.out
```

---

## 🔧 Customizing SLURM Parameters

### Environment Creation Job Configuration

Edit `bin/create-conda-env_conda_install.sbatch`:

```bash
#!/bin/bash
#SBATCH --time=02:00:00          # Walltime (HH:MM:SS)
#SBATCH --gpus-per-node=v100:1   # GPU type and count
#SBATCH --cpus-per-gpu=4         # CPU cores per GPU
#SBATCH --mem=32G                # Total memory
#SBATCH --partition=batch        # Queue name
#SBATCH --job-name=conda-env-create
#SBATCH --mail-type=END,FAIL     # Email notifications
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
```

### Resource Requirement Sizing

**Small Environment (< 5 GB)**
```bash
#SBATCH --time=00:45:00
#SBATCH --gpus-per-node=0        # No GPU needed
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
```

**Medium Environment (5-15 GB)**
```bash
#SBATCH --time=01:30:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
```

**Large Environment (> 15 GB, with RAPIDS)**
```bash
#SBATCH --time=02:30:00
#SBATCH --gpus-per-node=v100:2   # Multiple GPUs
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=64G
#SBATCH --partition=gpu          # May need special queue
```

### GPU Selection

```bash
#SBATCH --gpus-per-node=v100:1   # 1x V100
#SBATCH --gpus-per-node=a100:1   # 1x A100 (better)
#SBATCH --gpus-per-node=1        # Any GPU
#SBATCH --gpus-per-node=2        # 2 GPUs (any type)
```

### Memory & CPU Selection

```bash
#SBATCH --cpus-per-task=8        # 8 CPUs total
#SBATCH --cpus-per-gpu=4         # 4 CPUs per GPU (2 GPUs = 8 CPUs)
#SBATCH --mem=32G                # 32 GB RAM total
#SBATCH --mem-per-cpu=4G         # 4 GB per CPU selected
```

---

## 📝 Writing SLURM Jobs with Conda

### Example 1: Simple Training Script

```bash
#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
#SBATCH --job-name=training
#SBATCH --output=logs/training-%j.out
#SBATCH --error=logs/training-%j.err

# Activate conda environment
conda activate /path/to/env

# Set environment variables
export OMP_NUM_THREADS=4
export CUDA_VISIBLE_DEVICES=0

# Run training script
cd $SLURM_SUBMIT_DIR
python train.py \
    --epochs 100 \
    --batch-size 32 \
    --learning-rate 0.001
```

### Example 2: Jupyter Lab via SLURM

```bash
#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
#SBATCH --job-name=jupyter-lab
#SBATCH --output=logs/jupyter-%j.out
#SBATCH --error=logs/jupyter-%j.err

# Activate environment
conda activate /path/to/env

# Get node name
NODENAME=$(scontrol show hostname $SLURM_NODELIST | head -n1)

# Start Jupyter Lab
jupyter lab \
    --ip=$NODENAME \
    --port=8888 \
    --no-browser \
    --allow-root

# Output shows how to connect via SSH tunnel:
# ssh -N -L 8888:$NODENAME:8888 user@login-node.cluster
```

### Example 3: Distributed Training (Multi-GPU)

```bash
#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --gpus-per-node=2
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=64G
#SBATCH --job-name=distributed-training
#SBATCH --output=logs/distributed-%j.out
#SBATCH --error=logs/distributed-%j.err

# Activate environment
conda activate /path/to/env

# Set distributed training variables
export MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_PORT=29500
export RANK=$SLURM_PROCID
export WORLD_SIZE=$SLURM_NPROCS

# Run distributed script
python -m torch.distributed.launch \
    --nproc_per_node=2 \
    train_distributed.py \
    --epochs 100
```

### Example 4: Batch GPU Processing

```bash
#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
#SBATCH --job-name=batch-inference
#SBATCH --output=logs/inference-%j.out
#SBATCH --error=logs/inference-%j.err
#SBATCH --array=1-10%2              # 10 jobs, max 2 running

# Activate environment
conda activate /path/to/env

# Process file based on array index
INPUT_FILE="data/batch_${SLURM_ARRAY_TASK_ID}.pkl"
OUTPUT_FILE="results/output_${SLURM_ARRAY_TASK_ID}.pkl"

python inference.py \
    --input $INPUT_FILE \
    --output $OUTPUT_FILE \
    --device cuda:0
```

---

## 📊 Job Submission & Monitoring

### Submitting Jobs

```bash
# Submit single job
sbatch script.sbatch
# Output: Submitted batch job 45234567

# Submit job and wait for completion
sbatch --wait script.sbatch

# Submit with environment variables
sbatch --export=EPOCHS=100,BATCH_SIZE=32 train.sbatch

# Submit with dependency (wait for other jobs)
sbatch --dependency=afterok:45234567 test.sbatch
```

### Monitoring Jobs

```bash
# List your jobs
squeue -u ${USER}

# List specific job
squeue -j 45234567

# Full job info
scontrol show job 45234567

# Watch jobs in real-time
watch -n 1 "squeue -u \${USER}"

# Get job status
sacct -j 45234567
```

### Job Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| PD | Pending | Waiting in queue |
| R | Running | Job executing |
| CA | Cancelled | User cancelled |
| CD | Completed | Finished successfully |
| CF | Config fail | Configuration error |
| F | Failed | Job error |
| NF | Node fail | Hardware failure |
| PR | Preempted | Killed by scheduler |

### Output Files

```bash
# Standard output
logs/conda-env-create-45234567-slurm.out

# Error output
logs/conda-env-create-45234567-slurm.err

# Combined output
logs/%x-%j.out  # %x=job name, %j=job ID
```

---

## 🔍 Debugging SLURM Jobs

### Debug Failed Job

```bash
# Check job exit code
sacct -j 45234567 --format=state,exitcode

# View complete error
cat logs/conda-env-create-45234567-slurm.err

# Check system logs
scontrol show job 45234567 | grep Reason

# Check node health
sinfo -N -l | grep nodename
```

### Common SLURM Errors

**Error: Unable to allocate resources**
```bash
# Reason: Requested resources not available
# Solution: Reduce resource request or wait in queue
#SBATCH --gpus-per-node=1  # Reduce from 2
#SBATCH --time=00:30:00    # Reduce time
```

**Error: Job exceeds partition limits**
```bash
# Reason: Requested resources exceed partition max
# Solution: Check partition limits and reduce
sinfo -p batch  # Check batch partition limits
```

**Error: Script not found**
```bash
# Reason: Path not relative to submit directory
# Solution: Use absolute path or $SLURM_SUBMIT_DIR
sbatch /absolute/path/to/script.sbatch
# or
cd /path && sbatch script.sbatch
```

**Error: conda: command not found**
```bash
# Reason: conda not in PATH in job script
# Solution: Source conda initialization
source $HOME/miniconda3/bin/activate
# or use full path
/absolute/path/to/conda activate /path/to/env
```

---

## 🔄 Advanced Workflows

### Job Arrays (Parallel Processing)

```bash
#!/bin/bash
#SBATCH --array=0-99%10              # 100 jobs, max 10 parallel
#SBATCH --time=00:30:00
#SBATCH --gpus-per-node=1
#SBATCH --job-name=array-job

conda activate env/

# Each job gets different task ID
python process.py --task-id $SLURM_ARRAY_TASK_ID

# Control parallelism with %N
#SBATCH --array=1-1000%50  # Run max 50 jobs simultaneously
```

### Job Dependencies

```bash
# Submit job 1
JOB1=$(sbatch setup.sbatch | awk '{print $4}')

# Submit job 2, wait for job 1
JOB2=$(sbatch --dependency=afterok:$JOB1 train.sbatch | awk '{print $4}')

# Submit job 3, wait for job 2
sbatch --dependency=afterok:$JOB2 evaluate.sbatch

# Alternative dependency types:
#SBATCH --dependency=afterok:45234567      # Wait for success
#SBATCH --dependency=afternotok:45234567   # Wait for failure
#SBATCH --dependency=afterany:45234567     # Wait (any status)
#SBATCH --dependency=singleton              # Only one running
```

### Pipeline Workflow

```bash
#!/bin/bash
# pipeline.sh

set -e  # Exit on error

# Stage 1: Create environment
JOB1=$(sbatch --job-name=setup bin/create-conda-env_conda_install.sbatch | awk '{print $4}')
echo "Setup job: $JOB1"

# Stage 2: Test environment
JOB2=$(sbatch --dependency=afterok:$JOB1 \
    --job-name=test bin/test-conda-env_conda_install.sbatch | awk '{print $4}')
echo "Test job: $JOB2"

# Stage 3: Run training
JOB3=$(sbatch --dependency=afterok:$JOB2 \
    --job-name=train train.sbatch | awk '{print $4}')
echo "Training job: $JOB3"

echo "Pipeline submitted: $JOB1 -> $JOB2 -> $JOB3"
```

### Notification & Logging

```bash
#SBATCH --mail-type=BEGIN,END,FAIL        # Email on events
#SBATCH --mail-user=user@example.com

# In script, log important events
echo "$(date): Job start" >> job.log
echo "$(date): Training complete" >> job.log
echo "$(date): Results saved" >> job.log
```

---

## 📋 Best Practices

### 1. Resource Allocation
```bash
# Request what you need, not more
# Overestimate by 20% for safety
#SBATCH --time=01:00:00    # Not 05:00:00 if should take 1 hour
#SBATCH --mem=32G          # Not 128G if using 16G
```

### 2. Job Naming
```bash
#SBATCH --job-name=train-v1.2     # Descriptive name
#SBATCH --output=logs/%x-%j.log   # Use %x and %j
```

### 3. Error Handling
```bash
#!/bin/bash
set -e              # Exit on error
set -u              # Error on undefined var
set -o pipefail     # Pipe failures exit

# Check key steps
if [[ ! -f input.txt ]]; then
    echo "ERROR: input.txt not found"
    exit 1
fi
```

### 4. Conda Environment
```bash
# Always activate explicitly
conda activate /path/to/env

# Or use full path
/path/to/env/bin/python script.py

# Do NOT rely on environment.yml only
```

### 5. Resource Monitoring
```bash
# Check GPU usage
nvidia-smi

# Check CPU/memory
top -b -n 1

# Log resources in job
{
    echo "GPU Info:"
    nvidia-smi
    echo "Memory Info:"
    free -h
    echo "CPU Info:"
    nproc
} >> job.log
```

---

## 🚀 Performance Tips

### When Jobs Are Slow

1. **Check resource bottlenecks:**
   ```bash
   # GPU utilization
   nvidia-smi -l 1  # Update every 1 second
   
   # CPU utilization
   top -p $(pgrep -f "python|pytorch")
   ```

2. **Increase resources:**
   ```bash
   #SBATCH --gpus-per-node=2   # Add GPU
   #SBATCH --cpus-per-gpu=8    # Add CPU
   #SBATCH --mem=64G           # Add RAM
   ```

3. **Profile code:**
   ```bash
   # PyTorch profiling
   python -m torch.profiler
   
   # Memory profiling
   python -m memory_profiler script.py
   ```

### When Queue Wait Is Long

1. **Reduce resource requirements:**
   ```bash
   #SBATCH --gpus-per-node=0   # Remove GPU requirement
   #SBATCH --mem=16G           # Reduce memory
   #SBATCH --time=00:30:00     # Reduce time
   ```

2. **Use preemptible queue (if available):**
   ```bash
   #SBATCH --partition=preempt  # Lower priority, faster
   ```

3. **Submit off-peak hours:**
   ```bash
   # Submit at night for faster execution
   sbatch train.sbatch
   ```

---

## ✅ SLURM Job Checklist

- [ ] Script uses correct conda activation
- [ ] Environment variables set (CUDA_VISIBLE_DEVICES, etc.)
- [ ] Resource requests are reasonable
- [ ] Error handling implemented (set -e)
- [ ] Output paths created (logs/ directory)
- [ ] Logging enabled for debugging
- [ ] Input files exist and are readable
- [ ] Output directory is writable
- [ ] Job time is adequate for task
- [ ] Dependencies specified if needed

---

## 📚 Useful Commands Cheat Sheet

```bash
# Submission
sbatch script.sbatch                          # Submit
sbatch -p gpu script.sbatch                   # Specify partition
sbatch --gpus-per-node=2 script.sbatch        # Override GPU

# Status
squeue -u $USER                               # Your jobs
squeue -j 12345                               # Job 12345
sacct -j 12345                                # Job stats

# Cancellation
scancel 12345                                 # Cancel job
scancel -u $USER                              # Cancel all yours
scancel -p gpu                                # Cancel partition

# Monitoring
scontrol show node                            # Node info
sinfo -N -l                                   # All nodes detailed
sinfo -p batch                                # Partition info

# Debugging
tail logs/job-12345.err                       # View errors
cat logs/job-12345.out                        # View output
scontrol show job 12345                       # Job details
sacct -j 12345 --format=all                   # Complete stats
```

---

## 📞 Support & Troubleshooting

### Common Issues & Solutions

See [CONDA_TROUBLESHOOTING.md](CONDA_TROUBLESHOOTING.md) for detailed solutions.

### Quick Links
- [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) - Setup guide
- [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) - Testing guide
- [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md) - Module files

---

**Last Updated:** February 24, 2026  
**Version:** 2026.01
