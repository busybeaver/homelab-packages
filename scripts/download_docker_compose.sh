#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [ "${DEBUG_SCRIPT:-}" == "TRUE" ]; then
  set -x
fi
shopt -u nocasematch

echo "download_docker_compose.sh script started at $(date)"

# renovate: datasource=docker depName=mikefarah/yq versioning=docker
YQ_IMAGE_VERSION=4.47.1@sha256:b9285dd3b0bea3c34d0c54415dd48d767dabd9644d489bd6e253660847b58419

# renovate: datasource=docker depName=bitnami/cosign versioning=docker
COSIGN_IMAGE_VERSION=2.5.3@sha256:6c6622712d59631750c8c4f2ca008ffd766ba7b3553c174d155abcf80217311b

GIT_REPO_PATH="busybeaver/${GIT_REPOSITORY:-homelab-services}"

cd "${CHECKOUT_DIRECTORY:-.}" || exit 1

# requires SSH key or deploy key present
rm -rf ./tmp
git clone --branch main --single-branch --depth 1 --filter=blob:limit=1m "https://github.com/${GIT_REPO_PATH}.git" ./tmp
cd ./tmp || exit 1

if [ "${SKIP_VERIFICATION:-}" != "TRUE" ]; then
  # extract images from docker-compose.yaml file
  DOCKER_COMPOSE_IMAGES=$(docker run \
    --rm \
    --interactive \
    --security-opt=no-new-privileges \
    --cap-drop all \
    --network none \
    "mikefarah/yq:${YQ_IMAGE_VERSION}" '.services.[].image' <docker-compose.yaml)

  printf "The docker-compose.yaml file specifies the following Docker images:\n%s\n\n" "${DOCKER_COMPOSE_IMAGES}"

  echo "Verify the public sign key: public_key/cosign.pub"
  DOCKER_CONTENT_TRUST=1 docker run \
    --rm \
    --interactive \
    --security-opt=no-new-privileges \
    --cap-drop all \
    --network none \
    --volume "${PUBLIC_KEY_DIRECTORY:-$(pwd)/public_key}":/public_key:ro \
    "bitnami/cosign:${COSIGN_IMAGE_VERSION}" verify-blob --key /public_key/cosign.pub --signature /public_key/cosign.pub.sig /public_key/cosign.pub

  echo "Verify the signature of the docker image and if the image is available and accessible on remote registry"
  for DOCKER_COMPOSE_IMAGE in ${DOCKER_COMPOSE_IMAGES}; do
    # we can only verify the signature of our own images
    if [[ "${DOCKER_COMPOSE_IMAGE}" =~ ^ghcr\.io\/busybeaver\/homelab-packages\/.* ]]; then
      echo "Check signature for image: ${DOCKER_COMPOSE_IMAGE}"
      DOCKER_CONTENT_TRUST=1 docker run \
        --rm \
        --interactive \
        --security-opt=no-new-privileges \
        --cap-drop all \
        --volume "${PUBLIC_KEY_DIRECTORY:-$(pwd)/public_key}":/public_key:ro \
        "bitnami/cosign:${COSIGN_IMAGE_VERSION}" verify --key /public_key/cosign.pub --annotations "repo=${GIT_REPO_PATH}" --output text "${DOCKER_COMPOSE_IMAGE}"
      echo "Check if the image is available and accessible on remote registry: ${DOCKER_COMPOSE_IMAGE}"
      docker manifest inspect "${DOCKER_COMPOSE_IMAGE}" >/dev/null
    else
      echo "Skipping signature and image availability check for image: ${DOCKER_COMPOSE_IMAGE}"
    fi
  done

  echo "Verification and image availability check finished and succeeded"
else
  echo "SKIPPED Verification and image availability check. Use with caution!"
fi

DOCKER_COMPOSE_FILE="docker-compose.yaml"
echo "Replacing old ${DOCKER_COMPOSE_FILE} file"
cd .. || exit 1
rm "./${DOCKER_COMPOSE_FILE}"
mv "./tmp/${DOCKER_COMPOSE_FILE}" "./${DOCKER_COMPOSE_FILE}"
rm -rf ./tmp

echo "Start/update docker-compose in detached mode"
docker-compose --file "${DOCKER_COMPOSE_FILE}" up --no-color --detach --remove-orphans
sleep 10
docker-compose --file "${DOCKER_COMPOSE_FILE}" logs --no-color --tail="25"

echo "download_docker_compose.sh script finished successfully at $(date)"
