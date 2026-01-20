#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "download_scripts.sh script started at $(date)"

# renovate: datasource=docker depName=bitnami/cosign versioning=docker
COSIGN_IMAGE_VERSION=2.5.3@sha256:6c6622712d59631750c8c4f2ca008ffd766ba7b3553c174d155abcf80217311b

cd "${CHECKOUT_DIRECTORY:-.}" || exit 1

rm -rf ./tmp
git clone --branch main --single-branch --depth 1 --filter=blob:limit=1m "https://github.com/busybeaver/${GIT_REPOSITORY:-homelab-packages}.git" ./tmp
cd ./tmp || exit 1

if [[ "${SKIP_VERIFICATION:-}" != "TRUE" ]]; then
  echo "Verify the public sign key: public_key/cosign.pub"
  DOCKER_CONTENT_TRUST=1 docker run \
    --rm \
    --interactive \
    --security-opt=no-new-privileges \
    --cap-drop all \
    --network none \
    --volume "${PUBLIC_KEY_DIRECTORY:-$(pwd)/public_key}":/public_key:ro \
    "bitnami/cosign:${COSIGN_IMAGE_VERSION}" verify-blob --key /public_key/cosign.pub --signature /public_key/cosign.pub.sig /public_key/cosign.pub

  echo "Verify the checksum file: scripts/scripts.sha256"
  DOCKER_CONTENT_TRUST=1 docker run \
    --rm \
    --interactive \
    --security-opt=no-new-privileges \
    --cap-drop all \
    --network none \
    --volume "${PUBLIC_KEY_DIRECTORY:-$(pwd)/public_key}":/public_key:ro \
    --volume "${SCRIPTS_DIRECTORY:-$(pwd)/scripts}":/scripts:ro \
    "bitnami/cosign:${COSIGN_IMAGE_VERSION}" verify-blob --key /public_key/cosign.pub --signature /scripts/scripts.sha256.sig /scripts/scripts.sha256

  echo "Check the script checksums"
  (cd ./scripts && sha256sum -c scripts.sha256)

  echo "Verification finished and succeeded"
else
  echo "SKIPPED Verification. Use with caution!"
fi

echo "Replacing old script files"
cd .. || exit 1
rm -rf ./scripts
mv ./tmp/scripts ./scripts
rm -rf ./tmp

echo "download_scripts.sh script finished successfully at $(date)"
