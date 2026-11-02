#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LC_ALL=C

shopt -s nocasematch
if [[ "${DEBUG_SCRIPT:-}" == "TRUE" ]]; then
  set -x
fi
shopt -u nocasematch

echo "download_docker_compose.sh script started at $(date)"

# renovate: datasource=docker depName=mikefarah/yq versioning=docker
YQ_IMAGE_VERSION=4.54.1@sha256:4b3d9475d65571d28cbb19544d3820ec2945e4c8b2f18279394282b8dc3a592e

# renovate: datasource=docker depName=bitnami/cosign versioning=docker
COSIGN_IMAGE_VERSION=2.5.3@sha256:6c6622712d59631750c8c4f2ca008ffd766ba7b3553c174d155abcf80217311b

# deploys the latest signed release of docker-compose.<target>.yaml (see the services repository README)
RELEASE_REPOSITORY="${RELEASE_REPOSITORY:-busybeaver-homelab/services}"
RELEASE_TARGET="${RELEASE_TARGET:-homelab}"
RELEASE_URL="https://github.com/${RELEASE_REPOSITORY}/releases"
# our own images are signed by the Docker CI of this repository with this annotation
IMAGE_SIGNATURE_REPOSITORY="busybeaver/homelab-packages"

if [[ ! "${RELEASE_TARGET}" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "invalid release target: ${RELEASE_TARGET}"
  exit 1
fi
DOCKER_COMPOSE_FILE="docker-compose.${RELEASE_TARGET}.yaml"

cd "${CHECKOUT_DIRECTORY:-.}" || exit 1

# the trusted key must already be on the host; the release cannot vouch for itself
PUBLIC_KEY_DIRECTORY="${PUBLIC_KEY_DIRECTORY:-$(pwd)/public_key}"
if [[ ! -f "${PUBLIC_KEY_DIRECTORY}/cosign.pub" ]]; then
  echo "public key not found: ${PUBLIC_KEY_DIRECTORY}/cosign.pub"
  exit 1
fi

download() {
  curl --proto '=https' --proto-redir '=https' -fsSL --max-time 60 "$@"
}

LATEST_URL=$(download --output /dev/null --write-out '%{url_effective}' "${RELEASE_URL}/latest")
TAG="${LATEST_URL##*/}"
if [[ ! "${TAG}" =~ ^v[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9]+$ ]]; then
  echo "invalid release tag: ${TAG}"
  exit 1
fi

if [[ -f .deployed-release ]]; then
  DEPLOYED_TAG=$(cat .deployed-release)
  if [[ "${DEPLOYED_TAG}" == "${TAG}" ]]; then
    echo "Release ${TAG} is already deployed"
    exit 0
  fi
  if [[ "$(printf '%s\n' "${DEPLOYED_TAG}" "${TAG}" | sort -V | tail -n 1)" != "${TAG}" ]]; then
    echo "Release ${TAG} is older than the deployed release ${DEPLOYED_TAG}"
    exit 1
  fi
fi

echo "Download release ${TAG} of ${RELEASE_REPOSITORY}"
RELEASE_DIRECTORY="$(pwd)/tmp"
rm -rf "${RELEASE_DIRECTORY}"
trap 'rm -rf "${RELEASE_DIRECTORY}"' EXIT
mkdir "${RELEASE_DIRECTORY}"
for ASSET in SHA256SUMS SHA256SUMS.sigstore.json RELEASE "${DOCKER_COMPOSE_FILE}"; do
  download --output "${RELEASE_DIRECTORY}/${ASSET}" "${RELEASE_URL}/download/${TAG}/${ASSET}"
done

echo "Verify the signature of SHA256SUMS"
DOCKER_CONTENT_TRUST=1 docker run \
  --rm \
  --security-opt=no-new-privileges \
  --cap-drop all \
  --volume "${PUBLIC_KEY_DIRECTORY}":/public_key:ro \
  --volume "${RELEASE_DIRECTORY}":/release:ro \
  "bitnami/cosign:${COSIGN_IMAGE_VERSION}" verify-blob --key /public_key/cosign.pub --bundle /release/SHA256SUMS.sigstore.json /release/SHA256SUMS

echo "Check the checksums of RELEASE and ${DOCKER_COMPOSE_FILE}"
CHECKSUMS=$(grep -E -x "[0-9a-f]{64}  (RELEASE|docker-compose\.${RELEASE_TARGET}\.yaml)" "${RELEASE_DIRECTORY}/SHA256SUMS" || true)
if [[ "$(grep -c . <<<"${CHECKSUMS}")" -ne 2 ]]; then
  echo "SHA256SUMS does not list RELEASE and ${DOCKER_COMPOSE_FILE} exactly once"
  exit 1
fi
(cd "${RELEASE_DIRECTORY}" && sha256sum -c - <<<"${CHECKSUMS}")

# the signed RELEASE binds the files to the tag, so an older release cannot be served under a newer tag
if ! printf '%s\n' "${TAG}" | cmp -s - "${RELEASE_DIRECTORY}/RELEASE"; then
  echo "RELEASE does not match the tag ${TAG}"
  exit 1
fi

DOCKER_COMPOSE_IMAGES=$(docker run \
  --rm \
  --interactive \
  --security-opt=no-new-privileges \
  --cap-drop all \
  --network none \
  "mikefarah/yq:${YQ_IMAGE_VERSION}" '.services.[].image' <"${RELEASE_DIRECTORY}/${DOCKER_COMPOSE_FILE}")

printf "The %s file specifies the following Docker images:\n%s\n\n" "${DOCKER_COMPOSE_FILE}" "${DOCKER_COMPOSE_IMAGES}"

echo "Verify the signature of the docker image and if the image is available and accessible on remote registry"
for DOCKER_COMPOSE_IMAGE in ${DOCKER_COMPOSE_IMAGES}; do
  # we can only verify the signature of our own images
  if [[ "${DOCKER_COMPOSE_IMAGE}" =~ ^ghcr\.io\/busybeaver\/homelab-packages\/.* ]]; then
    echo "Check signature for image: ${DOCKER_COMPOSE_IMAGE}"
    DOCKER_CONTENT_TRUST=1 docker run \
      --rm \
      --security-opt=no-new-privileges \
      --cap-drop all \
      --volume "${PUBLIC_KEY_DIRECTORY}":/public_key:ro \
      "bitnami/cosign:${COSIGN_IMAGE_VERSION}" verify --key /public_key/cosign.pub --annotations "repo=${IMAGE_SIGNATURE_REPOSITORY}" --output text "${DOCKER_COMPOSE_IMAGE}"
    echo "Check if the image is available and accessible on remote registry: ${DOCKER_COMPOSE_IMAGE}"
    docker manifest inspect "${DOCKER_COMPOSE_IMAGE}" >/dev/null
  else
    echo "Skipping signature and image availability check for image: ${DOCKER_COMPOSE_IMAGE}"
  fi
done

echo "Verification and image availability check finished and succeeded"

echo "Replacing old ${DOCKER_COMPOSE_FILE} file"
if [[ -f "${DOCKER_COMPOSE_FILE}" ]]; then
  mv "${DOCKER_COMPOSE_FILE}" "${DOCKER_COMPOSE_FILE}.previous"
fi
mv "${RELEASE_DIRECTORY}/${DOCKER_COMPOSE_FILE}" "${DOCKER_COMPOSE_FILE}"

echo "Start/update docker-compose in detached mode"
docker-compose --file "${DOCKER_COMPOSE_FILE}" up --no-color --detach --remove-orphans
printf '%s\n' "${TAG}" >.deployed-release
sleep 10
docker-compose --file "${DOCKER_COMPOSE_FILE}" logs --no-color --tail="25"

echo "download_docker_compose.sh script finished successfully at $(date)"
