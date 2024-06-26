#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [ "${DEBUG_SCRIPT:-}" == "TRUE" ]; then
  set -x
fi
shopt -u nocasematch

echo "doppler_init.sh script started at $(date)"

# renovate: datasource=github-releases depName=DopplerHQ/cli versioning=loose
DOPPLER_VERSION="3.68.0"

DOPPLER_TEMP_INSTALL_DIRECTORY="/tmp/doppler-install"

mkdir "${DOPPLER_TEMP_INSTALL_DIRECTORY}"
cd "${DOPPLER_TEMP_INSTALL_DIRECTORY}"
curl -Ls --proto "=https" --tlsv1.3 --retry 3 "https://github.com/DopplerHQ/cli/releases/download/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION}_linux_amd64.tar.gz" >doppler_linux_arm64.tar.gz
tar -xvzf doppler_linux_arm64.tar.gz

sudo chmod a+x "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler"
sudo chown root:root "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler"
sudo mv "${DOPPLER_TEMP_INSTALL_DIRECTORY}/doppler" /usr/local/bin/doppler

rm -rf "${DOPPLER_TEMP_INSTALL_DIRECTORY}"

echo "doppler_init.sh script finished successfully at $(date)"
