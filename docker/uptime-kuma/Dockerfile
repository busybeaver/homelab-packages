# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
FROM louislam/uptime-kuma:2-rootless@sha256:e37da4d06fc3ac2c9f2a8a73304cca5d8efd2c539dad16e17b211646a15556c0

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
