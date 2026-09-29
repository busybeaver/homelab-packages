# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
FROM ghcr.io/micromdm/micromdm:v1.13.1@sha256:4ea541d809bc7665b013b56a89c2bd17fed65ad7490f6d3bb7ae166285f9534d

# Enabling the docker healthcheck below
ENV MICROMDM_HTTP_HOMEPAGE=true

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl --fail http://127.0.0.1:8080 || exit 1

# renovate: datasource=repology depName=alpine_3_21/libcap versioning=loose
ARG LIBCAP_VERSION="2.71-r0"

# Update outdated (and potentially vulnerable) dependencies;
# Allow to run micromdm on privileged ports (as a non-root user)
RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
    apk --update-cache upgrade && \
    apk --update-cache add libcap=${LIBCAP_VERSION} && \
    setcap 'cap_net_bind_service=+eip' /usr/bin/micromdm
