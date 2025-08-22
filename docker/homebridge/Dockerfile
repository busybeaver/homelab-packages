# syntax=docker/dockerfile:1@sha256:38387523653efa0039f8e1c89bb74a30504e76ee9f565e25c9a09841f9427b05
FROM public.ecr.aws/lts/ubuntu:24.04@sha256:288b44a1b2dfe3788255c3abd41e346bece153b9e066325f461f605425afaf82 as build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# renovate: datasource=repology depName=ubuntu_24_04/ca-certificates versioning=loose
ARG CA_CERTIFICATES_VERSION="20240203"
# renovate: datasource=repology depName=ubuntu_24_04/curl versioning=loose
ARG CURL_VERSION="8.5.0-2ubuntu10.6"
# renovate: datasource=repology depName=ubuntu_24_04/gnupg2 versioning=loose
ARG GPG_VERSION="2.4.4-2ubuntu17.3"

RUN --mount=type=cache,id=apt,sharing=locked,target=/var/cache/apt \
    apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
      ca-certificates="${CA_CERTIFICATES_VERSION}" \
      curl="${CURL_VERSION}" \
      gpg="${GPG_VERSION}" && \
    curl -sSfL https://repo.homebridge.io/KEY.gpg | gpg --dearmor -o /tmp/homebridge.gpg

FROM public.ecr.aws/lts/ubuntu:24.04@sha256:288b44a1b2dfe3788255c3abd41e346bece153b9e066325f461f605425afaf82

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=60s CMD curl --fail http://127.0.0.1:8581 || exit 1

COPY --from=build /tmp/homebridge.gpg /etc/apt/trusted.gpg.d/homebridge.gpg

# renovate: datasource=repology depName=ubuntu_24_04/ca-certificates versioning=loose
ARG CA_CERTIFICATES_VERSION="20240203"
# renovate: datasource=repology depName=ubuntu_24_04/curl versioning=loose
ARG CURL_VERSION="8.5.0-2ubuntu10.6"
# renovate: datasource=github-releases depName=homebridge/homebridge-apt-pkg versioning=loose
ARG HOMEBRIDGE_VERSION="v1.7.5 - 2025-08-06"

RUN --mount=type=cache,id=apt,sharing=locked,target=/var/cache/apt \
    # Setup repository
    apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
      ca-certificates="${CA_CERTIFICATES_VERSION}" && \
    echo "deb https://repo.homebridge.io stable main" | tee /etc/apt/sources.list.d/homebridge.list > /dev/null && \
    # Install homebridge
    apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
      libcap2-bin="${LIBCAP_VERSION}" \
      homebridge="${HOMEBRIDGE_VERSION:1}" && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Allow nodejs to run on privileged ports
    setcap 'cap_net_bind_service=+eip' /opt/homebridge/bin/node && \
    # Make the start script executable
    chmod +x /opt/homebridge/start.sh

WORKDIR /var/lib/homebridge
ARG NPM_CACHE_FOLDER="/tmp/npm_cache"

# renovate: datasource=npm depName=homebridge-fritz-platform versioning=npm
ARG HOMEBRIDGE_FRITZ_PLATFORM_VERSION=6.0.19
# renovate: datasource=npm depName=homebridge-weather-plus versioning=npm
ARG HOMEBRIDGE_WEATHER_PLUS_VERSION=3.3.5
# renovate: datasource=npm depName=homebridge-homeconnect versioning=npm
ARG HOMEBRIDGE_HOMECONNECT_VERSION=0.42.4
# renovate: datasource=npm depName=homebridge-dummy versioning=npm
ARG HOMEBRIDGE_DUMMY_VERSION=0.9.0
# renovate: datasource=npm depName=homebridge-delay-switch versioning=npm
ARG HOMEBRIDGE_DELAY_SWITCH_VERSION=3.2.5
# renovate: datasource=npm depName=homebridge-camera-ffmpeg versioning=npm
ARG HOMEBRIDGE_CAMERA_FFMPEG_VERSION=3.1.4
# renovate: datasource=npm depName=homebridge-dyson-pure-cool versioning=npm
ARG HOMEBRIDGE_DYSON_PURE_COOL_VERSION=2.7.12

# hadolint ignore=SC1091
RUN --mount=type=cache,id=npm,sharing=locked,uid=1000,gid=1000,target="${NPM_CACHE_FOLDER}" \
    . /opt/homebridge/source.sh && \
    npm_config_cache="${NPM_CACHE_FOLDER}" npm install --save-prod --no-package-lock --save-exact --no-update-notifier \
      "homebridge-fritz-platform@${HOMEBRIDGE_FRITZ_PLATFORM_VERSION}" \
      "homebridge-weather-plus@${HOMEBRIDGE_WEATHER_VERSION}" \
      "homebridge-homeconnect@${HOMEBRIDGE_HOMECONNECT_VERSION}" \
      "homebridge-dummy@${HOMEBRIDGE_DUMMY_VERSION}" \
      "homebridge-delay-switch@${HOMEBRIDGE_DELAY_SWITCH_VERSION}" \
      "homebridge-camera-ffmpeg@${HOMEBRIDGE_CAMERA_FFMPEG_VERSION}" \
      "homebridge-dyson-pure-cool@${HOMEBRIDGE_DYSON_PURE_COOL_VERSION}"

CMD [ "/opt/homebridge/start.sh" ]
