# syntax=docker/dockerfile:1@sha256:38387523653efa0039f8e1c89bb74a30504e76ee9f565e25c9a09841f9427b05
FROM louislam/uptime-kuma:2.0.0-beta-rootless.3@sha256:1ab09aa4c0d1058d28c2716123a43739a32b87806ba12f9b56c5bb7ba3785a9d

# renovate: datasource=repology depName=debian_12/libcap2 versioning=loose
ARG LIBCAP_VERSION="1:2.66-4+deb12u2"

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
    setcap 'cap_net_bind_service=+ep' /usr/local/bin/node
USER node
