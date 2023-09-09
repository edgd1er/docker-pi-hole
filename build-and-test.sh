#!/usr/bin/env bash
set -e -u -pipefail
set -x
digDomains() {
  if [[ -f domain_list ]]; then
    n=0
    for d in $(<domain_list);do (( n += 1 )); printf "%s : %s = %s\n" "${n}" "${d}" "$(dig +short ${d} @${1:-127.1.1.1} | tr '\n' ' ')"; done
  else
    echo "domain_list not found"
  fi
}

if [[ "$1" == "dig" ]]; then
  set +x
  digDomains 192.168.53.212
  exit
fi

if [[ "$1" == "enter" ]]; then
  enter="-it --entrypoint=sh"
fi

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed "s/\//-/g")
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || true)
GIT_TAG="${GIT_TAG:-$GIT_BRANCH}"
PLATFORM="${PLATFORM:-linux/amd64}"

# generate and build dockerfile
docker buildx build --load --platform=${PLATFORM} --tag image_pipenv --file test/Dockerfile test/
docker run --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume "$(pwd):/$(pwd)" \
  --workdir "$(pwd)" \
  --env PIPENV_CACHE_DIR="$(pwd)/.pipenv" \
  --env GIT_TAG="${GIT_TAG}" \
  --env PY_COLORS=1 \
  ${enter} image_pipenv
