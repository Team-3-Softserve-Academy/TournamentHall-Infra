#!/bin/bash
set -euo pipefail

SERVER_PRIVATE_IP = "192.168.56.254"

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

# Generate gossip encryption key
if [ ! -f /etc/consul.d/gossip.key ]; then
  consul keygen | sudo tee /etc/consul.d/gossip.key > /dev/null
fi

# Configure Consul server
sudo tee /etc/consul.d/server.hcl > /dev/null <<EOF
server = true
bootstrap_expect = 1
ui_config {
 enabled = false
}
client_addr = "0.0.0.0"
bind_addr = "${SERVER_PRIVATE_IP}"
data_dir = "/opt/consul"
encrypt = "$(cat /etc/consul.d/gossip.key)"
retry_join = ["${SERVER_PRIVATE_IP}"]
EOF

# Start Consul
sudo systemctl daemon-reload
sudo systemctl enable consul
sudo systemctl start consul

consul members
consul catalog services

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