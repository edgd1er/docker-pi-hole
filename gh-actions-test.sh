#!/usr/bin/env bash
set -x

# Script ran by Github actions for tests
#
# @environment ${ARCH}              The architecture to build. Example: amd64.
# @environment ${DEBIAN_VERSION}    Debian version to build. ('bullseye' or 'buster').
# @environment ${ARCH_IMAGE}        What the Docker Hub Image should be tagged as. Example: pihole/pihole:master-amd64-bullseye

# setup qemu/variables
docker run --rm --privileged multiarch/qemu-user-static:register --reset > /dev/null
. gh-actions-vars.sh

if [[ "$1" == "enter" ]]; then
    enter="-it --entrypoint=sh"
fi

# generate and build dockerfile
docker build  --tag image_pipenv --file Dockerfile_build .
docker run --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd):/$(pwd)" \
    --workdir "$(pwd)" \
    --env PIPENV_CACHE_DIR="$(pwd)/.pipenv" \
    --env ARCH="${ARCH}" \
    --env ARCH_IMAGE="${ARCH_IMAGE}" \
    --env DEBIAN_VERSION="${DEBIAN_VERSION}" \
    --env GIT_TAG="${GIT_TAG}" \
    --env CORE_VERSION="${CORE_VERSION}" \
    --env WEB_VERSION="${WEB_VERSION}" \
    --env FTL_VERSION="${FTL_VERSION}" \
    --env S6_OVERLAY_VERSION="${S6_OVERLAY_VERSION}" \
    ${enter} image_pipenv

mkdir -p ".gh-workspace/${DEBIAN_VERSION}/"
echo "${ARCH_IMAGE}" | tee "./.gh-workspace/${DEBIAN_VERSION}/${ARCH}"
