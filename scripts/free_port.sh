#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "free_port.sh script started at $(date)"

# Developed for DSM 6 - 7.x. Tested on DSM 7.2.
# Steps to install
# Save this script in one of your shares
# Edit it according to your requirements
# Backup /usr/syno/share/nginx/ as follows:
# # cd /usr/syno/share/
# # tar cvf ~/nginx.tar nginx
# Run this script as root
# Reboot and ensure everything is still working
# If not, restore the backup and post a comment on this script's gist page
# If it did, schedule it to run as root at boot
#   through Control Panel -> Task Scheduler

# Source: https://gist.github.com/hjbotha/f64ef2e0cd1e8ba5ec526dcd6e937dd7
# Revision: 14

HTTP_PORT="${HTTP_PORT:-81}"
HTTPS_PORT="${HTTPS_PORT:-444}"

BACKUP_FILES="${BACKUP_FILES:-true}" # change to false to disable backups
BACKUP_DIR="${BACKUP_DIR:-/volume1/apps/free_ports/backup}"
DELETE_OLD_BACKUPS="${DELETE_OLD_BACKUPS:-false}" # change to true to automatically delete old backups.
KEEP_BACKUP_DAYS="${KEEP_BACKUP_DAYS:-30}"

EFFECTIVE_USER_ID="$(id -u)"
if [[ "${EFFECTIVE_USER_ID}" -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

NGINX_MUSTACHE_DIR="${NGINX_MUSTACHE_DIR:-/usr/syno/share/nginx}"
if [[ ! -d "${NGINX_MUSTACHE_DIR}" ]]; then
    echo "Error: ${NGINX_MUSTACHE_DIR} does not exist. This script is intended for Synology DSM."
    exit 1
fi

DATE=$(date +%Y-%m-%d-%H-%M-%S)
CURRENT_BACKUP_DIR="$BACKUP_DIR/$DATE"

if [[ "${BACKUP_FILES}" == "true" ]]; then
  echo "Backing up mustache files to ${CURRENT_BACKUP_DIR}"
  mkdir -p "$CURRENT_BACKUP_DIR"
  cp "${NGINX_MUSTACHE_DIR}"/*.mustache "$CURRENT_BACKUP_DIR"
fi

if [[ "${DELETE_OLD_BACKUPS}" == "true" ]]; then
  echo "Deleting backups older than ${KEEP_BACKUP_DAYS} days"
  find "$BACKUP_DIR/" -type d -mtime +"${KEEP_BACKUP_DAYS}" -exec rm -r {} \;
fi

echo "Updating HTTP port to ${HTTP_PORT} and HTTPS port to ${HTTPS_PORT}"
sed -i "s/^\([ \t]\+listen[ \t]\+[]:[]*\)80\([^0-9]\)/\1$HTTP_PORT\2/" "${NGINX_MUSTACHE_DIR}"/*.mustache
sed -i "s/^\([ \t]\+listen[ \t]\+[]:[]*\)443\([^0-9]\)/\1$HTTPS_PORT\2/" "${NGINX_MUSTACHE_DIR}"/*.mustache

if which synoservicecfg; then
  synoservicecfg --restart nginx
else
  synosystemctl restart nginx
fi

echo "Made these changes:"

# diff returns 1 if differences are found, which is expected here.
# we use "|| true" to prevent the script from exiting due to "set -e" and "pipefail".
diff "${NGINX_MUSTACHE_DIR}/" "$CURRENT_BACKUP_DIR" 2>&1 | tee "$CURRENT_BACKUP_DIR/changes.log" || true

echo "free_port.sh script finished successfully at $(date)"
