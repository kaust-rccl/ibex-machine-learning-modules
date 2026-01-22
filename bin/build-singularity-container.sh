#!/bin/bash
#
# Build script for Singularity/Apptainer ML module container
# Optimized for RockyLinux 9 HPC clusters
#

set -e

# Load Singularity module on HPC cluster
module load singularity

# Setup Singularity cache directory
mkdir -p /ibex/user/$USER/singularity_cache
export SINGULARITY_CACHEDIR=/ibex/user/$USER/singularity_cache
unset SINGULARITY_BIND

# Configuration - accept parameters or use defaults
DEFINITION_FILE="${1:-ml_module.def}"
OUTPUT_IMAGE="${2:-ml_module_v1.0.sif}"
BUILD_DIR="$PWD"

echo "=========================================="
echo "ML Module Container Build Script"
echo "=========================================="
echo "Definition file: $DEFINITION_FILE"
echo "Output image: $OUTPUT_IMAGE"
echo "Build directory: $BUILD_DIR"
echo ""

# Check if Singularity/Apptainer is installed
if command -v singularity &> /dev/null; then
    CONTAINER_CMD="singularity"
    echo "Found Singularity: $(singularity --version)"
elif command -v apptainer &> /dev/null; then
    CONTAINER_CMD="apptainer"
    echo "Found Apptainer: $(apptainer --version)"
else
    echo "ERROR: Neither Singularity nor Apptainer found"
    echo "Please install one of them first"
    exit 1
fi

# Check if definition file exists
if [ ! -f "$DEFINITION_FILE" ]; then
    echo "ERROR: Definition file not found: $DEFINITION_FILE"
    exit 1
fi

# Create a temporary directory for the build
TMP_BUILD_DIR=$(mktemp -d -t singularity-build-XXXXXXXXXX)
echo "Temporary build directory: $TMP_BUILD_DIR"

# Build the container
echo ""
echo "Starting container build..."
echo "This may take 30-60 minutes depending on network speed and system resources"
echo ""

$CONTAINER_CMD build \
    -f \
    --nv \
    --force \
    "$OUTPUT_IMAGE" \
    "$DEFINITION_FILE"

BUILD_EXIT_CODE=$?

# Clean up
rm -rf "$TMP_BUILD_DIR"

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="
    echo "Output image: $OUTPUT_IMAGE"
    echo "Image size: $(du -h $OUTPUT_IMAGE | cut -f1)"
    echo ""
    echo "Next steps:"
    echo "1. Test the container: singularity exec --nv $OUTPUT_IMAGE python -c 'import torch; print(torch.cuda.is_available())'"
    echo "2. Run test script: sbatch ./bin/test-singularity-container.sbatch"
    echo "3. Deploy to shared location: cp $OUTPUT_IMAGE /ibex/shared/modules/"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "Build failed with exit code: $BUILD_EXIT_CODE"
    echo "=========================================="
    exit $BUILD_EXIT_CODE
fi
