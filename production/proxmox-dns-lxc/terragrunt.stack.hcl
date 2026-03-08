locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "technitium-dns-secondary"
  network_config = {
    type        = "static"
    ip_address  = "192.168.1.154"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "home.sflab.io"
  }
}

unit "proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//units/proxmox-lxc?ref=${local.env.catalog_version}"

  path = "proxmox-lxc"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    network_config = local.network_config

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
  }
}
