# syntax=docker/dockerfile:1@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf
FROM ghcr.io/micromdm/micromdm:v1.13.0@sha256:69b7b09543c0ed0a5181b0085fd821575cc609583e5b0f40e8a1db9a273eb40a

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
