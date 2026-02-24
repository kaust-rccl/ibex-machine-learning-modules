# Conda Installation - Documentation Index

**Central navigation hub for conda ML environment setup and usage**

---

## 🎯 Start Here

### First Time Users

1. **Read this page** (5 min) - Understand the structure
2. **Read [CONDA_QUICK_REFERENCE.md](CONDA_QUICK_REFERENCE.md)** (5 min) - Get oriented
3. **Follow one of the workflows below** (20-60 min depending on method)

### Returning Users

- **Need quick reminder?** → [CONDA_QUICK_REFERENCE.md](CONDA_QUICK_REFERENCE.md)
- **Have an issue?** → Jump to [Troubleshooting](#troubleshooting)
- **Need specific help?** → Use the [Guide Selector](#guide-selector) below

---

## 📚 Guide Selector

### I want to...

**Install conda environment locally**
→ [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Method 1: Direct Installation

**Install via SLURM job (recommended for HPC)**
→ [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Method 2: SLURM Job

**Write SLURM jobs using conda**
→ [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) → Writing SLURM Jobs section

**Test my environment**
→ [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) → Choose testing level

**Generate module file**
→ [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md) → Quick Start

**Use environment with modules**
→ [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md) → Using Module Files in SLURM Jobs

**Troubleshoot a problem**
→ See [Troubleshooting](#troubleshooting) section below

**Monitor/debug SLURM jobs**
→ [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) → Debugging SLURM Jobs

**Customize my environment.yml**
→ [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Phase 1: Preparation

**Use GPU with conda**
→ [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Verification section

---

## 📖 Full Guide Descriptions

### [CONDA_QUICK_REFERENCE.md](CONDA_QUICK_REFERENCE.md)
**Length:** 5-10 min read | **Type:** Cheat sheet  
**Best for:** Quick lookups, command reference, one-page overview

**Includes:**
- 30-second quick start
- File overview table
- Common workflows
- Command reference
- Troubleshooting lookup table
- Environment variables

**When to use:**
- You've done this before and need a reminder
- Quick command lookup
- First-time orientation

---

### [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md)
**Length:** 20-30 min read | **Type:** Complete guide  
**Best for:** Setting up your conda environment

**Includes:**
- Two installation methods (direct + SLURM)
- Step-by-step instructions
- Resource sizing guidance
- File reference (all scripts explained)
- Advanced usage options
- Troubleshooting guide
- Completion checklist

**When to use:**
- First time setting up
- Installing to custom locations
- Need detailed explanations
- Troubleshooting installation

---

### [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md)
**Length:** 25-35 min read | **Type:** Advanced guide  
**Best for:** Using conda with HPC cluster job scheduler

**Includes:**
- SLURM basics
- Job resource configuration
- 4 example job scripts (simple, Jupyter, distributed, array)
- Job submission & monitoring
- Debugging failures
- Advanced workflows (dependencies, arrays)
- Performance optimization
- Best practices

**When to use:**
- Submitting jobs on HPC cluster
- Want to understand SLURM parameters
- Writing complex job scripts
- Job debugging
- Learning job dependencies

---

### [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md)
**Length:** 20-25 min read | **Type:** Testing & validation  
**Best for:** Verifying environment installation

**Includes:**
- Three testing levels (quick, standard, comprehensive)
- Quick verification script
- Full test suite explanation
- Custom test creation
- GPU testing
- Benchmarking
- Result interpretation
- Failed test troubleshooting

**When to use:**
- After environment creation
- Before running important jobs
- Suspect GPU issues
- Performance validation
- Custom test development

---

### [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md)
**Length:** 20-25 min read | **Type:** HPC module system  
**Best for:** Using module system on clusters

**Includes:**
- Why use module files
- Quick start (3 steps)
- Module file contents & structure
- Customization options
- Using in SLURM jobs (examples)
- Module management
- Version management
- Advanced topics

**When to use:**
- Setting up HPC cluster deployment
- Want `module load` convenience
- Managing multiple environments
- Professional deployments
- Cross-team environment sharing

---

## 🔄 Common Workflows

### Workflow 1: Quick Test (15 minutes)
```
1. Read: CONDA_QUICK_REFERENCE.md (5 min)
2. Run: bash bin/setup_install_conda_install.sh (7 min)
3. Test: bash bin/verify_install_conda_install.sh env/ (3 min)
```
**Best for:** Development, quick experimentation, testing setup

### Workflow 2: Production Setup (45 minutes + queue time)
```
1. Read: CONDA_INSTALLATION_GUIDE.md (15 min)
2. Read: CONDA_SLURM_GUIDE.md → Quick Start (5 min)
3. Customize: environment.yml (5 min)
4. Submit: sbatch bin/create-conda-env_conda_install.sbatch (2 min)
5. Wait for job (5-30 min depending on queue)
6. Verify: sbatch bin/test-conda-env_conda_install.sbatch (5 min)
```
**Best for:** Production environments, cluster usage, best practices

### Workflow 3: Full Setup with Modules (1 hour + queue time)
```
1. Complete Workflow 2 above
2. Read: CONDA_MODULEFILE_GUIDE.md → Quick Start (10 min)
3. Generate: bash bin/generate_modulefile_conda_install.sh (1 min)
4. Test: module load machine_learning/2026.01/conda (1 min)
```
**Best for:** HPC clusters, multi-user environments, team deployments

### Workflow 4: Troubleshooting (30 minutes)
```
1. Check: CONDA_QUICK_REFERENCE.md → Troubleshooting table
2. Read: Relevant section in specific guide
3. Check: conda_install.log or logs/
4. Apply: Solution from guide
5. Test: Rerun verification/test
```
**Best for:** Fixing issues, debugging problems

---

## 📁 File Organization

### Installation Scripts Location: `bin/`

| Script | Purpose | When |
|--------|---------|------|
| `setup_install_conda_install.sh` | Orchestrator | Direct setup |
| `run_install_conda_install.sh` | Core installer | Auto-called |
| `verify_install_conda_install.sh` | Quick check | Post-install |
| `create-conda-env_conda_install.sbatch` | SLURM create | HPC setup |
| `test-conda-env_conda_install.sbatch` | SLURM test | HPC verify |
| `generate_modulefile_conda_install.sh` | Module file | Module system |

### Documentation Location: `core_documentation/`

| File | Purpose | Read Time |
|------|---------|-----------|
| `CONDA_QUICK_REFERENCE.md` | One-page cheat sheet | 5 min |
| `CONDA_INSTALLATION_GUIDE.md` | Complete setup guide | 25 min |
| `CONDA_SLURM_GUIDE.md` | HPC job scheduler | 30 min |
| `CONDA_TESTING_GUIDE.md` | Verification guide | 25 min |
| `CONDA_MODULEFILE_GUIDE.md` | Module system guide | 25 min |

### Container Archive: `singularity_build/`

All singularity/docker-related files archived here. See [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) for container reference.

---

## 🆘 Troubleshooting Decision Tree

**Environment creation failed?**
→ Check: `conda_install.log`
→ Read: [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Troubleshooting

**SLURM job failed?**
→ Check: `logs/conda-env-create-*.err`
→ Read: [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) → Debugging

**Tests fail?**
→ Check: `ml_env_test.log`
→ Read: [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) → Troubleshooting

**Module loading doesn't work?**
→ Check: Module file exists at `${MODULESHOME}/${VERSION}/conda`
→ Read: [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md) → Troubleshooting

**Package import fails?**
→ Check: Package in `conda list`
→ Read: [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) → Issue interpretation

**GPU not available?**
→ Run: `nvidia-smi`
→ Check: CUDA packages in `conda list`
→ Read: [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) → GPU tests

**Job takes too long?**
→ Check: `#SBATCH --time=` in job script
→ Read: [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) → Performance tips

**Out of disk/memory?**
→ Check: `du -sh env/` and `df -h`
→ Read: [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Troubleshooting

---

## 🎓 Learning Path by Role

### Data Scientist (Just Want ML Tools)
1. Read: [CONDA_QUICK_REFERENCE.md](CONDA_QUICK_REFERENCE.md)
2. Run: `bash bin/setup_install_conda_install.sh`
3. Use: `conda activate env/` then `python script.py`

### HPC User (Cluster Jobs)
1. Read: [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Method 2
2. Read: [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) → Job examples
3. Submit: `sbatch my_train_job.sbatch`

### System Administrator (Module System)
1. Read: [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) → Full guide
2. Read: [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md) → Full guide
3. Generate: `bash bin/generate_modulefile_conda_install.sh`
4. Deploy: Copy modulefile to shared location

### DevOps/Infrastructure
1. Read: [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) → Full guide
2. Read: [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) → Full guide
3. Implement: CI/CD with verification scripts

---

## 🔍 Quick Command Reference

### Installation
```bash
# Direct (local)
bash bin/setup_install_conda_install.sh

# Via SLURM
sbatch bin/create-conda-env_conda_install.sbatch
```

### Testing
```bash
# Quick
bash bin/verify_install_conda_install.sh env/

# Full
sbatch bin/test-conda-env_conda_install.sbatch
```

### Usage
```bash
# Direct
conda activate env/
python script.py

# Module (after generation)
module load machine_learning/2026.01/conda
python script.py
```

### Debugging
```bash
# Check installation log
cat conda_install.log

# Check SLURM logs
cat logs/conda-env-create-*.err

# List packages
conda list

# Check GPU
python -c "import torch; print(torch.cuda.is_available())"
```

---

## 📊 Documentation Statistics

| Guide | Lines | Est. Read Time |
|-------|-------|-----------------|
| CONDA_QUICK_REFERENCE.md | 150 | 5-10 min |
| CONDA_INSTALLATION_GUIDE.md | 400 | 25-30 min |
| CONDA_SLURM_GUIDE.md | 350 | 30-35 min |
| CONDA_TESTING_GUIDE.md | 300 | 20-25 min |
| CONDA_MODULEFILE_GUIDE.md | 300 | 20-25 min |
| **Total** | **1,500** | **~2 hours** |

*Read time varies by experience level and specific sections needed*

---

## ✨ Key Features

- ✅ **Multiple Installation Methods** - Direct or SLURM
- ✅ **Comprehensive Testing** - Quick to comprehensive levels
- ✅ **HPC Integration** - SLURM jobs, module system
- ✅ **GPU Support** - PyTorch, TensorFlow, cuDF
- ✅ **Production Ready** - Error handling, logging, best practices
- ✅ **Troubleshooting** - Every guide has troubleshooting section
- ✅ **Examples & Code** - 20+ working examples
- ✅ **Cross-Referenced** - Easy navigation between guides

---

## 🎯 Success Criteria

After following these guides, you should be able to:

✓ Create conda environment locally or via SLURM  
✓ Verify all packages installed correctly  
✓ Run Python scripts with conda environment  
✓ Submit SLURM jobs using conda  
✓ Use module system for environment management  
✓ Troubleshoot common issues  
✓ Monitor GPU availability  
✓ Write custom SLURM job scripts  

---

## 📞 Additional Resources

### Related Files
- Original singularity guide: [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)
- Container guide: [CONTAINER_BUILD.md](../core_documentation/CONTAINER_BUILD.md)
- General reference: [QUICK_REFERENCE.md](../core_documentation/QUICK_REFERENCE.md)

### External Links
- [Conda Documentation](https://docs.conda.io)
- [SLURM Documentation](https://slurm.schedmd.com)
- [PyTorch Installation](https://pytorch.org/get-started)
- [TensorFlow Installation](https://www.tensorflow.org/install)
- [RAPIDS Documentation](https://docs.rapids.ai)

---

## 🗺️ Navigation Summary

```
You are here: CONDA_INDEX.md (Navigation Hub)

Quick Navigation:
  ├─ Getting Started:    CONDA_QUICK_REFERENCE.md
  ├─ Installation:       CONDA_INSTALLATION_GUIDE.md
  ├─ SLURM/HPC:          CONDA_SLURM_GUIDE.md
  ├─ Testing:            CONDA_TESTING_GUIDE.md
  └─ Modules:            CONDA_MODULEFILE_GUIDE.md

By Use Case:
  ├─ Local Testing:      Quick Reference → Installation (Method 1)
  ├─ Cluster Deployment: Installation (Method 2) → SLURM Guide
  ├─ Module System:      Modulefile Guide
  ├─ Verification:       Testing Guide
  └─ Troubleshooting:    Each guide's troubleshooting section
```

---

**Last Updated:** February 24, 2026  
**Version:** 2026.01  
**Status:** ✅ Complete & Ready to Use
