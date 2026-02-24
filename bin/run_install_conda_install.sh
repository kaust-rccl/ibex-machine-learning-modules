#!/bin/bash
#
# Conda Environment Installation Script
# Creates a conda ML environment from environment.yml
#
# Standard Interface: Expects the following environment variables:
#   PREFIX              - Project root directory
#   ENV_PREFIX          - Path where conda environment will be created
#   PROJECT_DIR         - Project directory with environment.yml
#
# Returns:
#   0  - Success
#   1  - Failure

set -euo pipefail

# Ensure we have required variables
if [[ -z "${PREFIX:-}" ]] || [[ -z "${ENV_PREFIX:-}" ]]; then
    echo "ERROR: PREFIX and ENV_PREFIX environment variables must be set"
    exit 1
fi

# Verify environment.yml exists
if [[ ! -f "${PREFIX}/environment.yml" ]]; then
    echo "ERROR: environment.yml not found at ${PREFIX}/environment.yml"
    exit 1
fi

# Setup logging
LOG_FILE="conda_install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Conda ML Environment Creation"
echo "=========================================="
echo "[INFO] PREFIX:        ${PREFIX}"
echo "[INFO] ENV_PREFIX:    ${ENV_PREFIX}"
echo "[INFO] environment.yml: ${PREFIX}/environment.yml"
echo ""

# Check for conda/mamba
if ! command -v mamba &> /dev/null; then
    if ! command -v conda &> /dev/null; then
        echo "[ERROR] Neither mamba nor conda found in PATH"
        exit 1
    fi
    CONDA_CMD="conda"
else
    CONDA_CMD="mamba"
fi

echo "[INFO] Using package manager: $CONDA_CMD"
echo ""

# Set conda package cache directory
export CONDA_PKGS_DIRS="${CONDA_PKGS_DIRS:-.conda_cache}"
mkdir -p "$CONDA_PKGS_DIRS"
echo "[INFO] Conda cache directory: $CONDA_PKGS_DIRS"
echo ""

# Create the conda environment
echo "[INFO] Creating conda environment at: ${ENV_PREFIX}"
echo "[INFO] Installing packages from: ${PREFIX}/environment.yml"
echo "=========================================="

if $CONDA_CMD env create \
    --prefix "$ENV_PREFIX" \
    --file "${PREFIX}/environment.yml" \
    --force \
    2>&1 | tee -a "$LOG_FILE"; then
    
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Environment created successfully"
    echo "[INFO] Environment location: ${ENV_PREFIX}"
    echo "[INFO] To activate: conda activate ${ENV_PREFIX}"
    echo ""
    
    # Verify installation
    echo "[INFO] Verifying environment..."
    if [[ -f "${ENV_PREFIX}/bin/python" ]]; then
        PYTHON_VERSION=$(${ENV_PREFIX}/bin/python --version 2>&1)
        echo "[INFO] Python: $PYTHON_VERSION"
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installation complete"
    exit 0
else
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Environment creation failed"
    echo "[ERROR] See logs above for details"
    echo "[INFO] Log file: $LOG_FILE"
    exit 1
fi
