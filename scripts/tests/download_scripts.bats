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
    mkdir -p "\$TARGET_DIR/scripts"
    mkdir -p "\$TARGET_DIR/public_key"
    touch "\$TARGET_DIR/scripts/test.sh"
    echo "test" > "\$TARGET_DIR/scripts/test.sh"
    (cd "\$TARGET_DIR/scripts" && sha256sum test.sh > scripts.sha256)
    touch "\$TARGET_DIR/public_key/cosign.pub"
fi
EOF
    chmod +x "$MOCK_BIN/git"

    # Mock docker
    cat <<EOF > "$MOCK_BIN/docker"
#!/usr/bin/env bash
echo "docker called with \$*" >&2
EOF
    chmod +x "$MOCK_BIN/docker"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "download_scripts.sh downloads and replaces scripts correctly" {
    export CHECKOUT_DIRECTORY="$TEST_TEMP_DIR/checkout"
    mkdir -p "$CHECKOUT_DIRECTORY"
    mkdir -p "$CHECKOUT_DIRECTORY/scripts"
    touch "$CHECKOUT_DIRECTORY/scripts/old.sh"

    run bash scripts/download_scripts.sh
    [ "$status" -eq 0 ]
    [ -f "$CHECKOUT_DIRECTORY/scripts/test.sh" ]
    [ ! -f "$CHECKOUT_DIRECTORY/scripts/old.sh" ]
}

@test "download_scripts.sh skips verification if requested" {
    export CHECKOUT_DIRECTORY="$TEST_TEMP_DIR/checkout_skip"
    mkdir -p "$CHECKOUT_DIRECTORY"
    export SKIP_VERIFICATION="TRUE"

    run bash scripts/download_scripts.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"SKIPPED Verification"* ]]
}
