#!/bin/bash

# Run this script to build the ITK Python wheel packages for Linux.
#
# Versions can be restricted by passing them in as arguments to the script
# For example,
#
#   scripts/dockcross-manylinux-build-wheels.sh cp39
#
# A specialized manylinux image and tag can be used by exporting to 
# MANYLINUX_VERSION and IMAGE_TAG before running this script.
# See https://github.com/dockcross/dockcross for available versions and tags.
#
# For example,
#
#   export MANYLINUX_VERSION=2014
#   export IMAGE_TAG=20221205-459c9f0
#   scripts/dockcross-manylinux-build-module-wheels.sh cp39
#

# Handle case where the script directory is not the working directory
script_dir=$(cd $(dirname $0) || exit 1; pwd)
pushd $script_dir/..

source "${script_dir}/dockcross-manylinux-set-vars.sh"

# Set up paths and variables for build
mkdir -p dist
DOCKER_ARGS="-v $(pwd)/dist:/work/dist/"
DOCKER_ARGS+=" -e MANYLINUX_VERSION"
# Mount any shared libraries
if [[ -n ${LD_LIBRARY_PATH} ]]; then
  for libpath in ${LD_LIBRARY_PATH//:/ }; do
	  DOCKER_ARGS+=" -v ${libpath}:/usr/lib64/$(basename -- ${libpath})"
  done
fi

if [[ "${MANYLINUX_VERSION}" == "_2_28" && "${TARGET_ARCH}" = "aarch64" ]]; then
  echo "Install aarch64 architecture emulation tools to perform build for ARM platform"

  if [[ ! ${NO_SUDO} ]]; then
    docker_prefix="sudo"
  fi

  ${docker_prefix} docker run --privileged --rm tonistiigi/binfmt --install all

  # Build wheels
  DOCKER_ARGS+=" -v $(pwd):/work/ --rm"
  ${docker_prefix} docker run $DOCKER_ARGS ${CONTAINER_SOURCE} "/ITKPythonPackage/scripts/internal/manylinux-aarch64-build-wheels.sh" "$@"
else
  # Generate dockcross scripts
  docker run --rm ${CONTAINER_SOURCE} > /tmp/dockcross-manylinux-${TARGET_ARCH}
  chmod u+x /tmp/dockcross-manylinux-${TARGET_ARCH}

  # Build wheels
  /tmp/dockcross-manylinux-${TARGET_ARCH} \
    -a "$DOCKER_ARGS" \
    "/ITKPythonPackage/scripts/internal/manylinux-build-wheels.sh" "$@"
fi

popd # script_dir
