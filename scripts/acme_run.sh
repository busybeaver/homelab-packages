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
IMAGE_VERSION=latest@sha256:af690ec5db696a0050a34f1f36e1cbd1bb7959889bcb29089c2f98df80b08a10

ENV_ARGS=()
if [[ -n "${GLOBAL_ENV_FILE:-}" ]]; then
  ENV_ARGS+=("--env-file" "${GLOBAL_ENV_FILE}")
fi
if [[ -n "${ENV_FILE:-}" ]]; then
  ENV_ARGS+=("--env-file" "${ENV_FILE}")
fi

docker run \
  --rm \
  --net=host \
  --volume "${ACME_HOME:-$(pwd)/output}":/acme.sh \
  --volume "${VOLUME_BASE_DIRECTORY:-$(pwd)/volume_base_directory}":/volume_base_directory \
  "${ENV_ARGS[@]}" \
  "neilpang/acme.sh:${IMAGE_VERSION}" "$@"

echo "acme_run.sh script finished successfully at $(date)"
