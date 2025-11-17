# syntax=docker/dockerfile:1@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf
FROM alpine/git:v2.49.1@sha256:26a2c6e01600c5795c2694a95ba187e906422b5e5862a53f13f11e17fde8deb8 as build

# renovate: datasource=github-tags depName=tribut/homeassistant-docker-venv versioning=loose
ARG GIT_TAG_VERSION="v2.3"

WORKDIR /tmp/homeassistant-docker-venv
RUN git clone --depth 1 --branch ${GIT_TAG_VERSION} https://github.com/tribut/homeassistant-docker-venv.git .

FROM homeassistant/home-assistant:2025.9@sha256:89ec0583c7f47c8a150204f6b5ed48b5432026012bebe1226cf72775a795a5e1

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl --fail http://127.0.0.1:8123 || exit 1

ARG HOME_ASSISTANT_ENTRYPOINT="/etc/services.d/home-assistant/run"

# This is a simple build time check to ensure that the home assistant
# entry point didn't change in the base/parent image. without this
# check, a changed entry point would only be detected "later" during
# runtime (which is obviously not desirable)
RUN cat ${HOME_ASSISTANT_ENTRYPOINT} > /dev/null

# Copy/override the entry point of home-assistant, allows to run home-assistant as non-root user
COPY --from=build /tmp/homeassistant-docker-venv/run ${HOME_ASSISTANT_ENTRYPOINT}

# Update outdated (and potentially vulnerable) dependencies
RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
    apk --update-cache upgrade
