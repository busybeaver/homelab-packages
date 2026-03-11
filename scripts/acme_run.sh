#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "acme_run.sh script started at $(date)"

# renovate: datasource=docker depName=neilpang/acme.sh versioning=docker
IMAGE_VERSION=latest@sha256:f3f1b7b29a7eebe2d68a2b0fdafa6cb6e8dc5598ab8656d9a1cfc1e3d05a28d7

docker run \
  --rm \
  --net=host \
  --volume "${ACME_HOME:-$(pwd)/output}":/acme.sh \
  --volume "${VOLUME_BASE_DIRECTORY:-$(pwd)/volume_base_directory}":/volume_base_directory \
  --env-file "${GLOBAL_ENV_FILE}" \
  --env-file "${ENV_FILE}" \
  "neilpang/acme.sh:${IMAGE_VERSION}" "$@"

echo "acme_run.sh script finished successfully at $(date)"
