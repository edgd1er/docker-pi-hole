FROM debian:bookworm-slim
ARG DC_VERSION=2.23.0
# Only works for docker CLIENT (bind mounted socket)
COPY --from=docker:24.0.7 /usr/local/bin/docker /usr/local/bin/

ARG packages
RUN apt-get update && \
    apt-get --no-install-recommends install -y python3 python3-pip python3-dev pipenv curl gcc make \
        libffi-dev libssl-dev ${packages} \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto "https" -L https://github.com/docker/compose/releases/download/v${DC_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

COPY ./cmd.sh /usr/local/bin/
COPY Pipfile* /root/
WORKDIR /root

RUN pipenv -v install --deploy \
    && pipenv -v install --system \
    && sed -i 's|/bin/sh|/bin/bash|g' /usr/local/lib/python3.11/dist-packages/testinfra/backend/docker.py

RUN echo "set -ex && cmd.sh && \$@" > /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/cmd.sh
ENTRYPOINT entrypoint.sh
CMD cmd.sh
