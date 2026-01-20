#!/usr/bin/env bats

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Mock sudo
    cat <<EOF > "$MOCK_BIN/sudo"
#!/usr/bin/env bash
"\$@"
EOF
    chmod +x "$MOCK_BIN/sudo"

    # Mock chgrp
    cat <<EOF > "$MOCK_BIN/chgrp"
#!/usr/bin/env bash
echo "chgrp called with \$*"
EOF
    chmod +x "$MOCK_BIN/chgrp"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "update_docker_socks.sh fails if socket missing" {
    export DOCKER_SOCK="$TEST_TEMP_DIR/nonexistent.sock"
    run bash scripts/update_docker_socks.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"is not a socket or does not exist"* ]]
}

@test "update_docker_socks.sh updates group correctly" {
    export DOCKER_SOCK="$TEST_TEMP_DIR/docker.sock"
    # Create a fake socket using python
    python3 -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.bind('$DOCKER_SOCK')"

    export DOCKER_GROUP="test-group"
    run bash scripts/update_docker_socks.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Changing group of $DOCKER_SOCK to test-group"* ]]
    [[ "$output" == *"chgrp called with test-group $DOCKER_SOCK"* ]]
}
