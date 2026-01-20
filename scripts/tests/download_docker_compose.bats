#!/usr/bin/env bats

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Mock git
    cat <<EOF > "$MOCK_BIN/git"
#!/usr/bin/env bash
if [[ "\$1" == "clone" ]]; then
    TARGET_DIR="\${@: -1}"
    mkdir -p "\$TARGET_DIR/public_key"
    touch "\$TARGET_DIR/docker-compose.yaml"
    IMAGE_STR="services: { app: { image: 'ghcr.io/busybeaver/test:latest' } }"
    echo "\$IMAGE_STR" > "\$TARGET_DIR/docker-compose.yaml"
    touch "\$TARGET_DIR/public_key/cosign.pub"
    touch "\$TARGET_DIR/public_key/cosign.pub.sig"
fi
EOF
    chmod +x "$MOCK_BIN/git"

    # Mock docker
    cat <<EOF > "$MOCK_BIN/docker"
#!/usr/bin/env bash
echo "docker called with \$*" >&2
if [[ "\$*" == *"mikefarah/yq"* ]]; then
    echo "ghcr.io/busybeaver/test:latest"
fi
EOF
    chmod +x "$MOCK_BIN/docker"

    # Mock docker-compose
    cat <<EOF > "$MOCK_BIN/docker-compose"
#!/usr/bin/env bash
echo "docker-compose called with \$*" >&2
EOF
    chmod +x "$MOCK_BIN/docker-compose"

    # Mock sleep
    cat <<EOF > "$MOCK_BIN/sleep"
#!/usr/bin/env bash
echo "sleep called with \$*" >&2
EOF
    chmod +x "$MOCK_BIN/sleep"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "download_docker_compose.sh downloads and updates correctly" {
    export CHECKOUT_DIRECTORY="$TEST_TEMP_DIR/checkout"
    mkdir -p "$CHECKOUT_DIRECTORY"
    touch "$CHECKOUT_DIRECTORY/docker-compose.yaml"

    # We need to make sure we are in a directory that can see
    # scripts/download_docker_compose.sh or just use the absolute path.
    run bash scripts/download_docker_compose.sh
    [ "$status" -eq 0 ]
    EXPECTED="docker-compose called with --file docker-compose.yaml up"
    [[ "$output" == *"$EXPECTED"* ]]
    [ -f "$CHECKOUT_DIRECTORY/docker-compose.yaml" ]
}

@test "download_docker_compose.sh skips verification if requested" {
    export CHECKOUT_DIRECTORY="$TEST_TEMP_DIR/checkout_skip"
    mkdir -p "$CHECKOUT_DIRECTORY"
    touch "$CHECKOUT_DIRECTORY/docker-compose.yaml"
    export SKIP_VERIFICATION="TRUE"

    run bash scripts/download_docker_compose.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"SKIPPED Verification"* ]]
}
