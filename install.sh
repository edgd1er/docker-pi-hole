#!/bin/bash -ex

mkdir -p /etc/pihole/
mkdir -p /var/run/pihole

# Source versions file
source /etc/pi-hole-versions

CORE_REMOTE_REPO=https://github.com/pi-hole/pi-hole
CORE_LOCAL_REPO=/etc/.pihole
WEB_REMOTE_REPO=https://github.com/pi-hole/adminLTE
WEB_LOCAL_REPO=/var/www/html/admin
setupVars=/etc/pihole/setupVars.conf

fetch_release_metadata() {
    local directory="$1"
    local version="$2"
    pushd "$directory"
    git fetch -t
    git remote set-branches origin '*'
    git fetch --depth 10
    #if version number begins with a v, it's a version number
    if [[ $version == v* ]]; then
        git checkout master
        git reset --hard "$version"
    else # else treat it as a branch
        git checkout "$version"
    fi
    popd
}

apt-get update
apt-get install --no-install-recommends -y curl procps ca-certificates git
# curl in armhf-buster's image has SSL issues. Running c_rehash fixes it.
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=923479
c_rehash
ln -s `which echo` /usr/local/bin/whiptail

case $TARGETPLATFORM in
  linux/amd64)
    ARCH=amd64
    ;;
  linux/arm*)
    ARCH=arm
   ;;
esac
PIHOLE_ARCH=${ARCH}
S6OVERLAY_RELEASE="https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${ARCH}.tar.gz"
curl -L -s $S6OVERLAY_RELEASE | tar xvzf - -C /
mv /init /s6-init

# clone the remote repos to their local destinations
git clone "${CORE_REMOTE_REPO}" "${CORE_LOCAL_REPO}"
fetch_release_metadata "${CORE_LOCAL_REPO}" "${CORE_VERSION}"

git clone "${WEB_REMOTE_REPO}" "${WEB_LOCAL_REPO}"
fetch_release_metadata "${WEB_LOCAL_REPO}" "${WEB_VERSION}"

# FTL uses a local version file for the installer to determine which version we want
echo "${FTL_VERSION}" > /etc/pihole/ftlbranch

# Preseed variables to assist with using --unattended install
{
  echo "PIHOLE_INTERFACE=eth0"
  echo "IPV4_ADDRESS=0.0.0.0"
  echo "IPV6_ADDRESS=0:0:0:0:0:0"
  echo "PIHOLE_DNS_1=8.8.8.8"
  echo "QUERY_LOGGING=true"
  echo "INSTALL_WEB_SERVER=true"
  echo "INSTALL_WEB_INTERFACE=true"
  echo "LIGHTTPD_ENABLED=true"
}>> "${setupVars}"
source $setupVars

export USER=pihole

export PIHOLE_SKIP_OS_CHECK=true

ln -s /bin/true /usr/local/bin/service
# Run the installer in unattended mode using the preseeded variables above and --reconfigure so that local repos are not updated
bash -ex "./${PIHOLE_INSTALL}" --unattended --reconfigure
rm /usr/local/bin/service

# IPv6 support for nc openbsd better than traditional
apt-get install -y --force-yes netcat-openbsd

sed -i 's/readonly //g' /opt/pihole/webpage.sh
sed -i '/^WEBPASSWORD/d' /etc/pihole/setupVars.conf

# sed a new function into the `pihole` script just above the `helpFunc()` function for later use.
sed -i $'s/helpFunc() {/unsupportedFunc() {\\\n  echo "Function not supported in Docker images"\\\n  exit 0\\\n}\\\n\\\nhelpFunc() {/g' /usr/local/bin/pihole
# Replace a few of the `pihole` options with calls to `unsupportedFunc`:
# pihole -up / pihole updatePihole
sed -i $'s/)\s*updatePiholeFunc/) unsupportedFunc/g' /usr/local/bin/pihole
# pihole checkout
sed -i $'s/)\s*piholeCheckoutFunc/) unsupportedFunc/g' /usr/local/bin/pihole
# pihole -r / pihole reconfigure
sed -i $'s/)\s*reconfigurePiholeFunc/) unsupportedFunc/g' /usr/local/bin/pihole
# pihole uninstall
sed -i $'s/)\s*uninstallFunc/) unsupportedFunc/g' /usr/local/bin/pihole

# Inject a message into the debug scripts Operating System section to indicate that the debug log comes from a Docker system.
sed -i $'s/echo_current_diagnostic "Operating system"/echo_current_diagnostic "Operating system"\\\n    log_write "${INFO} Pi-hole Docker Container: ${PIHOLE_TAG:-PIHOLE_TAG is unset}"/g' /opt/pihole/piholeDebug.sh

# Inject container tag into web interface footer...
sed -i $"s/<ul class=\"list-unstyled\">/<ul class=\"list-unstyled\">\\n<strong><li>Docker Tag<\/strong> ${PIHOLE_TAG//\//\\/}<\/li>/g" /var/www/html/admin/scripts/pi-hole/php/footer.php
sed -i $"s/<ul class=\"list-inline\">/<strong>Docker Tag<\/strong> ${PIHOLE_TAG//\//\\/}\\n<ul class=\"list-inline\">/g" /var/www/html/admin/scripts/pi-hole/php/footer.php

touch /.piholeFirstBoot

echo 'Docker install successful'
