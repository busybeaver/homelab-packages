# syntax=docker/dockerfile:1@sha256:ac85f380a63b13dfcefa89046420e1781752bab202122f8f50032edf31be0021
FROM caddy:2.7.6-builder-alpine@sha256:fd9d8fc07ef53ffdb2c55e5eaf90f575f0742a80eca6a85d28000ae766838cc2 AS build

RUN --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/lolPants/caddy-requestid \
    --with github.com/hslatman/caddy-crowdsec-bouncer \
    --with github.com/caddyserver/transform-encoder

FROM caddy:2.7.6-alpine@sha256:95ce04978787e23e35143d23b8af2fbb6d6de55213b54a2e9ed2dbf8ffe7313c

COPY --from=build /usr/bin/caddy /usr/bin/caddy

# check here on which alpine version caddy is based on and update the renovate config when needed:
# https://github.com/caddyserver/caddy-docker
# https://repology.org/project/libcap/versions
# ---
# renovate: datasource=repology depName=alpine_3_18/libcap versioning=loose
ARG LIBCAP_VERSION="2.69-r0"

# Update outdated (and potentially vulnerable) dependencies;
# Allow to run Caddy on privileged ports (as a non-root user)
RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
    apk --update-cache upgrade && \
    apk --update-cache add libcap=${LIBCAP_VERSION} && \
    setcap 'cap_net_bind_service=+eip' /usr/bin/caddy
