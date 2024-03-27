#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ "${DEBUG_SCRIPT:-}" == "TRUE" ]; then
  set -x
fi

echo "download_scripts.sh script started at $(date)"

# renovate: datasource=docker depName=bitnami/cosign versioning=docker
COSIGN_IMAGE_VERSION=2.2.3@sha256:31795f4112105a3accd955ce5bf3ddff1219fc2f07f8cbfd4152a108f93e1cc7

cd "${CHECKOUT_DIRECTORY:-.}" || exit 1

rm -rf ./tmp
git clone --branch main --single-branch --depth 1 --filter=blob:limit=1m "https://github.com/busybeaver/${GIT_REPOSITORY:-homelab-packages}.git" ./tmp
cd ./tmp || exit 1

if [ "${SKIP_VERIFICATION:-}" != "TRUE" ]; then
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
