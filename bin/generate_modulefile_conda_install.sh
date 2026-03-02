#!/bin/bash
#
# Conda Environment Modulefile Generator
#
# This script generates a modulefile for the conda ML environment
# allowing users to load it via: module load machine_learning/conda
#
# Required environment variables:
#   VERSION         - Version string (e.g., 2026.02)
#   ENV_PREFIX      - Path to conda environment
#   PREFIX          - Project root directory
#   MODULESHOME     - Modulefiles installation directory
#   PACKAGE         - Package name (default: machine_learning)
#
# Generated file location: ${MODULESHOME}/${VERSION}

set -euo pipefail

# Set defaults if not provided
# VERSION="${VERSION:-2026.02}"
# ENV_PREFIX="${ENV_PREFIX:-.env}"
# PREFIX="${PREFIX:-.}"
# MODULESHOME="${MODULESHOME:-.modulefiles}"
# PACKAGE="${PACKAGE:-machine_learning}"

# Verify environment exists
if [[ ! -d "${ENV_PREFIX}" ]]; then
    echo "ERROR: Conda environment not found at ${ENV_PREFIX}"
    exit 1
fi

# Create modulefile directory
MODULEFILE_DIR="${MODULESHOME}"
MODULEFILE_PATH="${MODULEFILE_DIR}/${VERSION}"

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
set pkg_dir         $ENV_PREFIX
set name            $PACKAGE
set version         $VERSION

if { [module-info mode load] } {
   puts stderr "Loading module for \$name \$version"
   puts stderr "\$name \$version is now loaded"
   set output [exec python3 /sw/sources/elasticsearch/elasticapps.py --app "$PACKAGE" --version "$VERSION" &]
}

if { [module-info mode remove] } {
    puts stderr "Unloading module for \$name \$version"
    puts stderr "\$name \$version is now unloaded"
}

# Specific setup goes here, license files, path setup, etc
prepend-path PATH \$pkg_dir/bin
prepend-path LD_LIBRARY_PATH \$pkg_dir/lib
prepend-path LIBRARY_PATH \$pkg_dir/lib

setenv CONDA_DEFAULT_ENV \$pkg_dir
setenv CONDA_PREFIX \$pkg_dir

prepend-path PYTHONPATH \$pkg_dir/lib
prepend-path PKG_CONFIG_PATH \$pkg_dir/lib/pkgconfig
EOF

# Set proper permissions
chmod 644 "${MODULEFILE_PATH}"

echo "[INFO] ✓ Modulefile generated successfully"
echo "[INFO] Location: ${MODULEFILE_PATH}"
echo "[INFO] Version: ${VERSION}"
echo ""
echo "To use this modulefile:"
echo "  module load ${PACKAGE}/${VERSION}"
echo ""

exit 0
