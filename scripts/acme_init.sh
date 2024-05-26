#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [ "${DEBUG_SCRIPT:-}" == "TRUE" ]; then
  set -x
fi
shopt -u nocasematch

echo "acme_init.sh script started at $(date)"

HOMELAB_PACKAGES_CONFIG="${HOMELAB_PACKAGES_CONFIG_FOLDER:-~/homelab-packages-config}"

# note: unifi is running ssl cert updates on its own

# general setup
export CERT_DNS="dns_cf"
export ACME_DIRECTORY_RESOURCE="letsencrypt"
export ACME_HOME="${HOMELAB_PACKAGES_CONFIG}/acme.sh"
export GLOBAL_ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/cf.env"

# synology nas
if [ "${INIT_SYNOLOGY^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for Synology 1 ---"
  export CERT_DOMAIN_1="nas1.${ROOT_DOMAIN}"
  export CERT_DOMAIN_2="synology1.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/syno.env"
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" ${ADDITIONAL_ARGUMENTS:-}
  bash scripts/acme_run.sh --deploy --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --deploy-hook synology_dsm --insecure
  echo "--- Finished certificate renewal setup for Synology 1 ---"
fi

# fritz!box
if [ "${INIT_FRITZ_BOX^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for Fritz!Box ---"
  export CERT_DOMAIN_1="fritz-box.${ROOT_DOMAIN}"
  export CERT_DOMAIN_2="router.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/fritz-box.env"
  # fritzbox does not support ecc keys, only rsa keys
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" --keylength 4096 ${ADDITIONAL_ARGUMENTS:-}
  bash scripts/acme_run.sh --deploy --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --deploy-hook fritzbox --insecure
  echo "--- Finished certificate renewal setup for Fritz!Box ---"
fi

# adguard
if [ "${INIT_ADGUARD^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for Adguard 1 ---"
  export CERT_DOMAIN_1="adguard1.${ROOT_DOMAIN}"
  export CERT_DOMAIN_2="dns1.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/adguard.env"
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" ${ADDITIONAL_ARGUMENTS:-} \
    --post-hook "set -x && cp \$CERT_KEY_PATH /volume_base_directory/adguard/conf/certs/cert.key && cp \$CERT_PATH /volume_base_directory/adguard/conf/certs/cert.cer && chown -R ${ADGUARD_USER}:${DOCKER_USER_GROUP} /volume_base_directory/adguard/conf/certs"
  echo "--- Finished certificate renewal setup for Adguard 1 ---"
fi

# uptime-kuma
if [ "${INIT_UPTIME_KUMA^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for Uptime Kuma ---"
  export CERT_DOMAIN_1="uptime.${ROOT_DOMAIN}"
  export CERT_DOMAIN_2="status.${ROOT_DOMAIN}"
  export CERT_DOMAIN_3="health.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/uptime-kuma.env"
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --domain "${CERT_DOMAIN_3}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" ${ADDITIONAL_ARGUMENTS:-} \
    --post-hook "set -x && cp \$CERT_KEY_PATH /volume_base_directory/uptime-kuma/cert/cert.key && cp \$CERT_PATH /volume_base_directory/uptime-kuma/cert/cert.cer && chown -R ${UPTIME_KUMA_USER}:${DOCKER_USER_GROUP} /volume_base_directory/uptime-kuma/cert"
  echo "--- Finished certificate renewal setup for Uptime Kuma ---"
fi

# homebridge
if [ "${INIT_HOMEBRIDGE^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for Homebridge ---"
  export CERT_DOMAIN="homebridge.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/homebridge.env"
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" ${ADDITIONAL_ARGUMENTS:-}
  echo "--- Finished certificate renewal setup for Homebridge ---"
fi

# n8n
if [ "${INIT_N8N^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for N8N ---"
  export CERT_DOMAIN="n8n.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/n8n.env"
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" ${ADDITIONAL_ARGUMENTS:-}
  echo "--- Finished certificate renewal setup for N8N ---"
fi

# node-red
if [ "${INIT_NODE_RED^^}" == "TRUE" ]; then
  echo "--- Initialize certificate renewal setup for Node-RED ---"
  export CERT_DOMAIN_1="node-red.${ROOT_DOMAIN}"
  export CERT_DOMAIN_2="automation.${ROOT_DOMAIN}"
  export ENV_FILE="${HOMELAB_PACKAGES_CONFIG}/env_files/node-red.env"
  bash scripts/acme_run.sh --issue --domain "${CERT_DOMAIN_1}" --domain "${CERT_DOMAIN_2}" --dns "${CERT_DNS}" --server "${ACME_DIRECTORY_RESOURCE}" ${ADDITIONAL_ARGUMENTS:-} \
    --post-hook "set -x && cp \$CERT_KEY_PATH /volume_base_directory/node-red/cert/cert.key && cp \$CERT_PATH /volume_base_directory/node-red/cert/cert.cer && chown -R ${NODE_RED_USER}:${DOCKER_USER_GROUP} /volume_base_directory/node-red/cert"
  echo "--- Finished certificate renewal setup for Node-RED ---"
fi

echo "acme_init.sh script finished successfully at $(date)"
