ARG PYVER=3.11
FROM python:${PYVER}-bookworm
ARG PYVER=3.11
ARG DC_VERSION=2.21.0
# Only works for docker CLIENT (bind mounted socket)
COPY --from=docker:24.0.7 /usr/local/bin/docker /usr/local/bin/
COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx

ARG packages
RUN apt-get update && \
    apt-get --no-install-recommends install -y python3 python3-pip python3-dev pipenv curl gcc make \
        libffi-dev libssl-dev ${packages} \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir -U pip pipenv \
    && docker buildx install

RUN echo "Downloading docker-compose-$(uname -s)-$(uname -m) version ${DC_VERSION}" && \
    curl --proto "https" -L https://github.com/docker/compose/releases/download/v${DC_VERSION}/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

COPY ./cmd.sh /usr/local/bin/
COPY Pipfile* /root/
WORKDIR /root

RUN pipenv install --system && pipenv lock \
    && sed -i 's|/bin/sh|/bin/bash|g' /usr/local/lib/python${PYVER}/site-packages/testinfra/backend/docker.py

RUN echo "set -ex && cmd.sh && \$@" > /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/cmd.sh
ENTRYPOINT entrypoint.sh
CMD cmd.sh
