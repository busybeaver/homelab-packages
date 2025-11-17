#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [ "${DEBUG_SCRIPT:-}" == "TRUE" ]; then
  set -x
fi
shopt -u nocasematch

echo "acme_run.sh script started at $(date)"

# renovate: datasource=docker depName=neilpang/acme.sh versioning=docker
IMAGE_VERSION=latest@sha256:bfae47ce9d20711a19a73ebc7c8104dd17bfb3b0910f44710ee28aefcae49225

docker run \
  --rm \
  --net=host \
  --volume "${ACME_HOME:-$(pwd)/output}":/acme.sh \
  --volume "${VOLUME_BASE_DIRECTORY:-$(pwd)/volume_base_directory}":/volume_base_directory \
  --env-file "${GLOBAL_ENV_FILE}" \
  --env-file "${ENV_FILE}" \
  "neilpang/acme.sh:${IMAGE_VERSION}" "$@"

echo "acme_run.sh script finished successfully at $(date)"
