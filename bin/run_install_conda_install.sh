#!/bin/bash
#
# Conda Environment Installation Script
# Creates a conda ML environment from environment.yml
#
# Standard Interface: Expects the following environment variables:
#   PREFIX              - Project root directory
#   ENV_PREFIX          - Path where conda environment will be created
#   PACKAGE             - Package name (for logging)
#   VERSION             - Package version (for logging)
#   SRC_REPO            - Source repository URL
#
# Returns:
#   0  - Success
#   1  - Failure
#
# Installation Flow:
#   1. Clone repository from SRC_REPO
#   2. Verify environment.yml exists
#   3. Check conda/mamba availability
#   4. Create conda environment from environment.yml
#   5. Verify installation
#   6. Cleanup build artifacts

set -euo pipefail

# ========================== REQUIRED VARIABLES ==========================
if [[ -z "${PREFIX:-}" ]] || [[ -z "${ENV_PREFIX:-}" ]]; then
    echo "ERROR: PREFIX and ENV_PREFIX environment variables must be set"
    exit 1
fi

if [[ -z "${SRC_REPO:-}" ]] || [[ -z "${VERSION:-}" ]] || [[ -z "${PACKAGE:-}" ]]; then
    echo "ERROR: SRC_REPO, VERSION, and PACKAGE environment variables must be set"
    exit 1
fi

# ========================== LOGGING SETUP ==========================
LOG_FILE="conda_install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Conda ML Environment Installation"
echo "=========================================================================="
echo "[INFO] Package:       $PACKAGE"
echo "[INFO] Version:       $VERSION"
echo "[INFO] Repository:    $SRC_REPO"
echo "[INFO] PREFIX:        $PREFIX"
echo "[INFO] ENV_PREFIX:    $ENV_PREFIX"
echo ""

# ========================== STEP 1: CLONE REPOSITORY ==========================
echo "[INFO] STEP 1: Cloning repository..."
echo "=========================================================================="

INSTALL_BUILD_PATH="$PWD/ml-module-${VERSION}"

# Check for git command availability
command -v git >/dev/null 2>&1 || { 
    echo "$PACKAGE - git is required but not installed - installation failed"
    exit 1
}

# Clone the repository
if ! git clone "${SRC_REPO}" -b "machine-learning-${VERSION}" "${INSTALL_BUILD_PATH}" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Repository clone failed"
    echo "$PACKAGE - repository clone failure - installation failed"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Repository cloned successfully to: ${INSTALL_BUILD_PATH}"
echo ""

# ========================== STEP 2: VERIFY REQUIREMENTS ==========================
echo "[INFO] STEP 2: Verifying requirements..."
echo "=========================================================================="

# Verify environment.yml exists in cloned repository
if [[ ! -f "${INSTALL_BUILD_PATH}/environment.yml" ]]; then
    echo "[ERROR] environment.yml not found at ${INSTALL_BUILD_PATH}/environment.yml"
    echo "$PACKAGE - environment.yml not found - installation failed"
    exit 1
fi

echo "[INFO] ✓ environment.yml found at: ${INSTALL_BUILD_PATH}/environment.yml"

# Also check in PREFIX for user customizations
if [[ -f "${PREFIX}/environment.yml" ]]; then
    echo "[INFO] ✓ Customized environment.yml found at: ${PREFIX}/environment.yml"
    echo "[INFO] Using customized version from PREFIX"
    ENVIRONMENT_FILE="${PREFIX}/environment.yml"
else
    echo "[INFO] Using default environment.yml from cloned repository"
    ENVIRONMENT_FILE="${INSTALL_BUILD_PATH}/environment.yml"
fi

echo ""

# ========================== STEP 3: CHECK CONDA/MAMBA ==========================
echo "[INFO] STEP 3: Checking conda/mamba availability..."
echo "=========================================================================="

# Check for conda/mamba
if command -v mamba &> /dev/null; then
    CONDA_CMD="mamba"
elif command -v conda &> /dev/null; then
    CONDA_CMD="conda"
else
    echo "[ERROR] Neither mamba nor conda found in PATH"
    echo "$PACKAGE - conda/mamba not available - installation failed"
    exit 1
fi

echo "[INFO] ✓ Using package manager: $CONDA_CMD"
echo "[INFO] Command: $(command -v $CONDA_CMD)"
echo "[INFO] Version: $($CONDA_CMD --version 2>&1)"
echo ""

# ========================== STEP 4: CREATE CONDA ENVIRONMENT ==========================
echo "[INFO] STEP 4: Creating conda environment..."
echo "=========================================================================="

# Set conda package cache directory
export CONDA_PKGS_DIRS="${CONDA_PKGS_DIRS:-.conda_cache}"
mkdir -p "$CONDA_PKGS_DIRS"
echo "[INFO] Conda cache directory: $CONDA_PKGS_DIRS"
echo "[INFO] Environment file: $ENVIRONMENT_FILE"
echo "[INFO] Target location: ${ENV_PREFIX}"
echo ""

# Create the conda environment
if $CONDA_CMD env create \
    --prefix "$ENV_PREFIX" \
    --file "$ENVIRONMENT_FILE" \
    --force \
    2>&1 | tee -a "$LOG_FILE"; then
    
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Environment created successfully"
else
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Environment creation failed"
    echo "[ERROR] See logs above for details"
    echo "[INFO] Build artifacts retained at: ${INSTALL_BUILD_PATH}"
    echo "[INFO] Log file: $LOG_FILE"
    exit 1
fi

echo ""

# ========================== STEP 5: VERIFY INSTALLATION ==========================
echo "[INFO] STEP 5: Verifying installation..."
echo "=========================================================================="

# Verify environment directory exists
if [[ ! -d "${ENV_PREFIX}" ]]; then
    echo "[ERROR] Environment directory not found at ${ENV_PREFIX}"
    echo "$PACKAGE - environment directory not created - installation failed"
    exit 1
fi

echo "[INFO] ✓ Environment directory exists: ${ENV_PREFIX}"

# Verify Python is available
if [[ -f "${ENV_PREFIX}/bin/python" ]]; then
    PYTHON_VERSION=$(${ENV_PREFIX}/bin/python --version 2>&1)
    echo "[INFO] ✓ Python available: $PYTHON_VERSION"
else
    echo "[ERROR] Python executable not found at ${ENV_PREFIX}/bin/python"
    echo "$PACKAGE - python not installed - installation failed"
    exit 1
fi

# Optional: Verify core packages (quick check)
echo "[INFO] Verifying core packages..."
if ${ENV_PREFIX}/bin/python -c "import numpy, pandas, torch, sklearn" 2>/dev/null; then
    echo "[INFO] ✓ Core packages verified (numpy, pandas, torch, sklearn)"
else
    echo "[WARNING] Could not verify all core packages - some may have failed to install"
    echo "[INFO] Run verify_install_conda_install.sh for comprehensive verification"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Installation verification complete"
echo ""

# ========================== STEP 6: CLEANUP BUILD ARTIFACTS ==========================
echo "[INFO] STEP 6: Cleaning up build artifacts..."
echo "=========================================================================="

# Remove cloned repository (largest space consumer)
if [[ -d "${INSTALL_BUILD_PATH}" ]]; then
    REPO_SIZE=$(du -sh "${INSTALL_BUILD_PATH}" 2>/dev/null | cut -f1 || echo "unknown")
    echo "[INFO] Removing cloned repository: ${INSTALL_BUILD_PATH} (size: $REPO_SIZE)"
    rm -rf "${INSTALL_BUILD_PATH}"
    echo "[INFO] ✓ Repository cleaned"
fi

# Remove this installation script if copied to target directory
if [[ -f "${ENV_PREFIX}/../run_install_conda_install.sh" ]]; then
    echo "[INFO] Removing copied installation script"
    rm -f "${ENV_PREFIX}/../run_install_conda_install.sh"
fi

# Archive logs with timestamp
if [[ -f "$LOG_FILE" ]]; then
    BUILD_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE_NAME="conda_install_${BUILD_TIMESTAMP}.tar.gz"
    echo "[INFO] Archiving logs to: $ARCHIVE_NAME"
    
    tar -czf "$ARCHIVE_NAME" "$LOG_FILE" 2>/dev/null || echo "[WARNING] Could not create archive"
    
    # Record installation metadata
    {
        echo "Installation completed successfully at $(date)"
        echo "Package: $PACKAGE, Version: $VERSION"
        echo "Environment location: ${ENV_PREFIX}"
        echo "Log archive: $ARCHIVE_NAME"
    } >> "${ENV_PREFIX}/../installation_metadata.log"
    
    rm -f "$LOG_FILE"
fi

echo "[INFO] ✓ Cleanup complete"
echo ""

# ========================== FINAL SUMMARY ==========================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installation completed successfully"
echo "=========================================================================="
echo "[INFO] Environment location: ${ENV_PREFIX}"
echo "[INFO] To activate:          conda activate ${ENV_PREFIX}"
echo "[INFO] To verify:            bash bin/verify_install_conda_install.sh ${ENV_PREFIX}"
echo "[INFO] To test:              sbatch bin/test-conda-env_conda_install.sbatch"
echo ""

exit 0
