#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 host-or-ip [public-key-file]" >&2
  exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v sshpass >/dev/null 2>&1; then
  echo "sshpass is required for initial root-password login." >&2
  echo "Install it with: sudo apt-get install sshpass" >&2
  exit 1
fi

# Ansible rejects ansible.cfg when the repository is on a Windows-mounted,
# world-writable WSL directory. Use a private temporary copy so the settings
# are honored in WSL2 and on native Linux.
ansible_config=$(mktemp --suffix=.cfg)
trap 'rm -f "$ansible_config"' EXIT
install -m 600 "$script_dir/ansible.cfg" "$ansible_config"
export ANSIBLE_CONFIG="$ansible_config"

public_key_file=${2:-}
if [ -z "$public_key_file" ]; then
  for candidate in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
    if [ -r "$candidate" ]; then
      public_key_file=$candidate
      break
    fi
  done
fi

if [ -z "$public_key_file" ] || [ ! -r "$public_key_file" ]; then
  echo "Cannot find a readable SSH public key." >&2
  echo "Pass its path as the second argument." >&2
  exit 1
fi

export SHARKTRUST_PUBLIC_KEY_FILE="$public_key_file"

echo "First-time Ansible preparation for $1"
echo "Deployment public key: $public_key_file"
ansible-playbook -u root --ask-pass -i "$1," "$script_dir/main.yaml"
