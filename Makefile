.PHONY: help lint build

# Use bash for inline if-statements in arch_patch target
SHELL:=bash

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1
export COMPOSE_DOCKER_CLI_BUILD:=1
S6VER:=3.1.2.0
CACHER:=192.168.53.208
CACHER:=192.168.43.61

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# Fichiers/,/^# Base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

lint: ## stop all containers
	@echo "lint dockerfile ..."
	docker image pull hadolint/hadolint
	docker run -i --rm hadolint/hadolint < Dockerfile

build: ## build image
	@echo -e "build image .. for ${BUILDPLATFORM}"
	## docker-compose -f docker-compose-dev.yml build
	docker buildx build --load --progress plain --build-arg aptCacher=${CACHER} --build-arg NAME=edgd1er/pihole \
	--build-arg S6_OVERLAY_VERSION=${S6VER} --build-arg DEBIAN_VERSION=bullseye-slim --build-arg PIHOLE_DOCKER_TAG=latest \
	--build-arg PIHOLE_BASE=debian:bullseye-slim --build-arg PH_VERBOSE=1 -f src/Dockerfile -t edgd1er/pihole:dev src/

builds6: ## build image
	@echo -e "build image .."
	## docker-compose -f docker-compose-dev.yml build
	docker buildx build --push --progress auto --build-arg aptCacher=${CACHER} --build-arg NAME=edgd1er/pihole \
	--build-arg S6_OVERLAY_VERSION=${S6VER} --build-arg DEBIAN_VERSION=bullseye-slim --build-arg PIHOLE_DOCKER_TAG=latest \
    --build-arg PH_VERBOSE=1 --platform=linux/arm/v7,linux/amd64,linux/arm64,linux/386 \
	-f src/Dockerfile -t edgd1er/pihole:s6v3 src/

version:
	@curl -s "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | jq .name | grep -oP "([0-9]+\.)+[0-9-]+"

up:
	@echo "run container"
	docker-compose up

upbuild:
	docker compose up --build

latest:
	curl -s https://api.github.com/repos/just-containers/s6-overlay/releases/latest | jq .tag_name