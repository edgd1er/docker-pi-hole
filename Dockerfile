# syntax=docker/dockerfile:1
FROM debian:buster-slim

ARG PIHOLE_TAG
ENV PIHOLE_TAG "${PIHOLE_TAG}"
ARG CORE_VERSION
ENV CORE_VERSION "${CORE_VERSION}"
ARG WEB_VERSION
ENV WEB_VERSION "${WEB_VERSION}"
ARG FTL_VERSION
ENV FTL_VERSION "${FTL_VERSION}"
ARG S6_ARCH
ARG S6_VERSION
ARG aptCacher
ARG PHP_ENV_CONFIG
ENV PHP_ENV_CONFIG="${PHP_ENV_CONFIG:-/etc/lighttpd/conf-enabled/15-fastcgi-php.conf}"
ARG PHP_ERROR_LOG
ENV PHP_ERROR_LOG="${PHP_ERROR_LOG:-/var/log/lighttpd/error.log}"

RUN echo "running on $(dpkg --print-architecture)"
COPY install.sh /usr/local/bin/install.sh
ENV PIHOLE_INSTALL /etc/.pihole/automated\ install/basic-install.sh

RUN if [[ -n ${aptCacher} ]]; then printf "Acquire::http::Proxy \"http://%s:3142\";" "${aptCacher}">/etc/apt/apt.conf.d/01proxy && \
    printf "Acquire::https::Proxy \"http://%s:3142\";" "${aptCacher}">>/etc/apt/apt.conf.d/01proxy ; fi && \
    #echo "Dir::Cache \"\";\nDir::Cache::archives \"\";" | tee /etc/apt/apt.conf.d/02nocache && \
    printf "#/etc/dpkg/dpkg.cfg.d/01_nodoc\n\n# Delete locales\npath-exclude=/usr/share/locale/*\n\n# Delete man pages\npath-exclude=/usr/share/man/*\n\n# Delete docs\npath-exclude=/usr/share/doc/*\npath-include=/usr/share/doc/*/copyright" | tee /etc/dpkg/dpkg.cfg.d/03nodoc && \
    apt-get update && apt-get upgrade -y && bash -ex install.sh 2>&1 && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/* && \
     if [[ -n $aptCacher ]]; then echo "" > /etc/apt/apt.conf.d/01proxy; fi

ENTRYPOINT [ "/s6-init" ]

ADD s6/debian-root /
COPY s6/service /usr/local/bin/service

# php config start passes special ENVs into
ARG PHP_ENV_CONFIG
ENV PHP_ENV_CONFIG "${PHP_ENV_CONFIG:-/etc/lighttpd/conf-enabled/15-fastcgi-php.conf}"
ARG PHP_ERROR_LOG
ENV PHP_ERROR_LOG "${PHP_ERROR_LOG:-/var/log/lighttpd/error.log}"
COPY ./start.sh /
COPY ./bash_functions.sh /

# IPv6 disable flag for networks/devices that do not support it
ENV IPv6 True

EXPOSE 53 53/udp
EXPOSE 67/udp
EXPOSE 80

ENV S6_LOGGING 0
ENV S6_KEEP_ENV 1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2

ENV ServerIP 0.0.0.0
ENV FTL_CMD no-daemon
ENV DNSMASQ_USER root

ENV PATH /opt/pihole:${PATH}

ARG NAME
LABEL image="${NAME}:${PIHOLE_VERSION}_${TARGETPLATFORM}"
ARG MAINTAINER
LABEL maintainer="${MAINTAINER}"
LABEL url="https://www.github.com/pi-hole/docker-pi-hole"

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1

SHELL ["/bin/bash", "-c"]