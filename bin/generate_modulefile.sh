#!/bin/bash
set -euo pipefail

# This script generates a modulefile using variables from setup_install.sh

# Required variables: VERSION, CONTAINER_NAME, PREFIX, MODULESHOME, PACKAGE, TARGET_DIR

MODULEFILE_DIR="$MODULESHOME/${VERSION}"
MODULEFILE_PATH="$MODULEFILE_DIR/singularity"
CONTAINER_PATH="$TARGET_DIR/${CONTAINER_NAME}"

mkdir -p "$MODULEFILE_DIR"

cat > "$MODULEFILE_PATH" <<EOF
#%Module 1.0 -*- tcl -*-
#
#  Module for machine learning package (Singularity container):

set name            machine_learning
set version         $VERSION
set container_path  $CONTAINER_PATH
set stack           gpu

if { [module-info mode load] } {
   puts stderr "Loading module for \$name \$version"
   puts stderr "Container: \$container_path"
   puts stderr "\$name \$version is now loaded"
   #ELASTIC SEARCH SNIPET
   set output [exec /usr/bin/python3 /sw/sources/elasticsearch/elasticapps.py --app "$name" --version "$version" --stack "$stack" &]
}

if { [module-info mode remove] } {
    puts stderr "Unloading module for \$name \$version"
    puts stderr "\$name \$version is now unloaded"
}

# Set container environment variables
setenv ML_CONTAINER_PATH $CONTAINER_PATH
setenv SINGULARITY_IMAGE $CONTAINER_PATH
# setenv SINGULARITY_CACHEDIR /tmp/singularity-cache-\$USER

# Bind common paths for HPC cluster access
# setenv SINGULARITYENV_BIND "/sw,/home,/scratch,/project"

# Container-specific environment variables
# setenv SINGULARITYENV_LD_LIBRARY_PATH "/usr/local/lib:/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH"
# setenv SINGULARITYENV_PATH "/opt/conda/envs/ml-module/bin:/opt/bin:\$PATH"

# GPU support (if using nvidia-container-runtime)
setenv SINGULARITYENV_NVIDIA_VISIBLE_DEVICES all
setenv SINGULARITYENV_NVIDIA_DRIVER_CAPABILITIES compute,utility

# Inform user how to run the container
puts stderr ""
puts stderr "To run a command in the container:"
puts stderr "  singularity exec \$ML_CONTAINER_PATH <command>"
puts stderr ""
puts stderr "To open an interactive shell:"
puts stderr "  singularity shell \$ML_CONTAINER_PATH"
puts stderr ""
EOF

echo "Singularity modulefile generated at $MODULEFILE_PATH"
echo "Container location: $CONTAINER_PATH"
