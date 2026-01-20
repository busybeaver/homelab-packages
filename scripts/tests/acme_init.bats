#!/usr/bin/env bats

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Mock docker (since acme_run.sh calls it)
    cat <<EOF > "$MOCK_BIN/docker"
#!/usr/bin/env bash
echo "docker called with \$*"
EOF
    chmod +x "$MOCK_BIN/docker"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "acme_init.sh calls acme_run.sh for synology if requested" {
    export ROOT_DOMAIN="example.com"
    export INIT_SYNOLOGY="TRUE"
    export HOMELAB_PACKAGES_CONFIG_FOLDER="$TEST_TEMP_DIR/config"
    mkdir -p "$HOMELAB_PACKAGES_CONFIG_FOLDER/env_files"
    touch "$HOMELAB_PACKAGES_CONFIG_FOLDER/env_files/cf.env"
    touch "$HOMELAB_PACKAGES_CONFIG_FOLDER/env_files/syno.env"

    run bash scripts/acme_init.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"--- Initialize certificate renewal setup for Synology 1 ---"* ]]
    [[ "$output" == *"docker called with run"* ]]
    [[ "$output" == *"nas1.example.com"* ]]
}

@test "acme_init.sh calls acme_run.sh for fritzbox if requested" {
    export ROOT_DOMAIN="example.com"
    export INIT_FRITZ_BOX="TRUE"
    export HOMELAB_PACKAGES_CONFIG_FOLDER="$TEST_TEMP_DIR/config"
    mkdir -p "$HOMELAB_PACKAGES_CONFIG_FOLDER/env_files"
    touch "$HOMELAB_PACKAGES_CONFIG_FOLDER/env_files/cf.env"
    touch "$HOMELAB_PACKAGES_CONFIG_FOLDER/env_files/fritz-box.env"

    run bash scripts/acme_init.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"--- Initialize certificate renewal setup for Fritz!Box ---"* ]]
    [[ "$output" == *"--keylength 4096"* ]]
}
