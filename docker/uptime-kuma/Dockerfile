# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
FROM louislam/uptime-kuma:2-rootless@sha256:c4e17ce033deb811aff8a61a5f8f736f35b1bd937458ddeec46c59ca190f0e03

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
