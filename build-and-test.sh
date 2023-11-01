#!/usr/bin/env bash
set -e -u -o pipefail
set -x

ALPINE="3.21"
DKR="27.5.1"
DKR="28.0.0"

trap -p stop 1 2 3 6

stop() {
	docker stop pipenv
	docker container rm pipenv
}

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

enter=""
if [[ "${1:-''}" == "enter" ]]; then
	enter="-it --entrypoint=sh"
fi

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed "s/\//-/g")
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || true)
GIT_TAG="${GIT_TAG:-$GIT_BRANCH}"
#PLATFORM="linux/arm64"
PLATFORM="${PLATFORM:-linux/amd64}"
# generate and build dockerfile
docker buildx build --load --platform=${PLATFORM} --build-arg alpine_version="${ALPINE}" --build-arg docker_version="${DKR}" --tag image_pipenv --file test/Dockerfile test/
docker run --rm \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--volume "$(pwd):/$(pwd)" \
	--workdir "$(pwd)" \
	--env PIPENV_CACHE_DIR="$(pwd)/.pipenv" \
	--env GIT_TAG="${GIT_TAG}" \
	--env PY_COLORS=1 \
	--env TARGETPLATFORM="${PLATFORM}" \
	--name pipenv \
	${enter} image_pipenv