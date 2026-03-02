#!/bin/bash
#
# Conda ML Environment Verification Script
# 
# Quickly verifies that the conda environment was installed correctly
# Checks for key packages and capabilities
#
# Usage: bash verify_install_conda_install.sh [env_path]

set -euo pipefail

# Get environment path
ENV_PATH="${1:-.env}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Tracking
CHECKS_PASSED=0
CHECKS_FAILED=0

# Helper function
check_package() {
    local pkg_name=$1
    local import_name=${2:-$pkg_name}
    
    if [[ ! -d "${ENV_PATH}" ]]; then
        echo -e "${RED}✗${NC} Environment not found at: ${ENV_PATH}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        return 1
    fi
    
    if ${ENV_PATH}/bin/python -c "import ${import_name}" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} ${pkg_name}"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} ${pkg_name}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        return 1
    fi
}

echo "=================================================="
echo "Conda ML Environment Verification"
echo "=================================================="
echo ""
echo "Environment: ${ENV_PATH}"
echo ""

# Check if env exists
if [[ ! -d "${ENV_PATH}" ]]; then
    echo -e "${RED}ERROR: Environment not found at ${ENV_PATH}${NC}"
    exit 1
fi

# Check Python version
echo "Python & Core:"
PYTHON_VERSION=$(${ENV_PATH}/bin/python --version 2>&1)
echo "  $PYTHON_VERSION"

# Core packages
echo ""
echo "Core Data Science:"
check_package "NumPy" "numpy"
check_package "Pandas" "pandas"
check_package "SciPy" "scipy"
check_package "Scikit-Learn" "sklearn"

# Deep Learning
echo ""
echo "Deep Learning Frameworks:"
check_package "PyTorch" "torch"
check_package "TensorFlow" "tensorflow"
check_package "JAX" "jax"

# ML Libraries
echo ""
echo "ML Libraries:"
check_package "XGBoost" "xgboost"
check_package "LightGBM" "lightgbm"
check_package "CatBoost" "catboost"

# Distributed Computing
echo ""
echo "Distributed Computing:"
check_package "Dask" "dask"
check_package "Ray" "ray"

# GPU Support (optional)
echo ""
echo "GPU Support (optional):"
check_package "cuDF" "cudf" || true
check_package "cuGraph" "cugraph" || true

# Summary
echo ""
echo "=================================================="
echo "Summary:"
echo -e "  ${GREEN}Passed: ${CHECKS_PASSED}${NC}"
echo -e "  ${RED}Failed: ${CHECKS_FAILED}${NC}"
echo "=================================================="

if [[ ${CHECKS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}✓ All critical packages verified!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some packages failed verification.${NC}"
    exit 1
fi
