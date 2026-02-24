#!/bin/bash
# ==============================================================================
# ML Module Container Post-Build Verification Test
# ==============================================================================
# Run this script after building the container to verify all components work
# Usage: bash test-container-verification.sh ml_module_v1.0.sif
# ==============================================================================
module load singularity

# Configuration
CONTAINER="ml_module_v1.0.sif"
TEST_RESULTS_DIR="test-results"
TEST_LOG="${TEST_RESULTS_DIR}/verification-$(date +%Y%m%d-%H%M%S).log"

# Create results directory
mkdir -p "${TEST_RESULTS_DIR}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==============================================================================
# Helper Functions
# ==============================================================================

log_header() {
    echo "=========================================="
    echo "$1"
    echo "==========================================" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$TEST_LOG"
}

log_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}" | tee -a "$TEST_LOG"
}

run_test() {
    local test_name=$1
    local test_cmd=$2

    log_info "Running: $test_name"
    # Temporarily disable errexit so failing tests don't abort the script
    eval "$test_cmd" >> "$TEST_LOG" 2>&1
    local status=$?

    if [ $status -eq 0 ]; then
        log_success "$test_name passed"
        return 0
    else
        log_error "$test_name failed"
        return 1
    fi
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

log_header "ML Module Container Verification Tests"

echo "Test Log: $TEST_LOG"
echo ""

# Check if container exists
if [ ! -f "$CONTAINER" ]; then
    log_error "Container not found: $CONTAINER"
    exit 1
fi

log_success "Container found: $CONTAINER"
echo "Container size: $(du -h $CONTAINER | cut -f1)"
echo ""

# ==============================================================================
# Test Suite
# ==============================================================================

PASSED=0
FAILED=0

# Test 1: Container Validity
log_header "Test 1: Container Validity"
if run_test "Container inspection" "singularity inspect $CONTAINER > /dev/null 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 2: Python and Jupyter
log_header "Test 2: Python and Jupyter"
if run_test "Python version" "singularity exec $CONTAINER python --version"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Jupyter in PATH" "singularity exec $CONTAINER which jupyter"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Jupyter Lab version" "singularity exec $CONTAINER jupyter lab --version"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 3: Core ML Frameworks
log_header "Test 3: ML Frameworks"
if run_test "PyTorch" "singularity exec --nv $CONTAINER python -c 'import torch; print(f\"PyTorch {torch.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "TensorFlow" "singularity exec --nv $CONTAINER python -c 'import tensorflow as tf; print(f\"TensorFlow {tf.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "JAX" "singularity exec --nv $CONTAINER python -c 'import jax; print(f\"JAX {jax.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "RAPIDS cuDF" "singularity exec --nv $CONTAINER python -c 'import cudf; print(f\"cuDF {cudf.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 4: Data Science Libraries
log_header "Test 4: Data Science Libraries"
if run_test "Pandas" "singularity exec $CONTAINER python -c 'import pandas; print(f\"Pandas {pandas.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Scikit-learn" "singularity exec $CONTAINER python -c 'import sklearn; print(f\"Scikit-learn {sklearn.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Polars" "singularity exec $CONTAINER python -c 'import polars; print(f\"Polars {polars.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 5: Distributed Computing
log_header "Test 5: Distributed Computing"
if run_test "Dask" "singularity exec $CONTAINER python -c 'import dask; print(f\"Dask {dask.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Ray" "singularity exec $CONTAINER python -c 'import ray; print(f\"Ray {ray.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 6: ML Tools
log_header "Test 6: ML Tools and Utilities"
if run_test "LightGBM" "singularity exec $CONTAINER python -c 'import lightgbm; print(f\"LightGBM {lightgbm.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "XGBoost" "singularity exec $CONTAINER python -c 'import xgboost; print(f\"XGBoost {xgboost.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "MLflow" "singularity exec $CONTAINER python -c 'import mlflow; print(f\"MLflow {mlflow.__version__}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 7: GPU Access
log_header "Test 7: GPU and CUDA"
if run_test "nvidia-smi" "singularity exec --nv $CONTAINER nvidia-smi --query-gpu=name --format=csv,noheader"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "PyTorch CUDA" "singularity exec --nv $CONTAINER python -c 'import torch; assert torch.cuda.is_available(), \"CUDA not available\"; print(f\"CUDA available: {torch.cuda.is_available()}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "TensorFlow GPU" "singularity exec --nv $CONTAINER python -c 'import tensorflow as tf; gpus=tf.config.list_physical_devices(\"GPU\"); print(f\"GPUs detected: {len(gpus)}\")' 2>&1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test 8: Development Tools
log_header "Test 8: Development Tools"
if run_test "Git" "singularity exec $CONTAINER git --version"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Vim" "singularity exec $CONTAINER vim --version | head -1"; then
    ((PASSED++))
else
    ((FAILED++))
fi

if run_test "Curl" "singularity exec $CONTAINER curl --version | head -1"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# ==============================================================================
# Test Summary
# ==============================================================================

log_header "Test Summary"
TOTAL=$((PASSED + FAILED))
PASS_RATE=$((PASSED * 100 / TOTAL))

echo "Total tests: $TOTAL" | tee -a "$TEST_LOG"
echo "Passed: $PASSED" | tee -a "$TEST_LOG"
echo "Failed: $FAILED" | tee -a "$TEST_LOG"
echo "Pass rate: ${PASS_RATE}%" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

if [ $FAILED -eq 0 ]; then
    log_success "All tests passed! Container is ready to use."
    echo "" | tee -a "$TEST_LOG"
    echo "Next steps:" | tee -a "$TEST_LOG"
    echo "1. Deploy the container to /ibex/shared/modules/machine-learning/" | tee -a "$TEST_LOG"
    echo "2. Generate the environment module" | tee -a "$TEST_LOG"
    echo "3. Test with: sbatch bin/launch-jupyter-container.sbatch" | tee -a "$TEST_LOG"
    exit 0
else
    log_error "Some tests failed. See $TEST_LOG for details."
    exit 1
fi
