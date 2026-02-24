#!/bin/bash
#
# Conda ML Module Setup and Installation Orchestrator
# 
# This script orchestrates the creation of a conda environment for the ML module
# It sets up necessary environment variables and calls the installation script
#
# Usage: bash setup_install_conda_install.sh
#
# Configuration via environment variables:
#   PREFIX                 - Project root (optional, defaults to current directory)
#   CONDA_ENV_NAME         - Environment name (optional, defaults to "ml-module")
#   SKIP_ACTIVATION_CHECK  - Skip checking for conda activation (optional)

set -euo pipefail

# Default values
PREFIX="${PREFIX:-.}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-ml-module}"
ENV_PREFIX="${PREFIX}/env"

# Export variables for child script
export PREFIX
export ENV_PREFIX
export CONDA_ENV_NAME

# Check if we're in the correct directory
if [[ ! -f "${PREFIX}/environment.yml" ]]; then
    echo "ERROR: environment.yml not found in ${PREFIX}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "==============================================="
echo "Conda ML Module Setup and Installation"
echo "==============================================="
echo ""
echo "Configuration:"
echo "  Project Root (PREFIX):     ${PREFIX}"
echo "  Environment Location:      ${ENV_PREFIX}"
echo "  Environment Name:          ${CONDA_ENV_NAME}"
echo ""

# Check for conda/mamba availability
if ! command -v conda &> /dev/null && ! command -v mamba &> /dev/null; then
    echo "ERROR: conda or mamba must be installed and in PATH"
    echo ""
    echo "To set up conda, run:"
    echo "  source /ibex/user/\${USER}/miniconda3/bin/activate"
    echo "  # OR"
    echo "  source /path/to/your/conda/installation/bin/activate"
    exit 1
fi

echo "✓ Conda/Mamba found in PATH"
echo ""

# Source conda activation if not already activated
if [[ -z "${CONDA_DEFAULT_ENV:-}" ]]; then
    echo "[INFO] Activating conda environment..."
    # Try common conda installation locations
    if [[ -f "/ibex/user/${USER}/miniconda3/bin/activate" ]]; then
        source "/ibex/user/${USER}/miniconda3/bin/activate"
    elif [[ -f "/opt/conda/etc/profile.d/conda.sh" ]]; then
        source "/opt/conda/etc/profile.d/conda.sh"
    fi
fi

echo "[INFO] Creating target environment directory..."
mkdir -p "$(dirname "${ENV_PREFIX}")"

echo ""
echo "Starting installation..."
echo "==============================================="
echo ""

# Call the installation script
if bash "${PREFIX}/bin/run_install_conda_install.sh"; then
    echo ""
    echo "==============================================="
    echo "✓ Installation completed successfully!"
    echo "==============================================="
    echo ""
    
    # Optional: Generate modulefile for HPC cluster use
    # Uncomment the section below to generate a modulefile
    if [[ "${GENERATE_MODULEFILE:-0}" == "1" ]]; then
        echo "Generating modulefile..."
        export MODULESHOME="${MODULESHOME:-.modulefiles}"
        export VERSION="${VERSION:-2026.01}"
        export PACKAGE="${PACKAGE:-machine_learning}"
        
        if bash "${PREFIX}/bin/generate_modulefile_conda_install.sh"; then
            echo "✓ Modulefile generated"
        else
            echo "⚠ Modulefile generation failed (non-critical)"
        fi
        echo ""
    fi
    
    echo "Next steps:"
    echo "  1. Activate environment:  conda activate ${ENV_PREFIX}"
    echo "  2. Run tests:             sbatch bin/test-conda-env_conda_install.sbatch"
    if [[ "${GENERATE_MODULEFILE:-0}" != "1" ]]; then
        echo "  3. Generate modulefile:   MODULESHOME=/path/to/modulefiles GENERATE_MODULEFILE=1 bash setup_install_conda_install.sh"
    fi
    echo ""
    exit 0
else
    echo ""
    echo "==============================================="
    echo "✗ Installation failed"
    echo "==============================================="
    echo "Check the logs in: conda_install.log"
    exit 1
fi
