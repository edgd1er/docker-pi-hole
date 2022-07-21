ARG DEBIAN_VERSION=bullseye-slim
FROM debian:${DEBIAN_VERSION} as base_image

ENV phpver="php"
ARG aptCacher

#hadolint ignore=DL3008
RUN echo "Buidling pihole base ${DEBIAN_VERSION}" \
    && if [ -n "${aptCacher:-''}" ]; then printf "Acquire::http::Proxy \"http://%s:3142\";" "${aptCacher}">/etc/apt/apt.conf.d/01proxy \
    && printf "Acquire::https::Proxy \"http://%s:3142\";" "${aptCacher}">>/etc/apt/apt.conf.d/01proxy ; fi \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates tar \
    curl procps xz-utils dnsutils vim cron curl iputils-ping psmisc sudo unzip idn2 sqlite3 libcap2-bin dns-root-data \
    libcap2 lighttpd lighttpd-mod-openssl php-common php-cgi php-sqlite3 php-xml php-intl php-json whiptail grep git \
    iproute2 netcat-openbsd \
    && if [ -f /etc/apt/apt.conf.d/01proxy ]; then rm -f /etc/apt/apt.conf.d/01proxy; fi \
    && rm -rf /var/lib/apt/lists/*

FROM base_image

ARG PIHOLE_DOCKER_TAG
ENV PIHOLE_DOCKER_TAG="${PIHOLE_DOCKER_TAG}"
ARG TARGETPLATFORM
ARG BUILDPLATFORM

ARG S6_OVERLAY_VERSION=3.1.2.1

#ENV S6_VERBOSITY=3
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000
ENV S6_GLOBAL_PATH=${PATH}:/opt/pihole;
ENV PATH=${S6_GLOBAL_PATH}
ENV PIHOLE_INSTALL=/etc/.pihole/automated\ install/basic-install.sh
ENV S6_SVC_TIMEOUT=2500

#add apt-cacher setting if present:
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
#hadolint ignore=DL3008

# php config start passes special ENVs into
ARG PHP_ENV_CONFIG
ENV PHP_ENV_CONFIG=/etc/lighttpd/conf-enabled/15-fastcgi-php.conf
ARG PHP_ERROR_LOG
ENV PHP_ERROR_LOG=/var/log/lighttpd/error-pihole.log
ENV FTLCONF_LOCAL_IPV4=0.0.0.0
ENV FTL_CMD=no-daemon
ENV DNSMASQ_USER=pihole
ENV S6_LOGGING=0
ENV S6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=1
ENV PATH=/:/opt/pihole:${PATH}

# IPv6 disable flag for networks/devices that do not support it
ENV IPv6=True

EXPOSE 53 53/udp
EXPOSE 67/udp
EXPOSE 80

HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1

WORKDIR /usr/bin/
COPY ./s6/debian-root /
COPY ./s6/service /usr/local/bin/service

# Add PADD to the container, too.
ADD https://raw.githubusercontent.com/pi-hole/PADD/master/padd.sh /padd.sh
#RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
RUN echo "Buidling pihole version ${PIHOLE_DOCKER_TAG} with s6 ${S6_OVERLAY_VERSION} for ${TARGETPLATFORM}" \
    && find /etc/s6-overlay -type f -exec chmod +x {} \; \
    && bash -x /usr/local/bin/install.sh 2>&1 \
    && sed -i "s#once quiet#once \>/var/log/pihole/pihole_flush.log#" /etc/cron.d/pihole \
    # allow components checks when in container.
    && sed -i '/$docker_update = checkUpdate($docker_current,$docker_latest):/a \n   $core_update = checkUpdate($core_current, $core_latest);\n     $web_update = checkUpdate($web_current, $web_latest);\n    $FTL_update = checkUpdate($FTL_current, $FTL_latest); ' /var/www/html/admin/scripts/pi-hole/php/update_checker.php \
    # && sed -i "s# \* \* 7# * * *#" /etc/cron.d/pihole \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /padd.sh \
    && sleep 1 \
    && grep -P "(flush|update)" /etc/cron.d/pihole

ENTRYPOINT [ "/s6-init" ]