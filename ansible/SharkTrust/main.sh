#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 hostname [ssh-user] [ansible-options...]" >&2
  exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export ANSIBLE_CONFIG="$script_dir/ansible.cfg"

args=(-i "$1," "$script_dir/main.yaml")
host=$1
shift
if [ "$#" -gt 0 ] && [[ "$1" != -* ]]; then
  args+=(-e "ansible_user=$1")
  shift
fi

echo "Installing/upgrading SharkTrust on $host"
ansible-playbook "${args[@]}" "$@"
