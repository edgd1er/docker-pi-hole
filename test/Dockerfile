ARG alpine_version="3.22"
ARG docker_version="28.2.2"

#FROM docker:28.2.2-alpine3.22
FROM docker:${docker_version}-cli-alpine${alpine_version}

COPY --chmod=0755 ./cmd.sh /usr/local/bin/cmd.sh
COPY requirements.txt /root/
WORKDIR /root

RUN apk add --no-cache \
    python3-dev \
    py3-pip \
    curl \
    && pip3 install --break-system-packages --no-cache-dir -U pip  \
    && pip3 install --break-system-packages --no-cache-dir -r requirements.txt \
    # Replace hardcoded /bin/sh with /bin/bash in testinfra docker backend
    # see https://github.com/pytest-dev/pytest-testinfra/issues/582 and similar issues
    && pythonversion=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))') \
    && sed -i 's|/bin/sh|/bin/bash|g' /usr/lib/python${pythonversion}/site-packages/testinfra/backend/docker.py

SHELL ["/bin/sh", "-c"]
CMD ["cmd.sh"]
