#!/usr/bin/env bats

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Mock curl
    cat <<EOF > "$MOCK_BIN/curl"
#!/usr/bin/env bash
touch doppler_linux_amd64.tar.gz
EOF
    chmod +x "$MOCK_BIN/curl"

    # Mock tar
    cat <<EOF > "$MOCK_BIN/tar"
#!/usr/bin/env bash
# tar -xvzf doppler_linux_amd64.tar.gz
# We create the doppler binary that the script expects
cat <<EOD > doppler
#!/usr/bin/env bash
echo "doppler version 3.68.0"
EOD
chmod +x doppler
EOF
    chmod +x "$MOCK_BIN/tar"

    # Mock sudo
    cat <<EOF > "$MOCK_BIN/sudo"
#!/usr/bin/env bash
"\$@"
EOF
    chmod +x "$MOCK_BIN/sudo"

    # Mock chown
    cat <<EOF > "$MOCK_BIN/chown"
#!/usr/bin/env bash
echo "chown called with \$*"
EOF
    chmod +x "$MOCK_BIN/chown"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "doppler_init.sh installs doppler correctly" {
    export DOPPLER_INSTALL_PATH="$TEST_TEMP_DIR/usr_local_bin_doppler"
    run bash scripts/doppler_init.sh
    [ "$status" -eq 0 ]
    [ -f "$DOPPLER_INSTALL_PATH" ]
    [[ "$output" == *"Installing Doppler CLI..."* ]]
}
