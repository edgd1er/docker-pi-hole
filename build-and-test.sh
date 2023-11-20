#!/usr/bin/env bash
set -e -u -o pipefail
#set -x
enter=""

#Functions
digDomains() {
  if [[ -f domain_list ]]; then
    n=0
    for d in $(<domain_list); do
      ((n += 1))
      printf "%s : %s = %s\n" "${n}" "${d}" "$(dig +short ${d} @${1:-127.1.1.1} | tr '\n' ' ')"
      sleep ,2
    done
  else
    echo "domain_list not found"
  fi
}

if [[ "${1:-''}" == "dig" ]]; then
  digDomains ${2:-127.1.1.1}
  exit
fi

if [[ "${1:-''}" == "enter" ]]; then
  enter="-it --entrypoint=bash"
fi

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed "s/\//-/g")
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || true)
GIT_TAG="${GIT_TAG:-$GIT_BRANCH}"
DC_VERSION=2.26.0
BX_VERSION=0.14.0
DEBIAN_VERSION=bookworm-slim
PLATFORM="${PLATFORM:-linux/amd64}"

# generate and build dockerfile
docker buildx build --progress plain --build-arg DC_VERSION=${DC_VERSION} --build-arg=${BX_VERSION} --tag image_pipenv --file test/Dockerfile test/
docker run --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume "$(pwd):/$(pwd)" \
  --workdir "$(pwd)" \
  --env PIPENV_CACHE_DIR="$(pwd)/.pipenv" \
  --env DEBIAN_VERSION=${DEBIAN_VERSION} \
  --env GIT_TAG="${GIT_TAG}" \
  --env PY_COLORS=1 \
  --env TARGETPLATFORM="${PLATFORM}" \
  ${enter} image_pipenv
#docker cp image_pipenv:/root/Pipfile.lock test/
#docker rm image_pipenv
