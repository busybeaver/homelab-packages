#!/bin/bash
set -x

sudo mkdir -p "/var/snap/${SERVICE_NAME}/current/config/data"
echo "
bind_addr = \"{{ GetInterfaceIP \\\"eth0\\\" }}\"
data_dir = \"/var/snap/${SERVICE_NAME}/current/config/data\"
log_level = \"INFO\"
datacenter = \"github_actions\"
node_name = \"runner\"
server = true
" | sudo tee "/var/snap/${SERVICE_NAME}/current/config/test.hcl"
