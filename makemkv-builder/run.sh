#!/bin/sh
SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
BUILDER_DOCKER_IMAGE="ubuntu:xenial"

exec docker run --rm -ti \
    -v "$SCRIPT_DIR:/output" \
    -v "$SCRIPT_DIR/builder:/builder:ro" \
    "$BUILDER_DOCKER_IMAGE" /builder/build.sh /output
