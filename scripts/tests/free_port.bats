#!/usr/bin/env bats

setup() {
    # Create a temporary directory for our mock Synology environment
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR

    # Mock Synology directories
    export NGINX_MUSTACHE_DIR="$TEST_TEMP_DIR/usr/syno/share/nginx"
    mkdir -p "$NGINX_MUSTACHE_DIR"

    # Mock backup directory
    export BACKUP_DIR="$TEST_TEMP_DIR/volume1/apps/free_ports/backup"
    mkdir -p "$BACKUP_DIR"

    # Create fake mustache files
    cat <<EOF > "$NGINX_MUSTACHE_DIR/test1.mustache"
    listen 80;
    listen [::]:80;
EOF
    cat <<EOF > "$NGINX_MUSTACHE_DIR/test2.mustache"
    listen 443;
    listen [::]:443;
EOF

    # Mock commands by adding a bin to PATH
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    export PATH="$MOCK_BIN:$PATH"

    # Mock id to return root by default if requested
    cat <<EOF > "$MOCK_BIN/id"
#!/usr/bin/env bash
if [[ "\$*" == "-u" ]]; then
  echo "\${MOCK_EUID:-1001}"
else
  /usr/bin/id "\$@"
fi
EOF
    chmod +x "$MOCK_BIN/id"

    # Mock synoservicecfg and synosystemctl
    cat <<EOF > "$MOCK_BIN/synoservicecfg"
#!/usr/bin/env bash
echo "synoservicecfg called with \$*"
EOF
    chmod +x "$MOCK_BIN/synoservicecfg"

    cat <<EOF > "$MOCK_BIN/synosystemctl"
#!/usr/bin/env bash
echo "synosystemctl called with \$*"
EOF
    chmod +x "$MOCK_BIN/synosystemctl"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "free_port.sh fails if not root" {
    run env MOCK_EUID=1001 bash scripts/free_port.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"This script must be run as root"* ]]
}

@test "free_port.sh updates ports correctly when run as root" {
    run env MOCK_EUID=0 \
        NGINX_MUSTACHE_DIR="$NGINX_MUSTACHE_DIR" \
        BACKUP_DIR="$BACKUP_DIR" \
        bash scripts/free_port.sh
    [ "$status" -eq 0 ]

    grep "listen 81;" "$NGINX_MUSTACHE_DIR/test1.mustache"
    grep "listen 444;" "$NGINX_MUSTACHE_DIR/test2.mustache"

    # Check if backup was created
    [ "$(ls -A "$BACKUP_DIR")" ]
}

@test "free_port.sh updates to custom ports correctly" {
    run env MOCK_EUID=0 \
        HTTP_PORT=8080 HTTPS_PORT=8443 \
        NGINX_MUSTACHE_DIR="$NGINX_MUSTACHE_DIR" \
        BACKUP_DIR="$BACKUP_DIR" \
        bash scripts/free_port.sh
    [ "$status" -eq 0 ]

    grep "listen 8080;" "$NGINX_MUSTACHE_DIR/test1.mustache"
    grep "listen 8443;" "$NGINX_MUSTACHE_DIR/test2.mustache"
}

@test "free_port.sh uses synosystemctl if synoservicecfg is missing" {
    rm "$MOCK_BIN/synoservicecfg"
    run env MOCK_EUID=0 \
        NGINX_MUSTACHE_DIR="$NGINX_MUSTACHE_DIR" \
        BACKUP_DIR="$BACKUP_DIR" \
        bash scripts/free_port.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"synosystemctl called with restart nginx"* ]]
}
