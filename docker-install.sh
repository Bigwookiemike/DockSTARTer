#!/bin/bash

# # Root check
if [[ ${EUID} -ne 0 ]]; then
    echo "Please run this script as root."
    exit 0
fi

# # Updates and dependencies
apt-get update
if [[ ${CI} != true ]] && [[ ${TRAVIS} != true ]]; then
    apt-get -y dist-upgrade
fi
apt-get -qq install curl git grep
apt-get -y autoremove
apt-get -y autoclean

# # Common
source "./scripts/common.sh"

if [[ ${CI} == true ]] && [[ ${TRAVIS} == true ]]; then
    GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# # https://github.com/mikefarah/yq
AVAILABLE_YQ=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
if [[ ${ARCH} == "arm64" ]] || [[ ${ARCH} == "arm" ]]; then
    curl -H "${GH_HEADER}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_arm" -o /usr/local/bin/yq
fi
if [[ ${ARCH} == "amd64" ]]; then
    curl -H "${GH_HEADER}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_amd64" -o /usr/local/bin/yq
fi
chmod +x /usr/local/bin/yq

# # https://github.com/docker/docker-install
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# # https://docs.docker.com/machine/completion/
AVAILABLE_MACHINE_COMPLETION=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/docker/machine/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
curl -H "${GH_HEADER}" -L "https://raw.githubusercontent.com/docker/machine/${AVAILABLE_MACHINE_COMPLETION}/contrib/completion/bash/docker-machine.bash" -o /etc/bash_completion.d/docker-machine

# # https://docs.docker.com/compose/install/ OR https://github.com/javabean/arm-compose
if [[ ${ARCH} == "arm64" ]] || [[ ${ARCH} == "arm" ]]; then
    AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/javabean/arm-compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    curl -H "${GH_HEADER}" -L "https://github.com/javabean/arm-compose/releases/download/${AVAILABLE_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
fi
if [[ ${ARCH} == "amd64" ]]; then
    AVAILABLE_COMPOSE=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    curl -H "${GH_HEADER}" -L "https://github.com/docker/compose/releases/download/${AVAILABLE_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
fi
chmod +x /usr/local/bin/docker-compose

# # https://docs.docker.com/compose/completion/
AVAILABLE_COMPOSE_COMPLETION=$(curl -H "${GH_HEADER}" -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
curl -H "${GH_HEADER}" -L "https://raw.githubusercontent.com/docker/compose/${AVAILABLE_COMPOSE_COMPLETION}/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose

# # https://docs.docker.com/install/linux/linux-postinstall/
groupadd docker
usermod -aG docker "${USER}"
[[ ${ISSYSTEMD} == true ]] && systemctl enable docker
echo "Please reboot your system."
