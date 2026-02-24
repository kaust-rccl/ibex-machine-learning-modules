#!/bin/bash
#
# Conda Environment Modulefile Generator
#
# This script generates a modulefile for the conda ML environment
# allowing users to load it via: module load machine_learning/conda
#
# Required environment variables:
#   VERSION         - Version string (e.g., 2026.01)
#   ENV_PREFIX      - Path to conda environment
#   PREFIX          - Project root directory
#   MODULESHOME     - Modulefiles installation directory
#   PACKAGE         - Package name (default: machine_learning)
#
# Generated file location: ${MODULESHOME}/${VERSION}/conda

set -euo pipefail

# Set defaults if not provided
VERSION="${VERSION:-2026.01}"
ENV_PREFIX="${ENV_PREFIX:-.env}"
PREFIX="${PREFIX:-.}"
MODULESHOME="${MODULESHOME:-.modulefiles}"
PACKAGE="${PACKAGE:-machine_learning}"

# Verify environment exists
if [[ ! -d "${ENV_PREFIX}" ]]; then
    echo "ERROR: Conda environment not found at ${ENV_PREFIX}"
    exit 1
fi

# Create modulefile directory
MODULEFILE_DIR="${MODULESHOME}/${VERSION}"
MODULEFILE_PATH="${MODULEFILE_DIR}/conda"

mkdir -p "${MODULEFILE_DIR}"

echo "[INFO] Generating conda modulefile..."
echo "[INFO] Environment: ${ENV_PREFIX}"

# Generate the modulefile
cat > "${MODULEFILE_PATH}" <<'EOFMOD'
#%Module 1.0 -*- tcl -*-
#
# Module for machine learning package (Conda environment)
#

EOFMOD

# Add dynamic content to the modulefile
cat >> "${MODULEFILE_PATH}" <<EOF
set name            $PACKAGE
set version         $VERSION
set env_prefix      $ENV_PREFIX
set stack           gpu

if { [module-info mode load] } {
   puts stderr "Loading module for \$name \$version"
   puts stderr "Environment: \$env_prefix"
   puts stderr "\$name \$version is now loaded"
}

if { [module-info mode remove] } {
    puts stderr "Unloading module for \$name \$version"
    puts stderr "\$name \$version is now unloaded"
}

# Set conda environment variables
setenv ML_ENV_PREFIX $ENV_PREFIX
setenv CONDA_DEFAULT_ENV $ENV_PREFIX

# Prepend conda environment to PATH and PYTHONPATH
prepend-path PATH $ENV_PREFIX/bin
prepend-path LD_LIBRARY_PATH $ENV_PREFIX/lib
prepend-path PYTHONPATH $ENV_PREFIX/lib/python*/site-packages

# GPU support (if CUDA/cuDF installed)
setenv CUDA_VISIBLE_DEVICES 0

# Convenience variables
setenv ML_PYTHON $ENV_PREFIX/bin/python
setenv ML_PIP $ENV_PREFIX/bin/pip
setenv ML_JUPYTER $ENV_PREFIX/bin/jupyter

# Inform user how to use the environment
puts stderr ""
puts stderr "Conda ML Environment loaded:"
puts stderr "  Python:  \$env_prefix/bin/python"
puts stderr "  Jupyter: \$env_prefix/bin/jupyter lab"
puts stderr "  Pip:     \$env_prefix/bin/pip"
puts stderr ""
puts stderr "To activate in script: conda activate \$env_prefix"
puts stderr ""
EOF

# Set proper permissions
chmod 644 "${MODULEFILE_PATH}"

echo "[INFO] ✓ Modulefile generated successfully"
echo "[INFO] Location: ${MODULEFILE_PATH}"
echo "[INFO] Version: ${VERSION}"
echo ""
echo "To use this modulefile:"
echo "  module load ${PACKAGE}/${VERSION}/conda"
echo ""

exit 0
