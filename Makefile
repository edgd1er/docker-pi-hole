.PHONY: help lint build

# Use bash for inline if-statements in arch_patch target
SHELL:=bash

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1
export COMPOSE_DOCKER_CLI_BUILD:=1
CACHER:=$(shell ip -j a | jq -r '.[].addr_info[] | select(.label=="wlp2s0")|.local')
DEBIAN_VERSION:=bookworm-slim

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


lint: ## check syntax
	@echo "lint dockerfile ..."
	docker image pull hadolint/hadolint
	docker run -i --rm hadolint/hadolint < src/Dockerfile

build: ## build image
	@echo -e "build image .. for ${BUILDPLATFORM}" ; \
	## docker-compose -f docker-compose-dev.yml build
	S6VER=$$( grep -oP "(?<=S6_OVERLAY v)[0-9\.]+" README.md ) ;\
	docker buildx build --load --progress plain --build-arg aptCacher=${CACHER} --build-arg NAME=edgd1er/pihole \
	--build-arg S6_OVERLAY_VERSION=${S6VER} --build-arg DEBIAN_VERSION=${DEBIAN_VERSION} --build-arg PIHOLE_DOCKER_TAG=latest \
	--build-arg PH_VERBOSE=1 -f src/Dockerfile -t edgd1er/pihole:dev src/

builds6: ## build image for all platforms
	@echo -e "build image .."
	## docker-compose -f docker-compose-dev.yml build
	S6VER=$$( grep -oP "(?<=S6_OVERLAY v)[0-9\.]+" README.md );\
	docker buildx build --push --progress auto --build-arg aptCacher=${CACHER} --build-arg NAME=edgd1er/pihole \
	--build-arg S6_OVERLAY_VERSION=${S6VER} --build-arg DEBIAN_VERSION=${DEBIAN_VERSION} --build-arg PIHOLE_DOCKER_TAG=latest \
    --build-arg PH_VERBOSE=1 --platform=linux/arm/v7,linux/amd64,linux/arm64,linux/386 \
	-f src/Dockerfile -t edgd1er/pihole:s6v3 src/

version: ## get latest version s6-overlay
	#@curl -s "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" |jq .name | grep -oP "([0-9]+\.)+[0-9-]+"
	@S6VER=$$( grep -oP "(?<=S6_OVERLAY v)[0-9\.]+" README.md ); \
	remoteS6=$$(curl -s "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" |jq -r ".tag_name") ; \
	echo "S6VER local: $${S6VER} remote: $${remoteS6#v*}" ; \
	if [[ $${remoteS6#v*} != $${S6VER} ]]; then echo "S6 Overlay update detected: https://api.github.com/repos/just-containers/s6-overlay/releases/latest" ;\
	  sed -i -E "s/ S6_OVERLAY_VERSION=:.+/ S6_OVERLAY_VERSION=:${remoteS6}/" docker-compose.yml; \
	  sed -i -E "s/ S6_OVERLAY_VERSION=:.+/ S6_OVERLAY_VERSION=:${remoteS6}/" src/Dockerfile; \
	  sed -i -E "s/ S6_OVERLAY_VERSION=:.+/ S6_OVERLAY_VERSION=:${remoteS6}/" README.md; \
	fi

up: ## start container
	@echo "run container"
	docker-compose up

upbuild: ## build and start container
	docker compose up --build