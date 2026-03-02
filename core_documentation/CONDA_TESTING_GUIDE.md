# Conda Environment Testing Guide

**Comprehensive guide for validating conda ML environment installation**

---

## 📋 Overview

After conda environment creation, thorough testing ensures all packages are installed correctly and functional, especially for GPU-intensive workflows.

### Testing Levels

| Level | Scope | Time | Method |
|-------|-------|------|--------|
| **Quick** | Core packages only | 2-5 min | `verify_install_conda_install.sh` |
| **Standard** | All ML frameworks | 10-20 min | `ml_env_test_script.py` |
| **Comprehensive** | GPU, distributed, edge cases | 30-60 min | Full test suite |

---

## 🚀 Quick Verification (2-5 minutes)

### Method 1: Verification Script

```bash
# Activate environment first
conda activate env/

# Run quick verification
bash bin/verify_install_conda_install.sh env/
```

**Output Example:**
```
==================================================
Conda ML Environment Verification
==================================================

Environment: env/

Python & Core:
  Python 3.12.1
  ✓ NumPy
  ✓ Pandas
  ✓ SciPy
  ✓ Scikit-Learn

Deep Learning Frameworks:
  ✓ PyTorch
  ✓ TensorFlow
  ✓ JAX

ML Libraries:
  ✓ XGBoost
  ✓ LightGBM
  ✓ CatBoost

Distributed Computing:
  ✓ Dask
  ✓ Ray

==================================================
Summary:
  Passed: 15
  Failed: 0
==================================================
✓ All critical packages verified!
```

### Method 2: Manual Python Checks

```bash
# Activate environment
conda activate env/

# Check Python version
python --version

# Import critical packages
python -c "
import numpy as np
import pandas as pd
import torch
import tensorflow as tf
print('✓ All basic imports successful')
print(f'NumPy: {np.__version__}')
print(f'Pandas: {pd.__version__}')
print(f'PyTorch: {torch.__version__}')
print(f'TensorFlow: {tf.__version__}')
"
```

### Method 3: One-liner Tests

```bash
# Test each framework individually
python -c "import torch; print(f'PyTorch {torch.__version__}')"
python -c "import tensorflow as tf; print(f'TensorFlow {tf.__version__}')"
python -c "import jax; print(f'JAX {jax.__version__}')"
python -c "import cudf; print(f'cuDF {cudf.__version__}')"  # GPU optional

# Test GPU availability
python -c "
import torch
print(f'PyTorch CUDA available: {torch.cuda.is_available()}')
print(f'PyTorch CUDA device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"
```

---

## 📊 Standard Testing (10-20 minutes)

### Full Test Suite via Python

```bash
# Ensure environment is active
conda activate env/

# Run comprehensive test script
cd /ibex/user/barradd/ibex-machine-learning-modules
python tests/ml_env_test_script.py

# Or if in different location
python /path/to/ml_env_test_script.py
```

### Test Script Output

```
============================================================
Machine Learning Environment Test
============================================================
Running in: Host/Docker/Singularity
Hostname: compute-node-42

--- Environment Info ---
Python: 3.12.1 (main, Jan 29 2025)
PyTorch: 2.5.1
TensorFlow: 2.20.0
JAX: 0.8.2
cuDF: 25.12.0
cugraph: 25.12.0
[rest of output...]

--- PyTorch Tests ---
✅ PyTorch Basic Test passed.
✅ PyTorch Tensor Operations passed.
✅ PyTorch CUDA Test passed.
[more tests...]

--- TensorFlow Tests ---
✅ TensorFlow Basic Test passed.
✅ TensorFlow GPU Test passed.
[more tests...]
```

### Test Coverage

The comprehensive test suite validates:

**Python & Core Libraries:**
- ✓ Python version (3.12)
- ✓ NumPy arrays and operations
- ✓ Pandas DataFrames
- ✓ SciPy functions
- ✓ Scikit-learn ML algorithms

**Deep Learning Frameworks:**
- ✓ PyTorch tensor creation
- ✓ PyTorch GPU memory allocation
- ✓ PyTorch CUDA availability
- ✓ TensorFlow model creation
- ✓ TensorFlow GPU support
- ✓ JAX JIT compilation
- ✓ JAX CUDA operations

**ML Libraries:**
- ✓ LightGBM model training
- ✓ XGBoost features
- ✓ CatBoost gradient boosting
- ✓ Scikit-learn preprocessing

**Distributed Computing:**
- ✓ Dask arrays and dataframes
- ✓ Ray initialization and tasks
- ✓ Ray distributed training

**GPU Support (if installed):**
- ✓ cuDF GPU dataframes
- ✓ cuGraph GPU graph operations
- ✓ UMAP GPU acceleration

**Data Visualization:**
- ✓ Matplotlib rendering
- ✓ Seaborn plot generation

---

## ☁️ SLURM Job Testing (Compute Nodes)

### Submit Test Job

```bash
# Navigate to project root
cd /ibex/user/barradd/ibex-machine-learning-modules

# Submit test job
sbatch bin/test-conda-env_conda_install.sbatch

# Track job progress
squeue -u ${USER} | grep test-conda

# Wait for completion (status R) then check output
tail -f logs/test-conda-env_conda_install-${JOB_ID}-slurm.err
```

### Test Job Configuration

Customize in `bin/test-conda-env_conda_install.sbatch`:

```bash
#SBATCH --time=00:30:00          # Test duration
#SBATCH --gpus-per-node=v100:1   # GPU type/count
#SBATCH --cpus-per-gpu=4         # CPUs per GPU
#SBATCH --mem=32G                # Memory
#SBATCH --partition=batch        # Queue (change as needed)
```

### Monitor Job Status

```bash
# Check if job is running
squeue -j ${JOB_ID}

# Check job details
scontrol show job ${JOB_ID}

# View job output in real-time
tail -f logs/test-conda-env_conda_install-${JOB_ID}-slurm.out

# View errors
tail -f logs/test-conda-env_conda_install-${JOB_ID}-slurm.err
```

### Test Job Output Location

```
logs/test-conda-env_conda_install-${JOB_ID}-slurm.out  # Standard output
logs/test-conda-env_conda_install-${JOB_ID}-slurm.err  # Error messages
ml_env_test.log                                        # Detailed test log
ml_env_test.json                                       # Test results JSON
```

---

## 🔬 Custom Testing

### Create Your Own Test Script

```python
# my_tests.py
import sys
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_pytorch():
    """Test PyTorch functionality"""
    import torch
    logger.info(f"PyTorch version: {torch.__version__}")
    
    # Test tensor operations
    x = torch.randn(3, 4)
    y = torch.randn(4, 5)
    z = torch.matmul(x, y)
    
    # Test GPU if available
    if torch.cuda.is_available():
        x_gpu = x.to('cuda')
        result_gpu = torch.matmul(x_gpu, y.to('cuda'))
        logger.info(f"GPU tensor shape: {result_gpu.shape}")
    
    logger.info("✓ PyTorch test passed")
    return True

def test_tensorflow():
    """Test TensorFlow functionality"""
    import tensorflow as tf
    logger.info(f"TensorFlow version: {tf.__version__}")
    
    # Create a simple model
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(128, activation='relu', input_shape=(10,)),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dense(1)
    ])
    
    # Compile
    model.compile(optimizer='adam', loss='mse')
    logger.info("✓ TensorFlow model compiled successfully")
    return True

def test_gpu_availability():
    """Check GPU availability"""
    import torch
    cuda_available = torch.cuda.is_available()
    logger.info(f"CUDA available: {cuda_available}")
    if cuda_available:
        logger.info(f"GPU count: {torch.cuda.device_count()}")
        logger.info(f"GPU name: {torch.cuda.get_device_name(0)}")
    return cuda_available

if __name__ == "__main__":
    tests = [
        ("PyTorch", test_pytorch),
        ("TensorFlow", test_tensorflow),
        ("GPU Availability", test_gpu_availability),
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            test_func()
            passed += 1
        except Exception as e:
            logger.error(f"✗ {test_name} failed: {str(e)}")
            failed += 1
    
    logger.info(f"\nResults: {passed} passed, {failed} failed")
    sys.exit(0 if failed == 0 else 1)
```

### Run Custom Tests

```bash
# Activate environment
conda activate env/

# Run your test script
python my_tests.py

# Or via SLURM
sbatch << 'EOF'
#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --gpus-per-node=1

conda activate env/
python my_tests.py
EOF
```

---

## 🚨 Interpretation of Test Results

### All Tests Pass ✓
```
Passed: 25
Failed: 0
✓ All critical packages verified!
```
**Action:** Environment is ready for production use

### Some Tests Fail ✗
```
Passed: 23
Failed: 2
⚠ Some packages failed verification.
```
**Action:** Investigate which packages failed and reinstall:
```bash
# Check which packages failed
grep "failed" ml_env_test.log

# Reinstall specific package
conda install -n env pytorch::pytorch -c pytorch

# Rerun tests
python tests/ml_env_test_script.py
```

### GPU Tests Fail
```
PyTorch CUDA available: False
cuDF GPU operations: Failed
```
**Action:** Check GPU configuration:
```bash
# Verify GPU hardware
nvidia-smi

# Check CUDA in environment
conda list | grep cudatoolkit

# Check environment.yml for GPU packages
grep cuda environment.yml

# Reinstall GPU packages
conda install -n env pytorch::pytorch pytorch::pytorch-cuda cudatoolkit -c pytorch
```

### Import Errors
```
ImportError: No module named 'torch'
```
**Action:** Verify environment activation:
```bash
# Check if environment is active
echo $CONDA_DEFAULT_ENV

# Reactivate if needed
conda activate env/

# Verify Python interpreter
which python

# List installed packages
conda list
```

---

## 📈 Benchmarking Tests

### Performance Baseline

```python
# benchmark.py
import time
import numpy as np
import torch
import tensorflow as tf

def benchmark_pytorch(iterations=100):
    """Benchmark PyTorch tensor operations"""
    x = torch.randn(1000, 1000)
    y = torch.randn(1000, 1000)
    
    start = time.time()
    for _ in range(iterations):
        _ = torch.matmul(x, y)
    elapsed = time.time() - start
    
    print(f"PyTorch matmul: {elapsed/iterations*1000:.2f}ms per iteration")
    return elapsed

def benchmark_deep_learning():
    """Benchmark model training"""
    # PyTorch
    model = torch.nn.Sequential(
        torch.nn.Linear(100, 128),
        torch.nn.ReLU(),
        torch.nn.Linear(128, 10)
    )
    
    # Train for 1 epoch
    start = time.time()
    for _ in range(100):
        x = torch.randn(32, 100)
        y = model(x)
    elapsed = time.time() - start
    
    print(f"PyTorch model training: {elapsed:.2f}s for 100 batches")

if __name__ == "__main__":
    print("Running benchmarks...")
    benchmark_pytorch()
    benchmark_deep_learning()
```

---

## ✅ Test Checklist

**Before Deployment:**
- [ ] Quick verification passes: `bash bin/verify_install_conda_install.sh env/`
- [ ] Python imports work: `python -c "import torch; import tensorflow"`
- [ ] Full test suite passes: `python tests/ml_env_test_script.py`
- [ ] SLURM job test passes: `sbatch bin/test-conda-env_conda_install.sbatch`
- [ ] GPU is accessible: `python -c "import torch; print(torch.cuda.is_available())"`
- [ ] Custom models run: Your own test scripts execute successfully
- [ ] Performance meets expectations: Benchmark results acceptable
- [ ] Documentation reviewed: Users understand limitations

---

## 🔧 Troubleshooting Failed Tests

### Issue: "Module not found" errors
```bash
# Check which packages are missing
python -c "import missing_package"

# Reinstall the package
conda install -n env missing_package

# Verify reinstall
conda list | grep missing_package
```

### Issue: CUDA/GPU not found
```bash
# Check GPU hardware
nvidia-smi

# Verify CUDA install
python -c "import torch; print(torch.cuda.is_available())"

# Check NVIDIA container toolkit (if using containers)
nvidia-smi

# Rebuild environment with correct CUDA
conda install -n env pytorch::pytorch pytorch::pytorch-cuda -c pytorch
```

### Issue: Out of memory during tests
```bash
# Reduce test batch sizes
# Edit ml_env_test_script.py and change:
BATCH_SIZE = 16  # Reduce from default

# Or skip GPU tests
export SKIP_GPU_TESTS=1
python tests/ml_env_test_script.py
```

### Issue: Timeout during tests
```bash
# Increase SLURM job time
#SBATCH --time=01:00:00  # Increase from default

# Or test locally at night when cluster is less busy
bash bin/test-conda-env_conda_install.sh (without SLURM)
```

---

## 📊 Interpreting Test Logs

### Log File Location
```
ml_env_test.log              # Main test output
ml_env_test.json             # JSON results (if available)
conda_install.log            # Installation log
```

### Log Format Example
```
[2026-02-24 12:34:56] - INFO - Machine Learning Environment Test
[2026-02-24 12:34:56] - INFO - Running in: Host
[2026-02-24 12:35:01] - INFO - --- PyTorch Tests ---
[2026-02-24 12:35:10] - INFO - ✅ PyTorch Basic Test passed.
[2026-02-24 12:35:20] - ERROR - ✗ PyTorch Distributed Test failed: NCCL not found
```

### Log Analysis Commands
```bash
# Show all errors
grep ERROR ml_env_test.log

# Show all passed tests
grep "✅" ml_env_test.log

# Count test results
grep -c "✅" ml_env_test.log  # Passed
grep -c "✗" ml_env_test.log   # Failed

# View specific framework tests
grep "PyTorch\|TensorFlow\|JAX" ml_env_test.log
```

---

## 📞 Support

### Getting Help with Test Failures

1. **Review test logs:** `cat ml_env_test.log`
2. **Check environment:** `conda list`, `conda info`
3. **Test individual packages:** `python -c "import package"`
4. **Consult documentation:** Review package-specific docs
5. **Rebuild if needed:** `bash bin/setup_install_conda_install.sh`

### Useful Debugging Commands
```bash
# Environment information
conda info

# Installed packages
conda list

# Environment path
echo $CONDA_DEFAULT_ENV

# Python version
python --version

# GPU status
nvidia-smi

# Disk usage
du -sh env/
```

---

**Last Updated:** February 24, 2026  
**Version:** 2026.01
