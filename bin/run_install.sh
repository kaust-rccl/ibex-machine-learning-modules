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
  exit 1
fi

echo "[INFO] Container verification successful" | tee -a install.log

############################### if this far, return 0
exit 0
