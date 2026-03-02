# Singularity/Apptainer ML Module Deployment Guide

## Overview

This guide covers the deployment of the ML Module container to the Ibex HPC cluster running RockyLinux 9 with SLURM.

## Architecture

- **Base Image**: NVIDIA RAPIDS 25.12 (CUDA 13.1, Python 3.13)
- **Container Type**: Singularity/Apptainer SIF
- **Target OS**: RockyLinux 9
- **Scheduler**: SLURM
- **Security**: Non-root execution, bind mounts, GPU isolation

## Prerequisites

### On Build System
```bash
# Install Apptainer (recommended) or Singularity
# For RockyLinux 9:
sudo dnf install -y epel-release
sudo dnf install -y apptainer

# Or download latest version:
# https://github.com/apptainer/apptainer/releases
```

### On HPC Cluster
- Apptainer/Singularity installed and available
- NVIDIA GPU drivers (compatible with CUDA 13.1)
- SLURM configured with GPU support

## Building the Container

### Option 1: Build on Local System (Recommended)
```bash
cd /Users/barradd/Documents/GitHub/ibex-machine-learning-modules

# Build with sudo (required for full functionality)
sudo ./bin/build-singularity-container.sh

# Expected build time: 30-60 minutes
# Expected image size: 5-8 GB
```

### Option 2: Build on HPC Cluster
```bash
# Create build job
cat > build-container.sbatch <<'EOF'
#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --partition=batch
#SBATCH --job-name=build-ml-container

cd $SLURM_SUBMIT_DIR
apptainer build --fakeroot ml_module_v1.0.sif ml_module.def
EOF

# Submit build job
sbatch build-container.sbatch
```

### Option 3: Pull Pre-built Image (Future)
```bash
# Once pushed to a registry
apptainer pull ml_module.sif library://kaust/ml/module:latest
```

## Testing the Container

### Quick Test
```bash
# Test GPU access
singularity exec --nv ml_module_v1.0.sif nvidia-smi

# Test Python frameworks
singularity exec --nv ml_module_v1.0.sif python -c \
  "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### Comprehensive Test (SLURM)
```bash
# Submit test job
sbatch ./bin/test-singularity-container.sbatch

# Monitor job
squeue -u $USER
tail -f bin/test-ml-container-*-slurm.out
```

## Deployment to Production

### 1. Deploy to Shared Location
```bash
# Create module directory
SHARED_DIR="/ibex/shared/modules/machine-learning/1.0"
mkdir -p $SHARED_DIR

# Copy container and documentation
cp ml_module_v1.0.sif $SHARED_DIR/ml_module.sif
cp SINGULARITY_DEPLOYMENT.md $SHARED_DIR/
chmod 755 $SHARED_DIR/ml_module.sif
```

### 2. Create Environment Module (Optional)
```bash
# Create modulefile
cat > /ibex/shared/modules/modulefiles/ml-module/1.0 <<'EOF'
#%Module1.0
proc ModulesHelp { } {
    puts stderr "ML Module v1.0 - All-in-one Machine Learning Environment"
}

module-whatis "ML Module with RAPIDS, PyTorch, TensorFlow, JAX"

set basedir /ibex/shared/modules/machine-learning/1.0

setenv ML_MODULE_IMAGE $basedir/ml_module.sif
setenv ML_MODULE_VERSION 1.0

prepend-path PATH $basedir/bin
EOF

# Load the module
module load ml-module/1.0
```

### 3. Create User-Friendly Wrapper Scripts
```bash
# Create bin directory
mkdir -p /ibex/shared/modules/machine-learning/1.0/bin

# Python wrapper
cat > /ibex/shared/modules/machine-learning/1.0/bin/ml-python <<'EOF'
#!/bin/bash
CONTAINER=$ML_MODULE_IMAGE
singularity exec --nv \
  --bind /ibex/user/$USER:/work \
  --bind $PWD:/workspace \
  $CONTAINER python "$@"
EOF

# Jupyter wrapper
cat > /ibex/shared/modules/machine-learning/1.0/bin/ml-jupyter <<'EOF'
#!/bin/bash
CONTAINER=$ML_MODULE_IMAGE
PORT=${1:-8888}
singularity exec --nv \
  --bind /ibex/user/$USER:/work \
  --bind $PWD:/workspace \
  $CONTAINER jupyter lab --ip=0.0.0.0 --port=$PORT --no-browser
EOF

chmod +x /ibex/shared/modules/machine-learning/1.0/bin/*
```

## Usage Examples

### Interactive Shell
```bash
singularity shell --nv ml_module.sif
```

### Run Python Script
```bash
singularity exec --nv \
  --bind /ibex/user/$USER:/work \
  ml_module.sif python train_model.py
```

### Jupyter Lab Session
```bash
# Start Jupyter Lab
singularity exec --nv \
  --bind /ibex/user/$USER:/work \
  ml_module.sif jupyter lab --ip=0.0.0.0 --port=8888

# Access via SSH tunnel:
# ssh -L 8888:compute-node:8888 user@ibex-gateway
# Then open http://localhost:8888
```

### SLURM Batch Job
```bash
#!/bin/bash
#SBATCH --gpus-per-node=v100:2
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=64G
#SBATCH --time=24:00:00

PROJECT_DIR=$PWD
CONTAINER=/ibex/shared/modules/machine-learning/1.0/ml_module.sif

singularity exec --nv \
  --bind $PROJECT_DIR:/work \
  --bind $SLURM_TMPDIR:/tmp \
  $CONTAINER python /work/train_distributed.py \
    --epochs 100 \
    --batch-size 256
```

### Multi-Node Distributed Training
```bash
#!/bin/bash
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=v100:4
#SBATCH --cpus-per-gpu=6

CONTAINER=/ibex/shared/modules/machine-learning/1.0/ml_module.sif

srun singularity exec --nv \
  --bind $PWD:/work \
  $CONTAINER python -m torch.distributed.launch \
    --nproc_per_node=4 \
    --nnodes=$SLURM_NNODES \
    --node_rank=$SLURM_NODEID \
    --master_addr=$(scontrol show hostname $SLURM_NODELIST | head -n1) \
    --master_port=29500 \
    /work/train_ddp.py
```

## Security Considerations

### 1. Container Security
- ✅ Runs as non-root user (inherited from host)
- ✅ No setuid/setgid binaries
- ✅ Minimal attack surface (only runtime dependencies)
- ✅ Reproducible builds (pinned versions)

### 2. SLURM Integration
```bash
# GPU isolation (automatic with --nv flag)
singularity exec --nv ...

# Resource limits (via SLURM)
#SBATCH --mem=32G
#SBATCH --cpus-per-gpu=6
#SBATCH --time=24:00:00

# Network isolation (if needed)
singularity exec --net --network=none ...
```

### 3. Data Security
```bash
# Read-only bind mounts for shared data
--bind /ibex/shared/data:/data:ro

# Private scratch space
--bind $SLURM_TMPDIR:/tmp

# User workspace (read-write)
--bind /ibex/user/$USER:/work
```

### 4. Secrets Management
```bash
# Use environment variables (not embedded in container)
export WANDB_API_KEY="your-key"
singularity exec --nv ml_module.sif python train.py

# Or use secrets file
--bind $HOME/.secrets:/secrets:ro
```

## Performance Optimization

### 1. Overlay Filesystem (for faster I/O)
```bash
# Create overlay
dd if=/dev/zero of=overlay.img bs=1M count=1024
mkfs.ext3 overlay.img

# Use overlay
singularity exec --nv --overlay overlay.img ml_module.sif python script.py
```

### 2. GPU Affinity
```bash
# For multi-GPU nodes
export CUDA_VISIBLE_DEVICES=0,1,2,3
singularity exec --nv ml_module.sif python train.py
```

### 3. Memory Optimization
```bash
# For large models
ulimit -s unlimited
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

## Monitoring and Debugging

### Container Inspection
```bash
# Show container metadata
singularity inspect ml_module.sif

# Check installed packages
singularity exec ml_module.sif conda list

# Verify GPU access
singularity exec --nv ml_module.sif nvidia-smi

# Check environment variables
singularity exec ml_module.sif env
```

### Job Monitoring
```bash
# Monitor GPU usage during job
ssh compute-node-123
watch -n 1 nvidia-smi

# Check container processes
ps aux | grep singularity
```

### Troubleshooting

#### Issue: "CUDA driver version insufficient"
```bash
# Check host driver version
nvidia-smi

# Container requires CUDA 13.1 driver (>= 530.30.02)
# Update host drivers or use older container version
```

#### Issue: "Permission denied" on bind mounts
```bash
# Ensure directories exist and are accessible
ls -ld /ibex/user/$USER
mkdir -p /ibex/user/$USER/workspace

# Use absolute paths
--bind /ibex/user/$USER:/work
```

#### Issue: Out of memory
```bash
# Monitor memory usage
#SBATCH --mem=64G  # Increase allocation

# Enable GPU memory pooling
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
```

## Maintenance

### Updating the Container
```bash
# Rebuild with new packages
sudo ./bin/build-singularity-container.sh

# Version containers
cp ml_module_v1.0.sif ml_module_v1.1.sif

# Update symlink for production
ln -sf ml_module_v1.1.sif /ibex/shared/modules/machine-learning/latest.sif
```

### Image Registry (Future)
```bash
# Push to registry
apptainer push ml_module.sif library://kaust/ml/module:1.0

# Sign image
apptainer sign ml_module.sif
```

## Support and Contact

For issues or questions:
- **Email**: david.barradas@kaust.edu.sa
- **Documentation**: /ibex/shared/modules/machine-learning/1.0/
- **Test Scripts**: Run `sbatch bin/test-singularity-container.sbatch`

## References

- [Apptainer Documentation](https://apptainer.org/docs/)
- [NVIDIA NGC Containers](https://catalog.ngc.nvidia.com/)
- [RAPIDS Documentation](https://docs.rapids.ai/)
- [SLURM GPU Guide](https://slurm.schedmd.com/gres.html)
