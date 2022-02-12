#!/usr/bin/env bash

# @param ${ARCH}             The architecture to build. Example: amd64
# @param ${DEBIAN_VERSION}   The debian version to build. Example: buster
# @param ${ARCH_IMAGE}       What the Docker Hub Image should be tagged as [default: None]

set -eux

#./Dockerfile.py -v --no-cache --arch="${ARCH}" --debian="${DEBIAN_VERSION}" --s6="${S6_OVERLAY_VERSION}" --hub_tag="${ARCH_IMAGE}"
./Dockerfile.py -v --arch="${ARCH}" --debian="${DEBIAN_VERSION}" --s6="${S6_OVERLAY_VERSION}" --hub_tag="${ARCH_IMAGE}"
docker images

# TODO: Add junitxml output and have something consume it
# 2 parallel max b/c race condition with docker fixture (I think?)
py.test -vv -n 2 -k "${ARCH}" ./test/
