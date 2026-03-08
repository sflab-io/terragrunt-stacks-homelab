locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "docker"
}

stack "homelab_proxmox_vm" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"
  path   = "homelab-proxmox-vm"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    memory    = 2048
    disk_size = 8

    network_config = {
      type = "dhcp"
    }

    record_types = {
      normal   = true
      wildcard = true
    }

    dns_zone = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.ansible_ssh_public_key_path
  }
}
