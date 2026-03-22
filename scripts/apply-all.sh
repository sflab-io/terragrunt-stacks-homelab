#!/usr/bin/env bash

STACKS=(
  "proxmox-pool"
  "proxmox-dns-lxc"
  "proxmox-docker-vm"
  "proxmox-example-lxc"
  "proxmox-example-vm"
  "proxmox-github-runner-vm"
  "proxmox-gitlab-runner-vm"
  "proxmox-k3s-vms"
  "proxmox-netbox-vm"
  "proxmox-vault-vm"
)

for STACK in "${STACKS[@]}"; do
  echo "Applying stack: $STACK"
  mise run terragrunt:stack:apply staging "$STACK" -y
done
