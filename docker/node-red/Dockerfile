# syntax=docker/dockerfile:1@sha256:38387523653efa0039f8e1c89bb74a30504e76ee9f565e25c9a09841f9427b05
FROM nodered/node-red:4.0.2-20-minimal@sha256:b63febdc2cf9734d340df42c3bc5bb03f33b38ebfd4316ae7a35cd23baeb0df6

ARG NPM_CACHE_FOLDER="/usr/src/node-red/npm_cache"

# check here on which alpine version node-red is based on and update the renovate config when needed:
# https://github.com/node-red/node-red-docker/blob/master/docker-custom/Dockerfile.custom
# https://repology.org/project/libcap/versions
# ---
# renovate: datasource=repology depName=alpine_3_20/libcap versioning=loose
ARG LIBCAP_VERSION="2.70-r0"

# Allow nodejs to run on privileged ports
USER root
RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
    apk --update-cache upgrade && \
    apk --update-cache add libcap=${LIBCAP_VERSION} && \
    setcap 'cap_net_bind_service=+eip' /usr/local/bin/node
USER node-red

# renovate: datasource=npm depName=node-red-contrib-homekit-bridged versioning=npm
ARG NODE_RED_HOMEKIT_BRIDGED_VERSION=1.6.1
# renovate: datasource=npm depName=node-red-contrib-huemagic versioning=npm
ARG NODE_RED_HUEMAGIC_VERSION=4.2.2
# renovate: datasource=npm depName=node-red-node-pushover versioning=npm
ARG NODE_RED_PUSHOVER_VERSION=0.2.1
# renovate: datasource=npm depName=node-red-contrib-knx-ultimate versioning=npm
ARG NODE_RED_KNX_ULTIMATE_VERSION=2.5.1
# renovate: datasource=npm depName=node-red-contrib-sonos-plus versioning=npm
ARG NODE_RED_SONOS_PLUS_VERSION=6.9.0
# renovate: datasource=npm depName=node-red-contrib-sonos-event versioning=npm
ARG NODE_RED_SONOS_EVENTS_VERSION=1.2.4
# renovate: datasource=npm depName=node-red-contrib-dwd-local-weather versioning=npm
ARG NODE_RED_DWD_LOCAL_WEATHER_VERSION=1.0.5
# renovate: datasource=npm depName=node-red-node-openweathermap versioning=npm
ARG NODE_RED_OPENWEATHERMAP_VERSION=1.0.1
# renovate: datasource=npm depName=node-red-contrib-sun-position versioning=npm
ARG NODE_RED_SUN_POSITION_VERSION=2.2.0-beta3
# renovate: datasource=npm depName=node-red-contrib-blindcontroller versioning=npm
ARG NODE_RED_BLIND_CONTROLLER_VERSION=4.8.6
# renovate: datasource=npm depName=node-red-node-ping versioning=npm
ARG NODE_RED_NODE_PING_VERSION=0.3.3
# renovate: datasource=npm depName=node-red-contrib-credentials versioning=npm
ARG NODE_RED_CREDENTIALS_VERSION=0.2.3

RUN --mount=type=cache,id=npm,sharing=locked,uid=1000,gid=1000,target="${NPM_CACHE_FOLDER}" \
    npm_config_cache="${NPM_CACHE_FOLDER}" npm install --no-fund --no-package-lock --save-prod --save-exact --no-update-notifier \
    node-red-contrib-homekit-bridged@${NODE_RED_HOMEKIT_BRIDGED_VERSION} \
    node-red-contrib-huemagic@${NODE_RED_HUEMAGIC_VERSION} \
    node-red-node-pushover@${NODE_RED_PUSHOVER_VERSION} \
    node-red-contrib-knx-ultimate@${NODE_RED_KNX_ULTIMATE_VERSION} \
    node-red-contrib-sonos-plus@${NODE_RED_SONOS_PLUS_VERSION} \
    node-red-contrib-sonos-events@${NODE_RED_SONOS_EVENTS_VERSION} \
    node-red-contrib-dwd-local-weather@${NODE_RED_DWD_LOCAL_WEATHER_VERSION} \
    node-red-node-openweathermap@${NODE_RED_OPENWEATHERMAP_VERSION} \
    node-red-contrib-sun-position@${NODE_RED_SUN_POSITION_VERSION} \
    node-red-contrib-blindcontroller@${NODE_RED_BLIND_CONTROLLER_VERSION} \
    node-red-node-ping@${NODE_RED_NODE_PING_VERSION} \
    node-red-contrib-credentials@${NODE_RED_CREDENTIALS_VERSION}

# Update outdated (and potentially vulnerable) dependencies
USER root
RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
    apk --update-cache upgrade
USER node-red
