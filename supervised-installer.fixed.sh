#!/usr/bin/env bash
set -e

declare -a MISSING_PACKAGES

function info { echo -e "\e[32m[info] $*\e[39m"; }
function warn  { echo -e "\e[33m[warn] $*\e[39m"; }
function error { echo -e "\e[31m[error] $*\e[39m"; exit 1; }

info ""
info "This script is taken from the official"
info ""
info "Home Assistant Supervised script available at"
info ""
info "https://github.com/home-assistant/supervised-installer"
info ""

sleep 10

ARCH=$(uname -m)

IP_ADDRESS=$(hostname -I | awk '{ print $1 }')

BINARY_DOCKER=/usr/bin/docker

DOCKER_REPO=homeassistant

SERVICE_DOCKER="docker.service"
SERVICE_NM="NetworkManager.service"

FILE_DOCKER_CONF="/etc/docker/daemon.json"
FILE_INTERFACES="/etc/network/interfaces"
FILE_NM_CONF="/etc/NetworkManager/NetworkManager.conf"
FILE_NM_CONNECTION="/etc/NetworkManager/system-connections/default"

URL_RAW_BASE="https://github.com/xvrfr/homeassistant/raw/main/files/hassio"
URL_VERSION="https://version.home-assistant.io/stable.json"
URL_BIN_APPARMOR="${URL_RAW_BASE}/hassio-apparmor"
URL_BIN_HASSIO="${URL_RAW_BASE}/hassio-supervisor"
URL_DOCKER_DAEMON="${URL_RAW_BASE}/docker_daemon.json"
URL_HA="https://github.com/xvrfr/homeassistant/raw/main/files/hassio/ha_i386"
URL_INTERFACES="${URL_RAW_BASE}/interfaces"
URL_NM_CONF="${URL_RAW_BASE}/NetworkManager.conf"
URL_NM_CONNECTION="${URL_RAW_BASE}/system-connection-default"
URL_SERVICE_APPARMOR="${URL_RAW_BASE}/hassio-apparmor.service"
URL_SERVICE_HASSIO="${URL_RAW_BASE}/hassio-supervisor.service"
URL_APPARMOR_PROFILE="https://version.home-assistant.io/apparmor.txt"

# Check env
command -v systemctl > /dev/null 2>&1 || MISSING_PACKAGES+=("systemd")
command -v nmcli > /dev/null 2>&1 || MISSING_PACKAGES+=("network-manager")
command -v apparmor_parser > /dev/null 2>&1 || MISSING_PACKAGES+=("apparmor")
command -v docker > /dev/null 2>&1 || MISSING_PACKAGES+=("docker")
command -v jq > /dev/null 2>&1 || MISSING_PACKAGES+=("jq")
command -v curl > /dev/null 2>&1 || MISSING_PACKAGES+=("curl")
command -v dbus-daemon > /dev/null 2>&1 || MISSING_PACKAGES+=("dbus")


if [ ! -z "${MISSING_PACKAGES}" ]; then
    warn "The following is missing on the host and needs "
    warn "to be installed and configured before running this script again"
    error "missing: ${MISSING_PACKAGES[@]}"
fi

# Check if Modem Manager is enabled
if systemctl is-enabled ModemManager.service &> /dev/null; then
    warn "ModemManager service is enabled. This might cause issue when using serial devices."
fi

# Detect wrong docker logger config
if [ ! -f "$FILE_DOCKER_CONF" ]; then
  # Write default configuration
  info "Creating default docker daemon configuration $FILE_DOCKER_CONF"
  curl -sL ${URL_DOCKER_DAEMON} > "${FILE_DOCKER_CONF}"
#sudo echo "{" > /etc/docker/daemon.json
#sudo echo "    \"log-driver\":   \"journald\"," >> /etc/docker/daemon.json
#sudo echo "    \"log-level\":       \"error\"," >> /etc/docker/daemon.json
#sudo echo "    \"storage-driver\":   \"overlay2\"" >> /etc/docker/daemon.json
#sudo echo "}" >> /etc/docker/daemon.json
  # Restart Docker service
  info "Restarting docker service"
  systemctl restart "$SERVICE_DOCKER"
else
  STORAGE_DRIVER=$(docker info -f "{{json .}}" | jq -r -e .Driver)
  LOGGING_DRIVER=$(docker info -f "{{json .}}" | jq -r -e .LoggingDriver)
  if [[ "$STORAGE_DRIVER" != "overlay2" ]]; then 
    warn "Docker is using $STORAGE_DRIVER and not 'overlay2' as the storage driver, this is not supported."
  fi
  if [[ "$LOGGING_DRIVER"  != "journald" ]]; then 
    warn "Docker is using $LOGGING_DRIVER and not 'journald' as the logging driver, this is not supported."
  fi
fi

# Check dmesg access
if [[ "$(sysctl --values kernel.dmesg_restrict)" != "0" ]]; then
    info "Fix kernel dmesg restriction"
    echo 0 > /proc/sys/kernel/dmesg_restrict
    echo "kernel.dmesg_restrict=0" >> /etc/sysctl.conf
fi

# Create config for NetworkManager
info "Creating NetworkManager configuration"
curl -sL "${URL_NM_CONF}" > "${FILE_NM_CONF}"
#sudo echo '[main]' > /etc/NetworkManager/NetworkManager.conf
#sudo echo 'dns=default' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo 'plugins=keyfile' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo 'autoconnect-retries-default=0' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo 'rc-manager=file' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo '' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo '[keyfile]' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo 'unmanaged-devices=type:bridge;type:tun;driver:veth' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo '' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo '[logging]' >> /etc/NetworkManager/NetworkManager.conf
#sudo echo 'backend=journal' >> /etc/NetworkManager/NetworkManager.conf

if [ ! -f "$FILE_NM_CONNECTION" ]; then
    curl -sL "${URL_NM_CONNECTION}" > "${FILE_NM_CONNECTION}"
#sudo echo '[connection]' > /etc/NetworkManager/system-connections/default
#sudo echo 'id=Supervisor default' >> /etc/NetworkManager/system-connections/default
#sudo echo 'uuid=b653440a-544a-4e4f-aef5-6c443171c4f8' >> /etc/NetworkManager/system-connections/default
#sudo echo 'type=802-3-ethernet' >> /etc/NetworkManager/system-connections/default
#sudo echo 'llmnr=2' >> /etc/NetworkManager/system-connections/default
#sudo echo 'mdns=2' >> /etc/NetworkManager/system-connections/default
#sudo echo '' >> /etc/NetworkManager/system-connections/default
#sudo echo '[ipv4]' >> /etc/NetworkManager/system-connections/default
#sudo echo 'method=auto' >> /etc/NetworkManager/system-connections/default
#sudo echo '' >> /etc/NetworkManager/system-connections/default
#sudo echo '[ipv6]' >> /etc/NetworkManager/system-connections/default
#sudo echo 'addr-gen-mode=stable-privacy' >> /etc/NetworkManager/system-connections/default
#sudo echo 'method=auto' >> /etc/NetworkManager/system-connections/default

fi

warn "Changes are needed to the /etc/network/interfaces file"
info "If you have modified the network on the host manualy, those can now be overwritten"
info "If you do not overwrite this now you need to manually adjust it later"
info "Do you want to proceed with overwriting the /etc/network/interfaces file? [N/y] "
read answer < /dev/tty

if [[ "$answer" =~ "y" ]] || [[ "$answer" =~ "Y" ]]; then
    info "Replacing /etc/network/interfaces"
     curl -sL "${URL_INTERFACES}" > "${FILE_INTERFACES}";
#sudo chmod 777 /etc/network/interfaces
#sudo echo '# This file describes the network interfaces available on your system' > /etc/network/interfaces
#sudo echo '# and how to activate them. For more information, see interfaces(5).' >> /etc/network/interfaces
#sudo echo '' >> /etc/network/interfaces
#sudo echo 'source /etc/network/interfaces.d/*' >> /etc/network/interfaces
#sudo echo '' >> /etc/network/interfaces
#sudo echo '# The loopback network interface' >> /etc/network/interfaces
#sudo echo 'auto lo' >> /etc/network/interfaces
#sudo echo 'iface lo inet loopback' >> /etc/network/interfaces
#sudo echo '' >> /etc/network/interfaces
#sudo echo '#auto enp1s0' >> /etc/network/interfaces
#sudo echo '#iface enp1s0 inet dhcp' >> /etc/network/interfaces
#sudo echo '' >> /etc/network/interfaces
#sudo echo '#auto wlp2s0' >> /etc/network/interfaces
#sudo echo '#iface wlp2s0 inet dhcp' >> /etc/network/interfaces

fi

info "Restarting NetworkManager"
systemctl restart "${SERVICE_NM}"

# Parse command line parameters
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in
        -m|--machine)
            MACHINE=$2
            shift
            ;;
        -d|--data-share)
            DATA_SHARE=$2
            shift
            ;;
        -p|--prefix)
            PREFIX=$2
            shift
            ;;
        -s|--sysconfdir)
            SYSCONFDIR=$2
            shift
            ;;
        *)
            error "Unrecognized option $1"
            ;;
    esac
    shift
done

PREFIX=${PREFIX:-/usr}
SYSCONFDIR=${SYSCONFDIR:-/etc}
DATA_SHARE=${DATA_SHARE:-$PREFIX/share/hassio}
CONFIG=$SYSCONFDIR/hassio.json

# Generate hardware options
case $ARCH in
    "i386" | "i686")
        MACHINE=${MACHINE:=qemux86}
        HASSIO_DOCKER="$DOCKER_REPO/i386-hassio-supervisor"
    ;;
    "x86_64")
        MACHINE=${MACHINE:=qemux86-64}
        HASSIO_DOCKER="$DOCKER_REPO/amd64-hassio-supervisor"
    ;;
    "arm" |"armv6l")
        if [ -z $MACHINE ]; then
            error "Please set machine for $ARCH"
        fi
        HASSIO_DOCKER="$DOCKER_REPO/armhf-hassio-supervisor"
    ;;
    "armv7l")
        if [ -z $MACHINE ]; then
            error "Please set machine for $ARCH"
        fi
        HASSIO_DOCKER="$DOCKER_REPO/armv7-hassio-supervisor"
    ;;
    "aarch64")
        if [ -z $MACHINE ]; then
            error "Please set machine for $ARCH"
        fi
        HASSIO_DOCKER="$DOCKER_REPO/aarch64-hassio-supervisor"
    ;;
    *)
        error "$ARCH unknown!"
    ;;
esac

if [[ ! "${MACHINE}" =~ ^(intel-nuc|odroid-c2|odroid-n2|odroid-xu|qemuarm|qemuarm-64|qemux86|qemux86-64|raspberrypi|raspberrypi2|raspberrypi3|raspberrypi4|raspberrypi3-64|raspberrypi4-64|tinker)$ ]]; then
    error "Unknown machine type ${MACHINE}!"
fi

### Main

# Init folders
if [ ! -d "$DATA_SHARE" ]; then
    mkdir -p "$DATA_SHARE"
fi

if [ ! -d "${PREFIX}/sbin" ]; then
    mkdir -p "${PREFIX}/sbin"
fi

if [ ! -d "${PREFIX}/bin" ]; then
    mkdir -p "${PREFIX}/bin"
fi
# Read infos from web
HASSIO_VERSION=$(curl -s $URL_VERSION | jq -e -r '.supervisor')

##
# Write configuration
cat > "$CONFIG" <<- EOF
{
    "supervisor": "${HASSIO_DOCKER}",
    "machine": "${MACHINE}",
    "data": "${DATA_SHARE}"
}
EOF

##
# Pull supervisor image
info "Install supervisor Docker container"
docker pull "$HASSIO_DOCKER:$HASSIO_VERSION" > /dev/null
docker tag "$HASSIO_DOCKER:$HASSIO_VERSION" "$HASSIO_DOCKER:latest" > /dev/null

##
# Install Hass.io Supervisor
info "Install supervisor startup scripts"
curl -sL ${URL_BIN_HASSIO} > "${PREFIX}/sbin/hassio-supervisor"
#sudo chmod 777 /usr/sbin/hassio-supervisor
#sudo echo '#!/usr/bin/env bash' > /usr/sbin/hassio-supervisor
#sudo echo 'set -e' >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo '# Load configs' >> /usr/sbin/hassio-supervisor
#sudo echo 'CONFIG_FILE=/etc/hassio.json' >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo "SUPERVISOR=\"\$(jq --raw-output '.supervisor' \${CONFIG_FILE})\"" >> /usr/sbin/hassio-supervisor
#sudo echo "MACHINE=\"\$(jq --raw-output '.machine' \${CONFIG_FILE})\"" >> /usr/sbin/hassio-supervisor
#sudo echo "HOMEASSISTANT=\"\$(jq --raw-output '.homeassistant' \${CONFIG_FILE})\"" >> /usr/sbin/hassio-supervisor
#sudo echo "DATA=\"\$(jq --raw-output '.data // \"/usr/share/hassio\"' \${CONFIG_FILE})\"" >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo '# AppArmor Support' >> /usr/sbin/hassio-supervisor
#sudo echo 'if command -v apparmor_parser > /dev/null 2>&1 && grep hassio-supervisor /sys/kernel/security/apparmor/profiles > /dev/null 2>&1; then' >> /usr/sbin/hassio-supervisor
#sudo echo 'APPARMOR="--security-opt apparmor=hassio-supervisor"' >> /usr/sbin/hassio-supervisor
#sudo echo 'else' >> /usr/sbin/hassio-supervisor
#sudo echo 'APPARMOR="--security-opt apparmor:unconfined"' >> /usr/sbin/hassio-supervisor
#sudo echo 'fi' >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo '# Init supervisor' >> /usr/sbin/hassio-supervisor
#sudo echo 'HASSIO_DATA=${DATA}' >> /usr/sbin/hassio-supervisor
#sudo echo "HASSIO_IMAGE_ID=\$(docker inspect --format='{{.Id}}' \"\${SUPERVISOR}\")" >> /usr/sbin/hassio-supervisor
#sudo echo "HASSIO_CONTAINER_ID=\$(docker inspect --format='{{.Image}}' hassio_supervisor || echo \"\")" >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo 'runSupervisor() {' >> /usr/sbin/hassio-supervisor
#sudo echo 'docker rm --force hassio_supervisor || true' >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo '# shellcheck disable=SC2086' >> /usr/sbin/hassio-supervisor
#sudo echo 'docker run --name hassio_supervisor \' >> /usr/sbin/hassio-supervisor
#sudo echo '--privileged \' >> /usr/sbin/hassio-supervisor
#sudo echo '$APPARMOR \' >> /usr/sbin/hassio-supervisor
#sudo echo '--security-opt seccomp=unconfined \' >> /usr/sbin/hassio-supervisor
#sudo echo '-v /run/docker.sock:/run/docker.sock \' >> /usr/sbin/hassio-supervisor
#sudo echo '-v /run/dbus:/run/dbus \' >> /usr/sbin/hassio-supervisor
#sudo echo '-v "${HASSIO_DATA}":/data \' >> /usr/sbin/hassio-supervisor
#sudo echo '-e SUPERVISOR_SHARE="${HASSIO_DATA}" \' >> /usr/sbin/hassio-supervisor
#sudo echo '-e SUPERVISOR_NAME=hassio_supervisor \' >> /usr/sbin/hassio-supervisor
#sudo echo '-e SUPERVISOR_MACHINE="${MACHINE}" \' >> /usr/sbin/hassio-supervisor
#sudo echo '-e HOMEASSISTANT_REPOSITORY="${HOMEASSISTANT}" \' >> /usr/sbin/hassio-supervisor
#sudo echo '${SUPERVISOR}' >> /usr/sbin/hassio-supervisor
#sudo echo '}' >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor
#sudo echo '# Run supervisor' >> /usr/sbin/hassio-supervisor
#sudo echo 'mkdir -p "${HASSIO_DATA}"' >> /usr/sbin/hassio-supervisor
#sudo echo '([ "${HASSIO_IMAGE_ID}" = "${HASSIO_CONTAINER_ID}" ] && docker start --attach hassio_supervisor) || runSupervisor' >> /usr/sbin/hassio-supervisor
#sudo echo '' >> /usr/sbin/hassio-supervisor

curl -sL ${URL_SERVICE_HASSIO} > "${SYSCONFDIR}/systemd/system/hassio-supervisor.service"
#sudo chmod 777 /etc/systemd/system/hassio-supervisor.service
#sudo echo "[Unit]" > /etc/systemd/system/hassio-supervisor.service
#sudo echo "Description=Hass.io supervisor" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "Requires=docker.service" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "After=docker.service dbus.socket" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "[Service]" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "Type=simple" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "Restart=always" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "RestartSec=5s" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "ExecStartPre=-/usr/bin/docker stop hassio_supervisor" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "ExecStart=/usr/sbin/hassio-supervisor" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "ExecStop=-/usr/bin/docker stop hassio_supervisor" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "[Install]" >> /etc/systemd/system/hassio-supervisor.service
#sudo echo "WantedBy=multi-user.target" >> /etc/systemd/system/hassio-supervisor.service

sed -i "s,%%HASSIO_CONFIG%%,${CONFIG},g" "${PREFIX}"/sbin/hassio-supervisor
sed -i -e "s,%%BINARY_DOCKER%%,${BINARY_DOCKER},g" \
       -e "s,%%SERVICE_DOCKER%%,${SERVICE_DOCKER},g" \
       -e "s,%%BINARY_HASSIO%%,${PREFIX}/sbin/hassio-supervisor,g" \
       "${SYSCONFDIR}/systemd/system/hassio-supervisor.service"

chmod a+x "${PREFIX}/sbin/hassio-supervisor"
systemctl enable hassio-supervisor.service > /dev/null 2>&1;

#
# Install Hass.io AppArmor
info "Install AppArmor scripts"
mkdir -p "${DATA_SHARE}/apparmor"
curl -sL ${URL_BIN_APPARMOR} > "${PREFIX}/sbin/hassio-apparmor"
#sudo echo '#!/bin/sh' > /usr/sbin/hassio-apparmor
#sudo echo "set -e" >> /usr/sbin/hassio-apparmor
#sudo echo "# Load configs" >> /usr/sbin/hassio-apparmor
#sudo echo "CONFIG_FILE=/etc/hassio.json" >> /usr/sbin/hassio-apparmor
#sudo echo "# Read configs" >> /usr/sbin/hassio-apparmor
#sudo echo "DATA=\"\$(jq --raw-output '.data // \"/usr/share/hassio\"' \${CONFIG_FILE})\"" >> /usr/sbin/hassio-apparmor
#sudo echo "PROFILES_DIR=\"\${DATA}/apparmor\"" >> /usr/sbin/hassio-apparmor
#sudo echo "CACHE_DIR=\"\${PROFILES_DIR}/cache\"" >> /usr/sbin/hassio-apparmor
#sudo echo "REMOVE_DIR=\"\${PROFILES_DIR}/remove\"" >> /usr/sbin/hassio-apparmor
#sudo echo "# Exists AppArmor" >> /usr/sbin/hassio-apparmor
#sudo echo "if ! command -v apparmor_parser > /dev/null 2>&1; then" >> /usr/sbin/hassio-apparmor
#sudo echo 'echo "[Warning]: No apparmor_parser on host system!"' >> /usr/sbin/hassio-apparmor
#sudo echo "exit 0" >> /usr/sbin/hassio-apparmor
#sudo echo "fi" >> /usr/sbin/hassio-apparmor
#sudo echo "# Check folder structure" >> /usr/sbin/hassio-apparmor
#sudo echo "mkdir -p \"\${PROFILES_DIR}\"" >> /usr/sbin/hassio-apparmor
#sudo echo "mkdir -p \"\${CACHE_DIR}\"" >> /usr/sbin/hassio-apparmor
#sudo echo "mkdir -p \"\${REMOVE_DIR}\"" >> /usr/sbin/hassio-apparmor
#sudo echo "# Load/Update exists/new profiles" >> /usr/sbin/hassio-apparmor
#sudo echo "for profile in \"\${PROFILES_DIR}\"/*; do" >> /usr/sbin/hassio-apparmor
#sudo echo "if [ ! -f \"\${profile}\" ]; then" >> /usr/sbin/hassio-apparmor
#sudo echo "continue" >> /usr/sbin/hassio-apparmor
#sudo echo "fi" >> /usr/sbin/hassio-apparmor
#sudo echo "# Load Profile" >> /usr/sbin/hassio-apparmor
#sudo echo "if ! apparmor_parser -r -W -L \"\${CACHE_DIR}\" \"\${profile}\"; then" >> /usr/sbin/hassio-apparmor
#sudo echo "echo \"[Error]: Can't load profile \${profile}\"" >> /usr/sbin/hassio-apparmor
#sudo echo "fi" >> /usr/sbin/hassio-apparmor
#sudo echo "done" >> /usr/sbin/hassio-apparmor
#sudo echo "# Cleanup old profiles" >> /usr/sbin/hassio-apparmor
#sudo echo "for profile in \"\${REMOVE_DIR}\"/*; do" >> /usr/sbin/hassio-apparmor
#sudo echo "if [ ! -f \"\${profile}\" ]; then" >> /usr/sbin/hassio-apparmor
#sudo echo "continue" >> /usr/sbin/hassio-apparmor
#sudo echo "fi" >> /usr/sbin/hassio-apparmor
#sudo echo "# Unload Profile" >> /usr/sbin/hassio-apparmor
#sudo echo "if apparmor_parser -R -W -L \"\${CACHE_DIR}\" \"\${profile}\"; then" >> /usr/sbin/hassio-apparmor
#sudo echo "if rm -f \"\${profile}\"; then" >> /usr/sbin/hassio-apparmor
#sudo echo "continue" >> /usr/sbin/hassio-apparmor
#sudo echo "fi" >> /usr/sbin/hassio-apparmor
#sudo echo "fi" >> /usr/sbin/hassio-apparmor
#sudo echo "echo \"[Error]: Can't remove profile \${profile}\"" >> /usr/sbin/hassio-apparmor
#sudo echo "done" >> /usr/sbin/hassio-apparmor

curl -sL ${URL_SERVICE_APPARMOR} > "${SYSCONFDIR}/systemd/system/hassio-apparmor.service"
#sudo echo "[Unit]" > /etc/systemd/system/hassio-apparmor.service
#sudo echo "Description=Hass.io AppArmor" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "Wants=hassio-supervisor.service" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "Before=docker.service hassio-supervisor.service" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "[Service]" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "Type=oneshot" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "RemainAfterExit =true" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "ExecStart=/usr/sbin/hassio-apparmor" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "[Install]" >> /etc/systemd/system/hassio-apparmor.service
#sudo echo "WantedBy=multi-user.target" >> /etc/systemd/system/hassio-apparmor.service

curl -sL ${URL_APPARMOR_PROFILE} > "${DATA_SHARE}/apparmor/hassio-supervisor"

sed -i "s,%%HASSIO_CONFIG%%,${CONFIG},g" "${PREFIX}/sbin/hassio-apparmor"
sed -i -e "s,%%SERVICE_DOCKER%%,${SERVICE_DOCKER},g" \
    -e "s,%%HASSIO_APPARMOR_BINARY%%,${PREFIX}/sbin/hassio-apparmor,g" \
    "${SYSCONFDIR}/systemd/system/hassio-apparmor.service"

chmod a+x "${PREFIX}/sbin/hassio-apparmor"
systemctl enable hassio-apparmor.service > /dev/null 2>&1;
systemctl start hassio-apparmor.service


##
# Init system
info "Start Home Assistant Supervised"
systemctl start hassio-supervisor.service

##
# Setup CLI
info "Installing the 'ha' cli"
curl -sL ${URL_HA} > "${PREFIX}/bin/ha"
chmod a+x "${PREFIX}/bin/ha"

info
info "Home Assistant supervised is now installed"
info "First setup will take some time, when it's ready you can reach it here:"
info "http://${IP_ADDRESS}:8123"
info
