# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
FROM louislam/uptime-kuma:2-rootless@sha256:ea1b2ceb6ef710a3d0d994debcc8cded062e534fb901f6e895f59caad68e0a9e

# TODO: is this still needed after switching to rootless image? if not, remove it
# override entrypoint.sh file to support rootless execution of the container
COPY entrypoint.sh /app/extra/entrypoint.sh

# setcap comes with libcap2-bin in the base image; installing a pinned Debian version broke the build whenever Debian
# replaced it with a security update
USER root
RUN \
    # Make start script executable
    chmod +x /app/extra/entrypoint.sh && \
    # Allow nodejs to run on privileged ports
    setcap 'cap_net_bind_service=+eip' "$(readlink -f "$(which node)")"
USER node
