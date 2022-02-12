#!/usr/bin/env bash
set -a

# @environment ${ARCH}                    The architecture to build. Defaults to 'amd64'.
# @environment ${DEBIAN_VERSION}          Debian version to build. Defaults to 'bullseye'.
# @environment ${DOCKER_HUB_REPO}         The docker hub repo to tag images for. Defaults to 'pihole'.
# @environment ${DOCKER_HUB_IMAGE_NAME}   The name of the resulting image. Defaults to 'pihole'.

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed "s/\//-/g")
GIT_TAG=$(git describe --tags --exact-match 2> /dev/null || true)

DEFAULT_DEBIAN_VERSION="bullseye"
DEFAULT_S6_OVERLAY_VERSION="v2.2.0.3"

if [[ -z "${S6_OVERLAY_VERSION}" ]]; then
    S6_OVERLAY_VERSION=${DEFAULT_S6_OVERLAY_VERSION}
    echo "Defaulting S6_OVERLAY_VERSION to ${S6_OVERLAY_VERSION}"
fi

if [[ -z "${ARCH}" ]]; then
    ARCH="amd64"
    echo "Defaulting arch to ${ARCH}"
fi

if [[ -z "${DEBIAN_VERSION}" ]]; then
    DEBIAN_VERSION="${DEFAULT_DEBIAN_VERSION}"
    echo "Defaulting DEBIAN_VERSION to ${DEBIAN_VERSION}"
fi

if [[ -z "${DOCKER_HUB_REPO}" ]]; then
    DOCKER_HUB_REPO="edgd1er"
    echo "Defaulting DOCKER_HUB_REPO to ${DOCKER_HUB_REPO}"
fi

if [[ -z "${DOCKER_HUB_IMAGE_NAME}" ]]; then
    DOCKER_HUB_IMAGE_NAME="pihole"
    echo "Defaulting DOCKER_HUB_IMAGE_NAME to ${DOCKER_HUB_IMAGE_NAME}"
fi

BASE_IMAGE="${DOCKER_HUB_REPO}/${DOCKER_HUB_IMAGE_NAME}"

GIT_TAG="${GIT_TAG:-$GIT_BRANCH}"
ARCH_IMAGE="${BASE_IMAGE}:${GIT_TAG}-${ARCH}-${DEBIAN_VERSION}"
MULTIARCH_IMAGE="${BASE_IMAGE}:${GIT_TAG}"



# To get latest released, cut a release on https://github.com/pi-hole/docker-pi-hole/releases (manually gated for quality control)
latest_tag='UNKNOWN'
if ! latest_tag=$(curl -sI https://github.com/pi-hole/docker-pi-hole/releases/latest | grep --color=never -i Location: | awk -F / '{print $NF}' | tr -d '[:cntrl:]'); then
    print "Failed to retrieve latest docker-pi-hole release metadata"
else
    if [[ "${GIT_TAG}" == "${latest_tag}" ]] ; then
        LATEST_IMAGE="${BASE_IMAGE}:latest"
    fi
fi


set +a
