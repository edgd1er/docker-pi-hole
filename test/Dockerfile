FROM debian:bookworm-slim
ARG DC_VERSION=2.21.0
ARG BX_VERSION=0.11.2

# Only works for docker CLIENT (bind mounted socket)
COPY --from=docker:24.0.7 /usr/local/bin/docker /usr/local/bin/

ARG packages
RUN apt-get update && \
    apt-get --no-install-recommends install -y python3 python3-pip python3-dev pipenv curl gcc make \
        libffi-dev libssl-dev ${packages} \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Downloading docker-compose-$(uname -s)-$(uname -m) version ${DC_VERSION}" && \
    curl --proto "https" -L https://github.com/docker/compose/releases/download/v${DC_VERSION}/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
RUN /usr/local/bin/docker-compose version

SHELL ["bash","-c"]
RUN mkdir -p /root/.docker/cli-plugins ; \
    s=$(uname -s | tr "[:upper:]" "[:lower:]")  ; m=axm64 ;\
    if [ "x86_64" == "$(uname -m)" ]; then m="amd64"; fi && \
    url=https://github.com/docker/buildx/releases/download/v${BX_VERSION}/buildx-v${BX_VERSION}.${s}-${m} && \
    echo -e "url: $url / \n https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-amd64" ; curl --proto "https" -L ${url}>/root/.docker/cli-plugins/docker-buildx && \
     ls -alh /root/.docker/cli-plugins/docker-buildx
RUN chmod +x /root/.docker/cli-plugins/docker-buildx ; /root/.docker/cli-plugins/docker-buildx version

COPY ./cmd.sh /usr/local/bin/
COPY Pipfile* /root/
WORKDIR /root

RUN pipenv -v install --deploy && pipenv -v install --system \
    && sed -i 's|/bin/sh|/bin/bash|g' /usr/local/lib/python3.11/dist-packages/testinfra/backend/docker.py

RUN echo "set -ex && cmd.sh && \$@" > /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/cmd.sh
ENTRYPOINT entrypoint.sh
CMD cmd.sh