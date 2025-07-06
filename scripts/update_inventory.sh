#!/usr/bin/env bash
set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
IP=$(tofu -chdir=infra output -raw instance_ip)
cat > ansible/inventory.ini <<EOL
[minecraft]
${IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
EOL
printf "Inventory updated with IP: %s\n" "$IP"

