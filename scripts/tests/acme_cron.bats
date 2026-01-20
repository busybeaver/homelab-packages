#!/usr/bin/env bats

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Mock docker
    cat <<EOF > "$MOCK_BIN/docker"
#!/usr/bin/env bash
echo "docker called with \$*"
EOF
    chmod +x "$MOCK_BIN/docker"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "acme_cron.sh calls acme_run.sh with --cron" {
    export HOMELAB_PACKAGES_CONFIG_FOLDER="$TEST_TEMP_DIR/config"
    mkdir -p "$HOMELAB_PACKAGES_CONFIG_FOLDER"

    run bash scripts/acme_cron.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"docker called with run"* ]]
    [[ "$output" == *"--cron --insecure"* ]]
}
