#!/bin/bash

# Run this script to build the ITK Python wheel packages for Linux.
#
# Versions can be restricted by passing them in as arguments to the script
# For example,
#
#   scripts/dockcross-manylinux-build-wheels.sh cp39

MANYLINUX_VERSION=_2_28
IMAGE_TAG_x86=20221103-57a27d5
IMAGE_TAG_arm64=2022-11-06-7be974c

if [[ -z TARGET_ARCH]]; then
  TARGET_ARCH="x86"
fi

if [[ $TARGET_ARCH != "x86" || $TARGET_ARCH != "arm64" ]]; then
  echo "TARGET_ARCH not recognized: $TARGET_ARCH"
  exit 1
fi

if [[ TARGET_ARCH == "x86" ]]; then
  # Generate dockcross scripts
  docker run --rm dockcross/manylinux${MANYLINUX_VERSION}-x64:${IMAGE_TAG_x86} > /tmp/dockcross-manylinux-x64
  chmod u+x /tmp/dockcross-manylinux-x64

  script_dir=$(cd $(dirname $0) || exit 1; pwd)

  # Build wheels
  pushd $script_dir/..
  mkdir -p dist
  DOCKER_ARGS="-v $(pwd)/dist:/work/dist/"
  /tmp/dockcross-manylinux-x64 \
    -a "$DOCKER_ARGS" \
    ./scripts/internal/manylinux-build-wheels.sh "$@"
  popd

else if [[ TARGET_ARCH == "arm64" ]]; then
  # Install cross-platform emulator
  docker run --privileged --rm tonistiigi/binfmt --install arm64

  # Launch build container
  DOCKER_ARGS="-it -v $(pwd):/work/"
  docker run \
    -a "$DOCKER_ARGS" \
    quay.io/pypa/manylinux${MANYLINUX_VERSION}_aarch64:${IMAGE_TAG_arm64} \
    ./scripts/internal/manylinux-build-wheels.sh "$@"
fi
