#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "update_docker_socks.sh script started at $(date)"

# change group of the docker.sock, so selected users can access/use it properly and without user elevation
DOCKER_SOCK="/var/run/docker.sock"
DOCKER_GROUP="docker-sock-users"

if [[ -S "${DOCKER_SOCK}" ]]; then
    echo "Changing group of ${DOCKER_SOCK} to ${DOCKER_GROUP}"
    sudo chgrp "${DOCKER_GROUP}" "${DOCKER_SOCK}"
else
    echo "Error: ${DOCKER_SOCK} is not a socket or does not exist"
    exit 1
fi

echo "update_docker_socks.sh script finished successfully at $(date)"
