# Ibex Machine Learning Modules

**Enterprise-grade ML/AI environment for HPC clusters**

Choose your deployment:
- **Conda** (native) - Lightweight, direct Python access, ideal for development
- **Singularity** (container) - Reproducible, centralized, production-ready

Both include RAPIDS, PyTorch, TensorFlow, JAX, and 100+ ML libraries optimized for Ibex RockyLinux 9 cluster with SLURM scheduling.

---

## 🚀 Quick Start

### Option 1: Conda (Local/Development)
```bash
# Create environment
bash bin/setup_install_conda_install.sh

# Or via SLURM
sbatch bin/create-conda-env_conda_install.sbatch

# Use environment
conda activate env/
python train.py

# Or with module system
module load machine_learning/2026.01/conda
python train.py
```

### Option 2: Singularity (Container/Production)
```bash
# Load the module
module load machine_learning/2026.01/singularity

# Run Python script
singularity exec --nv $ML_CONTAINER_PATH python train.py

# Interactive shell
singularity shell --nv $ML_CONTAINER_PATH

# Jupyter Lab
sbatch singularity_build/launch-jupyter-container-ml-module-26.01.sbatch
```

### For Administrators
**Conda Setup:**
```bash
bash bin/setup_install_conda_install.sh
bash bin/generate_modulefile_conda_install.sh
```

**Singularity Setup:**
```bash
bash singularity_build/setup_install.sh
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

### Conda Installation Guides (NEW)
| Document | Purpose |
|----------|----------|
| **[CONDA_INDEX.md](core_documentation/CONDA_INDEX.md)** | Navigation hub for all conda docs |
| **[CONDA_QUICK_REFERENCE.md](core_documentation/CONDA_QUICK_REFERENCE.md)** | One-page cheat sheet ⭐ START HERE |
| **[CONDA_INSTALLATION_GUIDE.md](core_documentation/CONDA_INSTALLATION_GUIDE.md)** | Setup guide (direct + SLURM methods) |
| **[CONDA_SLURM_GUIDE.md](core_documentation/CONDA_SLURM_GUIDE.md)** | HPC job scheduling & examples |
| **[CONDA_TESTING_GUIDE.md](core_documentation/CONDA_TESTING_GUIDE.md)** | Environment verification |
| **[CONDA_MODULEFILE_GUIDE.md](core_documentation/CONDA_MODULEFILE_GUIDE.md)** | Module system integration |

### General Documentation
| Document | Purpose | Audience |
|----------|---------|----------|
| **[INDEX.md](INDEX.md)** | Complete documentation index | Everyone |
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | Singularity commands & examples | Users |
| **[DEPLOYMENT_GUIDE.md](core_documentation/DEPLOYMENT_GUIDE.md)** | Singularity deployment | Admins |
| **[CONTAINER_BUILD.md](core_documentation/CONTAINER_BUILD.md)** | Building container locally | Developers |
| **[MIGRATION_GUIDE.md](core_documentation/MIGRATION_GUIDE.md)** | Conda ↔ Container migration | Users/Admins |

---

## 🏗️ Architecture

### Deployment Models

**Conda (Native Environment):**
```
HPC Cluster (RockyLinux 9 + SLURM)
├── Conda Environment: env/ (~10-15 GB)
│   ├── Python: 3.12
│   ├── Build: Mambaforge from environment.yml
│   └── Shared or per-user
│
├── Environment Module (optional): /sw/rl9g/modulefiles/applications/machine_learning/*/conda
│   └── Sets: $ML_ENV_PREFIX, PATH, PYTHONPATH
│
└── User Access:
    - Direct: conda activate env/
    - Module: module load machine_learning/2026.01/conda
```

**Singularity (Container):**
```
HPC Cluster (RockyLinux 9 + SLURM)
├── Singularity Container: ml_module_2026.01.sif (~6-7 GB, shared)
│   ├── Base: NVIDIA CUDA-DL-Base (CUDA 13.0, Ubuntu 24.04)
│   ├── Python: 3.12
│   ├── Build: Mambaforge + environment.yml
│
├── Environment Module: /sw/rl9g/modulefiles/applications/machine_learning/*/singularity
│   └── Sets: $ML_CONTAINER_PATH, $SINGULARITY_IMAGE
│
└── User Access: module load machine_learning/2026.01/singularity
```

### Key Features (Both Options)
- ✅ **GPU-optimized** - CUDA support, cuDNN, NCCL
- ✅ **Reproducible** - Frozen versions in environment.yml
- ✅ **SLURM-integrated** - Native HPC job scheduling
- ✅ **Module system** - Simple `module load` activation
- ✅ **Comprehensive testing** - Verification scripts included
- ✅ **Production quality** - Error handling, logging, monitoring

### Conda-Specific Features
- ✅ **Direct Python access** - No container overhead
- ✅ **Easy customization** - Modify environment.yml and reinstall
- ✅ **Interactive development** - Jupyter, notebooks supported
- ✅ **Lightweight** - No container runtime dependencies

### Singularity-Specific Features
- ✅ **Centralized image** - Single shared binary
- ✅ **Enhanced security** - Container isolation
- ✅ **Portability** - Runs anywhere with Singularity
- ✅ **Environment consistency** - Immutable after build

---

## 🔬 Testing

### Conda Environment Tests
```bash
# Quick verification
bash bin/verify_install_conda_install.sh env/

# Comprehensive testing (local)
python tests/ml_env_test_script.py

# Comprehensive testing (SLURM job)
sbatch bin/test-conda-env_conda_install.sbatch
```

### Singularity Container Tests
```bash
# Run comprehensive environment test
singularity exec --nv $ML_CONTAINER_PATH python tests/ml_env_test_script.py

# Results: ml_env_test_results.json
```

### Both Test Suites Include
- Container/Environment detection
- Framework version reporting (PyTorch, TensorFlow, JAX, etc.)
- GPU availability checks
- Distributed computing validation (Dask, Ray)
- ML library verification (scikit-learn, XGBoost, etc.)
- JSON output for CI/CD integration

---

## 🛠️ Development

### Conda Installation & Customization
**Edit environment.yml, then:**
```bash
# Direct installation
bash bin/setup_install_conda_install.sh

# Or via SLURM
sbatch bin/create-conda-env_conda_install.sbatch

# Generate module file
bash bin/generate_modulefile_conda_install.sh
```

**Conda Installation Scripts** (in `bin/`)
- **setup_install_conda_install.sh** - Orchestrator for conda setup
- **run_install_conda_install.sh** - Core environment creator
- **verify_install_conda_install.sh** - Post-install verification
- **create-conda-env_conda_install.sbatch** - SLURM creation job
- **test-conda-env_conda_install.sbatch** - SLURM test job
- **generate_modulefile_conda_install.sh** - TCL module generator

### Singularity Container Building
**Docker (for testing on Mac/Linux):**
```bash
# Build with platform flag for M-series Mac
docker build --platform=linux/amd64 -f singularity_build/Dockerfile -t ml-module:latest .

# With security scanning
bash singularity_build/build-and-scan-docker.sh
```

**Singularity (for HPC deployment):**
```bash
# Build on HPC cluster
singularity build ml_module.sif singularity_build/ml_module.def

# Build time: 30-60 minutes
# Output: ml_module.sif (~6-7 GB)
```

**Singularity Installation Scripts** (in `singularity_build/`)
- **setup_install.sh** - Initial deployment to HPC
- **run_install.sh** - Clone repo + build container
- **generate_modulefile.sh** - Create environment module
- **rebuild_module.sh** - Rebuild existing module

---

## 📊 Comparison: Conda vs Singularity Container

| Metric | Conda (Native) | Singularity (Container) |
|--------|----------------------|-------------------------|
| **Build Time** | 20-40 minutes | 30-60 minutes |
| **Disk Usage** | 10-15 GB per env | 6-7 GB (shared) |
| **Setup Complexity** | Simple | Moderate |
| **Customization** | Very easy | Easy (rebuild needed) |
| **Reproducibility** | Good | Excellent |
| **Security** | User-level | Container isolation |
| **GPU Access** | Direct CUDA | `--nv` flag required |
| **SLURM Jobs** | Native support | Native support |
| **Dev Experience** | Jupyter friendly | Container overhead |
| **Updates** | Easy (reinstall) | Rebuild container |
| **Portability** | Linux only | Any HPC cluster |
| **Module System** | Supported | Supported |
| **Best For** | Development | Production |

**Recommendation:**
- **Conda**: When you want a lightweight, customizable environment for development and experimentation
- **Singularity**: When you need reproducibility, portability, and centralized management for production workflows

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

### 2026.01 (Current)
- **Dual deployment models**: Conda + Singularity
- RAPIDS 25.12, CUDA 13.0
- Mambaforge build system
- Comprehensive conda documentation (6 guides, 3,000+ lines)
- Enhanced testing infrastructure
- Module file support for both options
- SLURM job templates
- GPU optimization

### 2025.09 (Previous)
- Singularity-based deployment only
- RAPIDS 25.12, CUDA 13.0
- Container-focused workflows

### 2025.01 (Legacy)
- Conda-based deployment (replaced by dual approach)
- Manual per-user installation

---

## 🤝 Contributing

### Adding New Packages

**For Conda:**
1. Update `environment.yml` with new packages
2. Reinstall: `bash bin/setup_install_conda_install.sh`
3. Test: `bash bin/verify_install_conda_install.sh env/`
4. Verify: `python -c "import your_package"`

**For Singularity:**
1. Update `environment.yml` with new packages
2. Rebuild: `sudo singularity build ml_module_new.sif singularity_build/ml_module.def`
3. Test: `singularity exec --nv ml_module_new.sif python -c "import your_package"`
4. Update module: `bash singularity_build/generate_modulefile.sh`

### Reporting Issues

**Conda Issues:**
- Environment creation fails → Check `conda_install.log`
- Import errors → Check `conda list`, reinstall package
- SLURM job timeout → Increase `#SBATCH --time=` directive
- GPU not available → Run `nvidia-smi` and check CUDA packages
- See [CONDA_TESTING_GUIDE.md](core_documentation/CONDA_TESTING_GUIDE.md) for troubleshooting

**Singularity Issues:**
- GPU not detected → Check `--nv` flag and NVIDIA drivers
- Import errors → Verify package in environment.yml
- Build failures → See [DEPLOYMENT_GUIDE.md](core_documentation/DEPLOYMENT_GUIDE.md)
- Rebuild container → Use `singularity_build/setup_install.sh`

---

## 📞 Support

**Getting Started:**
- **New to Conda?** → Start with [CONDA_QUICK_REFERENCE.md](core_documentation/CONDA_QUICK_REFERENCE.md)
- **New to Singularity?** → Start with [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Complete docs** → See [INDEX.md](INDEX.md) and [CONDA_INDEX.md](core_documentation/CONDA_INDEX.md)

**Technical Help:**
- **Conda troubleshooting** → [CONDA_TESTING_GUIDE.md](core_documentation/CONDA_TESTING_GUIDE.md)
- **SLURM jobs** → [CONDA_SLURM_GUIDE.md](core_documentation/CONDA_SLURM_GUIDE.md)
- **Module system** → [CONDA_MODULEFILE_GUIDE.md](core_documentation/CONDA_MODULEFILE_GUIDE.md)
- **Container builds** → [CONTAINER_BUILD.md](core_documentation/CONTAINER_BUILD.md)
- **Migration guide** → [MIGRATION_GUIDE.md](core_documentation/MIGRATION_GUIDE.md)

**Contact:**
- HPC Issues → Contact Ibex support team
- Repository → https://github.com/D-Barradas/ibex-machine-learning-modules

---

## 📄 License

See [LICENSE](LICENSE) file for details.

---

**Repository:** https://github.com/D-Barradas/ibex-machine-learning-modules

**Maintained by:** HPC Team, Ibex Cluster
