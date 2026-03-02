#!/bin/bash
set -euo pipefail

# Export all variables needed by run_install.sh
export VERSION="2025.01"
export CONTAINER_NAME="ml_module_${VERSION}.sif"
export PREFIX="$PWD"
export SOFTWARE_SOURCE_DIRECTORY="/sw/sources"
export MODULESHOME="/sw/rl9g/modulefiles/applications/machine_learning"
export PACKAGE="machine_learning"
export SRCDIR="${SOFTWARE_SOURCE_DIRECTORY}/${PACKAGE}"
export SRC_REPO="https://github.com/D-Barradas/ibex-machine-learning-modules.git"
export TARGET_DIR="machine_learning/${VERSION}/singularity"

# Log file
export LOGFILE="$PREFIX/rebuild_module.log"
echo "--- Rebuild started at $(date) ---" > "$LOGFILE"


# Clean up previous installation
echo "[INFO] Cleaning up previous Singularity installation..." | tee -a "$LOGFILE"
rm -rf "machine_learning-module/${VERSION}" 2>&1 | tee -a "$LOGFILE"
rm -f "${TARGET_DIR}/${CONTAINER_NAME}" 2>&1 | tee -a "$LOGFILE"

# Create the target directory
echo "[INFO] Creating target directory $TARGET_DIR..." | tee -a "$LOGFILE"
mkdir -p "$TARGET_DIR" 2>&1 | tee -a "$LOGFILE"

# Change permissions on the specified directory
echo "[INFO] Setting permissions on $TARGET_DIR..." | tee -a "$LOGFILE"
chmod g+w "$TARGET_DIR" 2>&1 | tee -a "$LOGFILE"

# Copy run_install.sh into the new directory
echo "[INFO] Copying run_install.sh to $TARGET_DIR..." | tee -a "$LOGFILE"
cp run_install.sh "$TARGET_DIR/" 2>&1 | tee -a "$LOGFILE"


# Change to the new directory and execute the script
echo "[INFO] Changing to $TARGET_DIR and running run_install.sh..." | tee -a "$LOGFILE"
cd "$TARGET_DIR"
bash run_install.sh 2>&1 | tee -a "$LOGFILE"


# Create a module file
echo "[INFO] Generating modulefile..." | tee -a "$LOGFILE"
bash "$PREFIX/generate_modulefile.sh" 2>&1 | tee -a "$LOGFILE"

echo "--- Rebuild finished at $(date) ---" | tee -a "$LOGFILE"