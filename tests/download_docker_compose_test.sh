#!/usr/bin/env bash
# Tests scripts/download_docker_compose.sh with stubbed curl, docker, docker-compose and sleep.
set -euo pipefail

script="$(cd "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/scripts/download_docker_compose.sh"
work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT
tests=0
failures=0

# usage: assert <name> <condition...>
assert() {
  local name="$1"
  shift
  tests=$((tests + 1))
  if "$@"; then
    echo "ok   ${name}"
  else
    failures=$((failures + 1))
    echo "FAIL ${name}"
    [[ ! -s "${work}/log" ]] || while IFS= read -r line; do echo "    ${line}"; done <"${work}/log"
  fi
}

# --- stubs ---
mkdir -p "${work}/bin"
# curl: resolves releases/latest to STUB_LATEST_TAG and serves assets from ${work}/server/<tag>/
cat >"${work}/bin/curl" <<'EOF'
#!/usr/bin/env bash
out="" write="" url=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -o | --output) out="$2"; shift 2 ;;
    -w | --write-out) write="$2"; shift 2 ;;
    --proto | --proto-redir | --max-time) shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
echo "curl ${url}" >>"${STUB_CALLS}"
if [[ "${url}" == */releases/latest ]]; then
  [[ "${write}" == "%{url_effective}" ]] && printf '%s' "${url%/latest}/tag/${STUB_LATEST_TAG}"
  exit 0
fi
file="${STUB_SERVER}/${url#*/releases/download/}"
[[ -f "${file}" ]] || exit 22
cp "${file}" "${out}"
EOF
# docker: cosign verify-blob, cosign verify (images), yq (image list) and manifest inspect
cat >"${work}/bin/docker" <<'EOF'
#!/usr/bin/env bash
echo "docker $*" >>"${STUB_CALLS}"
case " $* " in
  *" verify-blob "*) exit "${STUB_BLOB_STATUS:-0}" ;;
  *" verify "*) exit "${STUB_IMAGE_STATUS:-0}" ;;
  *"mikefarah/yq"*) awk '$1 == "image:" {print $2}' ;;
  *" manifest inspect "*) exit 0 ;;
esac
EOF
# shellcheck disable=SC2016 # expanded by the stub, not here
printf '#!/usr/bin/env bash\necho "docker-compose $*" >>"${STUB_CALLS}"\n' >"${work}/bin/docker-compose"
printf '#!/usr/bin/env bash\nexit 0\n' >"${work}/bin/sleep"
chmod +x "${work}/bin/"*

# usage: release <tag> ; publishes a consistent release of target homelab under ${work}/server/<tag>/
release() {
  local dir="${work}/server/$1"
  mkdir -p "${dir}"
  printf '%s\n' "$1" >"${dir}/RELEASE"
  printf 'services:\n  own:\n    image: ghcr.io/busybeaver/homelab-packages/node-red:latest@sha256:%064d\n  other:\n    image: docker.io/library/postgres:18@sha256:%064d\n# release %s\n' 1 2 "$1" >"${dir}/docker-compose.homelab.yaml"
  printf 'services: {}\n' >"${dir}/docker-compose.cloud-a.yaml"
  (cd "${dir}" && sha256sum RELEASE docker-compose.cloud-a.yaml docker-compose.homelab.yaml >SHA256SUMS)
  printf '{}\n' >"${dir}/SHA256SUMS.sigstore.json"
}

# usage: deploy_dir ; fresh deployment directory with a public key and a running v2026.01.01-1 stack
deploy_dir() {
  rm -rf -- "${work}/deploy" "${work}/server" "${work}/calls"
  mkdir -p "${work}/deploy/public_key"
  printf 'PUBLIC KEY\n' >"${work}/deploy/public_key/cosign.pub"
  printf 'services: {}\n# release v2026.01.01-1\n' >"${work}/deploy/docker-compose.homelab.yaml"
  printf 'v2026.01.01-1\n' >"${work}/deploy/.deployed-release"
  : >"${work}/calls"
}

# usage: run_script [VAR=value...] ; sets $status
run_script() {
  status=0
  env "$@" PATH="${work}/bin:${PATH}" STUB_CALLS="${work}/calls" STUB_SERVER="${work}/server" \
    CHECKOUT_DIRECTORY="${work}/deploy" bash "${script}" >"${work}/log" 2>&1 || status=$?
}
called() { grep -qF -- "$1" "${work}/calls"; }
deployed() { grep -qx "# release $1" "${work}/deploy/docker-compose.homelab.yaml" && grep -qx "$1" "${work}/deploy/.deployed-release"; }
# the running stack stays untouched and nothing is started
unchanged() { [[ "${status}" -ne 0 ]] && deployed v2026.01.01-1 && ! called "docker-compose --file" && [[ ! -e "${work}/deploy/tmp" ]]; }
failed_with() { unchanged && grep -qF -- "$1" "${work}/log"; }

# --- tests ---
deploy_dir
release v2026.01.02-1
run_script STUB_LATEST_TAG=v2026.01.02-1
assert "deploys the latest release" [ "${status}" -eq 0 ]
assert "replaces the compose file and records the release" deployed v2026.01.02-1
assert "keeps the previous compose file" grep -qx "# release v2026.01.01-1" "${work}/deploy/docker-compose.homelab.yaml.previous"
assert "resolves the release from busybeaver-homelab/services" called "curl https://github.com/busybeaver-homelab/services/releases/latest"
assert "downloads the target from the resolved tag" called "curl https://github.com/busybeaver-homelab/services/releases/download/v2026.01.02-1/docker-compose.homelab.yaml"
assert "verifies the SHA256SUMS bundle with the local public key" called "verify-blob --key /public_key/cosign.pub --bundle /release/SHA256SUMS.sigstore.json /release/SHA256SUMS"
assert "mounts the local public key directory" called "--volume ${work}/deploy/public_key:/public_key:ro"
assert "verifies own images with the homelab-packages annotation" called "--annotations repo=busybeaver/homelab-packages --output text ghcr.io/busybeaver/homelab-packages/node-red"
assert "does not verify foreign images" bash -c "! grep -F 'verify --key' '${work}/calls' | grep -qF 'postgres'"
assert "starts the stack with the release file" called "docker-compose --file docker-compose.homelab.yaml up --no-color --detach --remove-orphans"
assert "removes the download directory" [ ! -e "${work}/deploy/tmp" ]

deploy_dir
release v2026.01.01-1
run_script STUB_LATEST_TAG=v2026.01.01-1
assert "already deployed release is a no-op" bash -c "[ ${status} -eq 0 ] && ! grep -qF 'docker-compose --file' '${work}/calls' && ! grep -qF 'releases/download' '${work}/calls'"

deploy_dir
release v2025.12.31-9
run_script STUB_LATEST_TAG=v2025.12.31-9
assert "older release than the deployed one fails" failed_with "older than the deployed release"

deploy_dir
run_script STUB_LATEST_TAG=latest
assert "invalid tag fails" failed_with "invalid release tag"

deploy_dir
release v2026.01.02-1
run_script STUB_LATEST_TAG=v2026.01.02-1 STUB_BLOB_STATUS=1
assert "invalid release signature fails" unchanged

deploy_dir
release v2026.01.02-1
printf 'tampered\n' >>"${work}/server/v2026.01.02-1/docker-compose.homelab.yaml"
run_script STUB_LATEST_TAG=v2026.01.02-1
assert "checksum mismatch of the target fails" unchanged

deploy_dir
release v2026.01.02-1
sed -i.bak '/docker-compose.homelab.yaml/d' "${work}/server/v2026.01.02-1/SHA256SUMS"
run_script STUB_LATEST_TAG=v2026.01.02-1
assert "SHA256SUMS without the target fails" failed_with "SHA256SUMS does not list"

deploy_dir
release v2026.01.02-1
release v2026.01.03-1
cp "${work}/server/v2026.01.03-1/"* "${work}/server/v2026.01.02-1/"
run_script STUB_LATEST_TAG=v2026.01.02-1
assert "RELEASE of another tag fails" failed_with "does not match"

deploy_dir
release v2026.01.02-1
run_script STUB_LATEST_TAG=v2026.01.02-1 STUB_IMAGE_STATUS=1
assert "invalid image signature fails" unchanged

deploy_dir
release v2026.01.02-1
rm "${work}/deploy/public_key/cosign.pub"
run_script STUB_LATEST_TAG=v2026.01.02-1
assert "missing public key fails before downloading" bash -c "[ ${status} -ne 0 ] && ! grep -qF 'curl' '${work}/calls' && grep -qF 'public key' '${work}/log'"

deploy_dir
rm "${work}/deploy/.deployed-release"
release v2026.01.02-1
run_script STUB_LATEST_TAG=v2026.01.02-1
assert "first deployment without a recorded release succeeds" bash -c "[ ${status} -eq 0 ] && grep -qx v2026.01.02-1 '${work}/deploy/.deployed-release'"

deploy_dir
run_script STUB_LATEST_TAG=v2026.01.02-1 RELEASE_TARGET=Bad
assert "invalid target fails" failed_with "invalid release target"

echo "${tests} tests, ${failures} failures"
[[ "${failures}" -eq 0 ]]
