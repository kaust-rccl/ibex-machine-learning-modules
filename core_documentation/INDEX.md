# ML Module Documentation Index

**Complete navigation for the Ibex Machine Learning Modules project**

---

## 🎯 Start Here (By Role)

### 👤 For End Users
**Goal: Run ML/AI workloads on Ibex cluster**

1. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** (5 min) - Common commands and usage patterns
2. **Load module and run:**
   ```bash
   module load machine_learning/2025.09/singularity
   singularity exec $ML_CONTAINER_PATH python your_script.py
   ```

### 🏗️ For Cluster Administrators
**Goal: Deploy and maintain the ML module**

1. **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** (15 min) - Complete installation guide
2. **Run installation:**
   ```bash
   bash bin/setup_install.sh
   ```
3. **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** (10 min) - Conda → Container migration

### 🔬 For Developers/Contributors
**Goal: Build containers, add packages, or modify infrastructure**

1. **[CONTAINER_BUILD.md](CONTAINER_BUILD.md)** (20 min) - Docker and Singularity build process
2. **[environment.yml](environment.yml)** - Package specifications
3. **Test changes:**
   ```bash
   python tests/ml_env_test_script.py
   python tests/distributed_test_script.py
   ```

### 🔒 For Security/Compliance
**Goal: Verify security posture and scan for vulnerabilities**

1. **[DEPLOYMENT_GUIDE.md#security](DEPLOYMENT_GUIDE.md)** - Security features
2. **Run scans:**
   ```bash
   bash bin/build-and-scan-docker.sh
   ```
3. **Review:** scan-reports/ directory

---

## 📚 Complete Documentation Index

### Core Documentation

| Document | Purpose | Read Time | Audience |
|----------|---------|-----------|----------|
| **[README.md](README.md)** | Project overview and quick start | 5 min | Everyone |
| **[INDEX.md](INDEX.md)** | ⭐ This file - documentation navigator | 5 min | Everyone |
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | Command cheat sheet | 5 min | Users |

### Implementation Guides

| Document | Purpose | Read Time | Audience |
|----------|---------|-----------|----------|
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | ⭐ HPC deployment (Singularity) | 20 min | Admins |
| **[CONTAINER_BUILD.md](CONTAINER_BUILD.md)** | Docker/Singularity build process | 20 min | Developers |
| **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** | Conda → Container migration | 15 min | Admins/Users |

### Technical Reference

| Document | Purpose | Read Time | Audience |
|----------|---------|-----------|----------|
| **[REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md)** | Package inventory (100+ packages) | 15 min | Developers |
| **[SINGULARITY_DEPLOYMENT.md](SINGULARITY_DEPLOYMENT.md)** | Singularity-specific details | 20 min | Admins |

---

## 🐳 Container Specifications

### Production Container (Singularity)
**File:** [ml_module.def](ml_module.def)  
**Base:** nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04  
**Build Time:** 30-60 minutes  
**Size:** ~6-7 GB  
**Status:** ✅ Production Ready

**What's inside:**
- RAPIDS 25.12 (cuDF, cuML, cuGraph)
- PyTorch 2.5.1 (CUDA 13.0)
- TensorFlow 2.20.0
- JAX 0.8.2 (CUDA 13)
- Dask, Ray, Horovod
- 100+ ML/AI packages

**Build command:**
```bash
sudo singularity build ml_module.sif ml_module.def
```

### Development Container (Docker)
**File:** [Dockerfile](Dockerfile)  
**Purpose:** Local testing on Mac/Linux  
**Platform:** linux/amd64 (x86_64)  
**Build Time:** 15-20 minutes  
**Size:** ~6-7 GB  

**Build command:**
```bash
docker build --platform=linux/amd64 -f Dockerfile -t ml-module:latest .
```

---

## 🛠️ Scripts & Tools

### Build Scripts
- **[bin/build-and-scan-docker.sh](bin/build-and-scan-docker.sh)** - Build Docker + Trivy scan
- **[bin/setup_install.sh](bin/setup_install.sh)** - Initial HPC deployment
- **[bin/rebuild_module.sh](bin/rebuild_module.sh)** - Rebuild existing module
- **[bin/run_install.sh](bin/run_install.sh)** - Clone + build container
- **[bin/generate_modulefile.sh](bin/generate_modulefile.sh)** - Create environment module

### Test Scripts
- **[tests/ml_env_test_script.py](tests/ml_env_test_script.py)** - Comprehensive environment test
- **[tests/distributed_test_script.py](tests/distributed_test_script.py)** - Distributed computing test
- **[tests/test_one.py](tests/test_one.py)**, **[tests/test_two.py](tests/test_two.py)**, **[tests/test_three.py](tests/test_three.py)** - Unit tests

### SLURM Job Templates
- **[bin/launch-jupyter-server.sbatch](bin/launch-jupyter-server.sbatch)** - Jupyter Lab
- **[bin/example-training-job.sbatch](bin/example-training-job.sbatch)** - Single-GPU training
- **[bin/example-distributed-job.sbatch](bin/example-distributed-job.sbatch)** - Multi-GPU training

---

## 📊 Key Files

### Configuration Files
- **[environment.yml](environment.yml)** - ⭐ Master package specification (no version pins)
- **[ml_module.def](ml_module.def)** - ⭐ Singularity definition
- **[Dockerfile](Dockerfile)** - Docker definition (renamed from Dockerfile.option4)

### Deprecated Files (Keep for Reference)
- **environment_dev.yml** - Old development environment
- **exported-environment.yml** - Old frozen environment
- **requirements.txt** - Old pip requirements (replaced by environment.yml)

---

## 🎓 Learning Paths

### Path 1: "I want to use the ML module"
1. Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (5 min)
2. Load module: `module load machine_learning/2025.09/singularity`
3. Run example: `singularity exec $ML_CONTAINER_PATH python -c "import torch; print(torch.cuda.is_available())"`
4. Copy SLURM template from [bin/example-training-job.sbatch](bin/example-training-job.sbatch)

### Path 2: "I need to deploy this on our HPC cluster"
1. Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) (20 min)
2. Review [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) if migrating from Conda (15 min)
3. Run `bash bin/setup_install.sh`
4. Test with `singularity exec $ML_CONTAINER_PATH python tests/ml_env_test_script.py`
5. Generate module with `bash bin/generate_modulefile.sh`

### Path 3: "I want to add new packages or modify the container"
1. Read [CONTAINER_BUILD.md](CONTAINER_BUILD.md) (20 min)
2. Review [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md) (15 min)
3. Update [environment.yml](environment.yml)
4. Build locally: `docker build --platform=linux/amd64 -f Dockerfile -t ml-module:test .`
5. Test: `docker run --rm ml-module:test python -c "import your_package"`
6. Build Singularity: `sudo singularity build ml_module_new.sif ml_module.def`

### Path 4: "I'm migrating from Conda to containers"
1. Read [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) (15 min)
2. Review [README.md#comparison](README.md) for feature comparison
3. Test container with your existing scripts
4. Update job scripts (replace `conda activate` with `singularity exec`)
5. Validate with [tests/ml_env_test_script.py](tests/ml_env_test_script.py)

---

## 🔍 Common Tasks

### Add a New Package
1. Edit [environment.yml](environment.yml):
   ```yaml
   dependencies:
     - new-package  # No version pin, mamba resolves latest
   ```
2. Rebuild container: `sudo singularity build ml_module_new.sif ml_module.def`
3. Test import: `singularity exec ml_module_new.sif python -c "import new_package"`

### Update Framework Versions
Versions are managed automatically by mamba. To force specific versions:
1. Edit [environment.yml](environment.yml):
   ```yaml
   dependencies:
     - pytorch=2.6.0  # Pin specific version
   ```
2. Rebuild and test

### Run Security Scan
```bash
bash bin/build-and-scan-docker.sh
# Review: scan-reports/trivy-report.json
```

### Deploy New Version
```bash
export VERSION="2025.10"
bash bin/setup_install.sh
```

### Troubleshoot Build Failures
1. Check [CONTAINER_BUILD.md#troubleshooting](CONTAINER_BUILD.md)
2. Review build logs in install.log
3. Test base image: `singularity exec docker://nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04 python --version`

---

## 📞 Getting Help

### Documentation Not Helping?
1. **Check logs:** install.log, build logs, SLURM output
2. **Test components:**
   ```bash
   singularity exec $ML_CONTAINER_PATH python tests/ml_env_test_script.py
   ```
3. **Verify GPU:** `singularity exec --nv $ML_CONTAINER_PATH nvidia-smi`

### Common Issues
- **"Module not found"** → Module not loaded or package not in environment.yml
- **"CUDA not available"** → Missing `--nv` flag or GPU drivers
- **"Build failed"** → Check disk space, network, base image availability
- **"Permission denied"** → Singularity build requires sudo

### Support Channels
- **HPC Issues:** Ibex support team
- **Container Issues:** See [CONTAINER_BUILD.md](CONTAINER_BUILD.md)
- **Package Issues:** See [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md)

---

## 🗺️ Documentation Map

```
├─ README.md .......................... Project overview & quick start
├─ INDEX.md ........................... This file - complete navigation
│
├─ QUICK_REFERENCE.md ................. Commands & usage patterns
├─ DEPLOYMENT_GUIDE.md ................ HPC deployment guide
├─ CONTAINER_BUILD.md ................. Docker/Singularity build
├─ MIGRATION_GUIDE.md ................. Conda → Container guide
│
├─ REQUIREMENTS_BREAKDOWN.md .......... Package inventory
├─ SINGULARITY_DEPLOYMENT.md .......... Singularity details
│
├─ environment.yml .................... Master package spec
├─ ml_module.def ...................... Singularity definition
├─ Dockerfile ......................... Docker definition
│
└─ bin/
   ├─ setup_install.sh ................ Deploy to HPC
   ├─ rebuild_module.sh ............... Rebuild module
   ├─ run_install.sh .................. Build container
   ├─ generate_modulefile.sh .......... Create module
   ├─ build-and-scan-docker.sh ........ Docker build + scan
   └─ *.sbatch ........................ SLURM job templates
```

---

**Last Updated:** January 2026  
**Version:** 2025.09  
**Container:** ml_module_2025.09.sif
