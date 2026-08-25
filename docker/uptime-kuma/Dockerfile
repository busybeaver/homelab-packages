# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
FROM louislam/uptime-kuma:2-rootless@sha256:79c639df9a2f26472bfcf48bb95a4e38533ce049158b79d4871a8bac787b6e71

# renovate: datasource=repology depName=debian_12/libcap2 versioning=loose
ARG LIBCAP_VERSION="1:2.66-4+deb12u2+b2"

# TODO: is this still needed after switching to rootless image? if not, remove it
# override entrypoint.sh file to support rootless execution of the container
COPY entrypoint.sh /app/extra/entrypoint.sh

USER root
RUN --mount=type=cache,id=apt,sharing=locked,target=/var/cache/apt \
    apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
      libcap2-bin="${LIBCAP_VERSION}" && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Make start script executable
    chmod +x /app/extra/entrypoint.sh && \
    # Allow nodejs to run on privileged ports
    setcap 'cap_net_bind_service=+eip' "$(readlink -f "$(which node)")"
USER node
