# syntax=docker/dockerfile:1@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

FROM scratch
# FROM lstarwarsfan/edomi-docker:2.03.10

# # renovate: datasource=repology depName=debian_10/libcap2 versioning=loose
# ARG LIBCAP_VERSION="1:2.25-2"

# # override entrypoint.sh file to support rootless execution of the container
# COPY entrypoint.sh /app/extra/entrypoint.sh
# RUN --mount=type=cache,id=apt,sharing=locked,target=/var/cache/apt \
#     apt-get update && \
#     apt-get install --yes --no-install-recommends --no-install-suggests \
#       libcap2-bin="${LIBCAP_VERSION}" && \
#     # Cleanup
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* && \
#     # Make start script executable
#     chmod +x /app/extra/entrypoint.sh && \
#     # Allow nodejs to run on privileged ports
#     setcap 'cap_net_bind_service=+ep' /usr/local/bin/node
