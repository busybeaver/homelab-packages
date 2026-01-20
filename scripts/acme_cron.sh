#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "acme_cron.sh script started at $(date)"

HOMELAB_PACKAGES_CONFIG="${HOMELAB_PACKAGES_CONFIG_FOLDER:-~/homelab-packages-config}"

# general setup
export ACME_HOME="${HOMELAB_PACKAGES_CONFIG}/acme.sh"

# refresh all certificates
bash scripts/acme_run.sh --cron --insecure

echo "acme_cron.sh script finished successfully at $(date)"
