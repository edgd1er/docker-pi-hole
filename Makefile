SHELL=/bin/bash
DOCKER=/usr/bin/docker
DOCKER_IMAGE_NAME=edgd1er/pihole
PTF=linux/amd64
DKRFILE=./Dockerfile
S6_VERSION=v2.2.0.3
IMAGE=pihole
DUSER=edgd1er
#PIHOLE_VERSION=$(shell date '+%YY.%mm')-buster
PIHOLE_VERSION=latest
PROGRESS=AUTO
WHERE=--load
CACHE=
aptCacher:=$(shell ifconfig wlp2s0 | awk '/inet /{print $$2}')

default: build
all: lint build test

help:


lint:
	$(DOCKER) run --rm -i hadolint/hadolint < ./Dockerfile

build:
	$(DOCKER) buildx build $(WHERE) $(CACHE) --platform $(PTF) -f $(DKRFILE) --build-arg NAME=$(NAME) \
    --progress $(PROGRESS) --build-arg aptCacher=$(aptCacher) --build-arg S6_VERSION=${S6_VERSION} \
    --build-arg PIHOLE_VERSION=$(PIHOLE_VERSION) -t ${DUSER}/$(IMAGE) .

push:
	$(DOCKER) login
	$(DOCKER) push $(DOCKER_IMAGE_NAME)

clean:
	$(DOCKER) images -qf dangling=true | xargs --no-run-if-empty $(DOCKER) rmi
	$(DOCKER) volume ls -qf dangling=true | xargs --no-run-if-empty $(DOCKER) volume rm
