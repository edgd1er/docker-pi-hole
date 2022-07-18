#!/usr/bin/env bash
set -eux

docker build --tag pihole:${GIT_TAG} --no-cache src/
docker images

# TODO: Add junitxml output and have something consume it
# 2 parallel max b/c race condition with docker fixture (I think?)
py.test -vv -n 2 ./test/tests/
