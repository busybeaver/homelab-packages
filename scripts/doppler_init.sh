#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "doppler_init.sh script started at $(date)"

# renovate: datasource=github-releases depName=DopplerHQ/cli versioning=loose
DOPPLER_VERSION="3.68.0"

DOPPLER_TEMP_INSTALL_DIRECTORY=$(mktemp -d)
trap 'rm -rf "${DOPPLER_TEMP_INSTALL_DIRECTORY}"' EXIT

cd "${DOPPLER_TEMP_INSTALL_DIRECTORY}"
echo "Downloading Doppler CLI v${DOPPLER_VERSION}..."
curl -Ls --proto "=https" --tlsv1.3 --retry 3 "https://github.com/DopplerHQ/cli/releases/download/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION}_linux_amd64.tar.gz" >doppler_linux_amd64.tar.gz
tar -xvzf doppler_linux_amd64.tar.gz

echo "Installing Doppler CLI..."
sudo chmod a+x "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler"
sudo chown root:root "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler"

# Verify binary works before moving
if ! "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler" --version; then
    echo "Error: Downloaded Doppler binary is not working"
    exit 1
fi

DOPPLER_INSTALL_PATH="${DOPPLER_INSTALL_PATH:-/usr/local/bin/doppler}"
sudo mv "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler" "${DOPPLER_INSTALL_PATH}"

echo "doppler_init.sh script finished successfully at $(date)"
