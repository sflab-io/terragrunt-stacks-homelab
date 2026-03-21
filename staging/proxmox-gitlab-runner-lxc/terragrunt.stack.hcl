locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "gitlab-runner"

  network_config = {
    type = "dhcp"
  }

  record_types = {
    normal   = true
    wildcard = false
  }
}

stack "homelab_proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-lxc?ref=${local.env.catalog_version}"
  path   = "homelab-proxmox-lxc"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    network_config = local.network_config

    record_types = local.record_types

    dns_zone = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
  }
}
