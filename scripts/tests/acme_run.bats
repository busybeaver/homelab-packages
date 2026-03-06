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

@test "acme_run.sh runs docker with provided arguments" {
    export GLOBAL_ENV_FILE="$TEST_TEMP_DIR/global.env"
    export ENV_FILE="$TEST_TEMP_DIR/local.env"
    touch "$GLOBAL_ENV_FILE" "$ENV_FILE"

    run bash scripts/acme_run.sh --issue -d example.com
    [ "$status" -eq 0 ]
    [[ "$output" == *"docker called with run"* ]]
    [[ "$output" == *"--issue -d example.com"* ]]
    [[ "$output" == *"--env-file $GLOBAL_ENV_FILE"* ]]
    [[ "$output" == *"--env-file $ENV_FILE"* ]]
}
