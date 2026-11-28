#!/bin/bash
set -euo pipefail

SERVER_PRIVATE_IP="192.168.56.254"
CLIENT_PRIVATE_IP="192.168.56.3"
SERVICE_NAME="app"
SERVICE_PORT=5000

# Install Consul
sudo apt install -y curl gnupg
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg |
    sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$UBUNTU_CODENAME") main" |
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt update
sudo apt install -y consul

sudo mkdir -p /etc/consul.d

# Configure Consul client
sudo tee /etc/consul.d/client.hcl > /dev/null <<EOF
server     = false
bind_addr  = "${CLIENT_PRIVATE_IP}"
data_dir   = "/opt/consul"
retry_join = ["${SERVER_PRIVATE_IP}"]
encrypt    = ""
EOF

# Create Consul systemd service
sudo tee /etc/systemd/system/consul-client.service > /dev/null <<'EOF'
[Unit]
Description=Consul Client Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# Register specific service through agent configuration
sudo tee /etc/consul.d/service.hcl > /dev/null <<EOF
service {
  name    = "${SERVICE_NAME}"
  id      = "${SERVICE_NAME}"
  address = "${CLIENT_PRIVATE_IP}"
  port    = ${SERVICE_PORT}
  tags    = ["${SERVICE_NAME}"]
}
EOF

# Start Consul
sudo systemctl daemon-reload
sudo systemctl enable consul-client
sudo systemctl restart consul-client

# Check Consul
sudo systemctl status consul-client --no-pager

# Configure Consul service discovery and DNS resolution
sudo mkdir -p /etc/systemd/resolved.conf.d

sudo tee /etc/systemd/resolved.conf.d/consul.conf > /dev/null <<'EOF'
[Resolve]
DNS=127.0.0.1:8600
DNSSEC=false
Domains=~consul
EOF

sudo systemctl restart systemd-resolved

# Verify DNS
systemctl is-active systemd-resolved
resolvectl status
