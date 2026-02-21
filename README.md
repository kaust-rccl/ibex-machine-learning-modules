# Ibex Machine Learning Modules

**Enterprise-grade ML/AI container for HPC clusters**

Singularity container with RAPIDS, PyTorch, TensorFlow, JAX, and 100+ ML libraries optimized for Ibex RockyLinux 9 cluster with SLURM scheduling.

---

## 🚀 Quick Start

### For Users
```bash
# Load the module
module load machine_learning/2026.01/singularity

# Run Python script
singularity exec $ML_CONTAINER_PATH python train.py

# Interactive shell
singularity shell --nv $ML_CONTAINER_PATH

# Jupyter Lab
sbatch bin/launch-jupyter-container-ml-module-26.01.sbatch
```

### For Administrators
```bash
# Build Singularity container
bash bin/setup_install.sh

# This will:
# 1. Clone the repo
# 2. Build ml_module.sif from ml_module.def
# 3. Generate environment module
# 4. Deploy to /sw/rl9g/modulefiles/
```

---

## 📦 What's Inside

### Core Frameworks (Latest Stable)
- **RAPIDS 25.12** (cuDF, cuML, cuGraph) - GPU-accelerated data science
- **PyTorch 2.5.1** (CUDA 13.0) - Deep learning
- **TensorFlow 2.20.0** - Neural networks
- **JAX 0.8.2** (CUDA 13) - High-performance ML

### Distributed Computing
- **Dask** - Parallel computing
- **Ray** - Distributed applications
- **Horovod** - Distributed DL training
- **MPI4Py** - Message passing interface

### ML Libraries
- LightGBM, CatBoost, XGBoost
- Scikit-learn, Prophet, UMAP
- Transformers (HuggingFace)
- Optuna, MLflow

### Development Tools
- JupyterLab + extensions
- Streamlit, Plotly, Dash
- Polars, Zarr, Hydra

**Total: 100+ packages** | See [environment.yml](environment.yml) for complete list

---

## 📚 Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[INDEX.md](INDEX.md)** | Complete documentation index | Everyone |
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | Common commands & examples | Users |
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | Installation & deployment | Admins |
| **[CONTAINER_BUILD.md](CONTAINER_BUILD.md)** | Building containers locally | Developers |
| **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** | Conda → Container migration | Users/Admins |

---

## 🏗️ Architecture

### Deployment Model
```
HPC Cluster (RockyLinux 9 + SLURM)
├── Singularity Container: ml_module_2026.01.sif
│   ├── Base: NVIDIA CUDA-DL-Base (CUDA 13.0, Ubuntu 24.04)
│   ├── Python: 3.12
│   ├── Build: Mambaforge + environment.yml
│   └── Size: ~6-7 GB
│
├── Environment Module: /sw/rl9g/modulefiles/applications/machine_learning/
│   └── Sets: $ML_CONTAINER_PATH, $SINGULARITY_IMAGE
│
└── User Access: module load machine_learning/2026.01/singularity
```

### Key Features
- ✅ **Single shared image** - No per-user installations
- ✅ **GPU-optimized** - CUDA 13.0, cuDNN, NCCL
- ✅ **Reproducible** - Frozen versions in environment.yml
- ✅ **Secure** - Non-root execution, bind mounts
- ✅ **SLURM-integrated** - Native HPC scheduling

---

## 🔬 Testing

### Container Environment Tests
```bash
# Run comprehensive environment test
singularity exec --nv $ML_CONTAINER_PATH python tests/ml_env_test_script.py

# Results: ml_env_test_results.json
```

### Distributed Computing Tests
```bash
# Test Dask, PyTorch, TensorFlow, Ray
singularity exec --nv $ML_CONTAINER_PATH python tests/distributed_test_script.py

# Results: distributed_test_results.json
```

Both tests include:
- Container detection (Docker/Singularity/Host)
- Framework version reporting
- GPU availability checks
- JSON output for CI/CD

---

## 🛠️ Development

### Building Containers Locally

**Docker (for testing on Mac/Linux):**
```bash
# Build with platform flag for M-series Mac
docker build --platform=linux/amd64 -f Dockerfile -t ml-module:latest .

# With security scanning
bash bin/build-and-scan-docker.sh
```

**Singularity (for HPC deployment):**
```bash
# Build on HPC cluster without sudo
# The HPC cluster must have Singularity installed
singularity build ml_module.sif ml_module.def

# Build time: 30-60 minutes
# Output: ml_module.sif (~6-7 GB) If build locally with singularity_build_local_container.slurm
```

### Installation Scripts
- **setup_install.sh** - Initial deployment to HPC
- **rebuild_module.sh** - Rebuild existing module
- **run_install.sh** - Clone repo + build container
- **generate_modulefile.sh** - Create environment module

---

## 📊 Comparison: Conda vs Container

| Metric | Conda (Old) | Container (New) |
|--------|-------------|-----------------|
| **Build Time** | 2-4 hours | 30-60 minutes |
| **Disk per User** | 15-20 GB | 6-7 GB (shared) |
| **Updates** | Manual (each user) | Centralized (one rebuild) |
| **Reproducibility** | Moderate | Excellent |
| **Security** | User-level | Container isolation |
| **GPU Access** | Direct | `--nv` flag |
| **SLURM Integration** | Moderate | Native |

---

## 🔐 Security & Compliance

### Vulnerability Scanning
```bash
# Scan Docker image with Trivy
bash bin/build-and-scan-docker.sh

# Reports generated in scan-reports/
```

### Container Security Features
- Non-root execution by default
- Read-only root filesystem
- Bind mounts for data access only
- GPU isolation via NVIDIA container runtime
- Network isolation (configurable)

---

## 📝 Version History

### 2025.09 (Current)
- Singularity-based deployment model
- RAPIDS 25.12, CUDA 13.0
- Mambaforge build system
- Enhanced testing infrastructure
- Container-aware module files

### 2025.01 (Previous)
- Conda-based deployment
- RAPIDS 25.08
- Manual per-user installation

---

## 🤝 Contributing

### Adding New Packages

1. **Update environment.yml:**
   ```yaml
   dependencies:
     - your-package  # No version pins, mamba resolves latest
   ```

2. **Rebuild container:**
   ```bash
   sudo singularity build ml_module_new.sif ml_module.def
   ```

3. **Test:**
   ```bash
   singularity exec --nv ml_module_new.sif python -c "import your_package"
   ```

4. **Update module:**
   ```bash
   bash bin/generate_modulefile.sh
   ```

### Reporting Issues
- GPU not detected → Check `--nv` flag and NVIDIA drivers
- Import errors → Verify package in environment.yml
- Build failures → See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 📞 Support

- **Documentation:** See [INDEX.md](INDEX.md) for complete guide
- **HPC Issues:** Contact Ibex support team
- **Container Builds:** See [CONTAINER_BUILD.md](CONTAINER_BUILD.md)
- **Migration:** See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

---

## 📄 License

See [LICENSE](LICENSE) file for details.

---

**Repository:** https://github.com/D-Barradas/ibex-machine-learning-modules

**Maintained by:** HPC Team, Ibex Cluster
