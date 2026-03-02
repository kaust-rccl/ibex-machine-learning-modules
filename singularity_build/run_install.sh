#!/bin/bash
set -euo pipefail


# Check for required commands
command -v git >/dev/null 2>&1 || { echo "git is required but not installed. Aborting."; exit 1; }

############################## standard interface to installation
# Input:
#############################   Environment variables
# The following variables should be set by the parent script or environment:
#   PREFIX, SOFTWARE_SOURCE_DIRECTORY, PACKAGE, VERSION, SRCDIR, SRC_REPO, TARGET_DIR, CONTAINER_NAME
#                     only to be used in special circumstances
# Output
#   Return code of 0=success or 1=failure
############################## SINGULARITY CONTAINER BUILD
# Build Singularity container from ml_module.def

# Check for required commands
command -v singularity >/dev/null 2>&1 || { echo "singularity is required but not installed. Aborting."; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git is required but not installed. Aborting."; exit 1; }

INSTALL_BUILD_PATH="$PWD/machine_learning-module"

# Clone the repository branch corresponding to the version
if ! git clone "${SRC_REPO}" -b "machine-learning-${VERSION}" "${INSTALL_BUILD_PATH}" 2>&1 | tee -a install.log; then
  echo "$PACKAGE - repository clone failure - installation failed"
  exit 1
fi

echo "[INFO] Building Singularity container from ml_module.def..." | tee -a install.log
cd "${INSTALL_BUILD_PATH}"

# Build the Singularity container using build-singularity-container.sh
if [ ! -f "./bin/build-singularity-container.sh" ]; then
  echo "$PACKAGE - build-singularity-container.sh not found - installation failed"
  exit 1
fi

if ! bash ./bin/build-singularity-container.sh ml_module.def "${TARGET_DIR}/${CONTAINER_NAME}" 2>&1 | tee -a install.log; then
  echo "$PACKAGE - Singularity container build failure - installation failed"
  exit 1
fi

echo "[INFO] Container built successfully: ${TARGET_DIR}/${CONTAINER_NAME}" | tee -a install.log

# Verify container exists and is readable
if [ ! -r "${TARGET_DIR}/${CONTAINER_NAME}" ]; then
  echo "$PACKAGE - Container file not readable - installation failed"
  echo "[ERROR] Build failed - keeping artifacts for debugging" | tee -a install.log
  echo "[ERROR] Debug info:" | tee -a install.log
  echo "  - Build directory: ${INSTALL_BUILD_PATH}" | tee -a install.log
  echo "  - Expected container: ${TARGET_DIR}/${CONTAINER_NAME}" | tee -a install.log
  echo "  - Log file: ${TARGET_DIR}/install.log" | tee -a install.log
  exit 1
fi

echo "[INFO] Container verification successful" | tee -a install.log

# SUCCESS - Clean up build artifacts
echo "[INFO] Cleaning up build artifacts..." | tee -a install.log

# Remove cloned repository (largest space consumer)
if [ -d "${INSTALL_BUILD_PATH}" ]; then
  echo "[INFO] Removing cloned repository: ${INSTALL_BUILD_PATH}" | tee -a install.log
  rm -rf "${INSTALL_BUILD_PATH}"
fi

# Remove copied script
if [ -f "${TARGET_DIR}/run_install.sh" ]; then
  echo "[INFO] Removing copied run_install.sh" | tee -a install.log
  rm -f "${TARGET_DIR}/run_install.sh"
fi

# Archive logs with timestamp
if [ -f "install.log" ]; then
  BUILD_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  echo "[INFO] Archiving build logs to build_${BUILD_TIMESTAMP}.tar.gz" | tee -a install.log
  tar -czf "${TARGET_DIR}/build_${BUILD_TIMESTAMP}.tar.gz" install.log 2>/dev/null || true
  rm -f install.log
  echo "Build completed successfully at $(date)" >> "${TARGET_DIR}/build_archive.log"
  echo "Archive: build_${BUILD_TIMESTAMP}.tar.gz" >> "${TARGET_DIR}/build_archive.log"
fi

echo "[INFO] Cleanup complete - build archive created"

############################### if this far, return 0
exit 0
