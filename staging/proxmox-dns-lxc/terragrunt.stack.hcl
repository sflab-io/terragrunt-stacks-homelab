locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "technitium-dns"

  network_config_1 = {
    type        = "static"
    ip_address  = "192.168.1.153"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "home.sflab.io"
  }
  network_config_2 = {
    type        = "static"
    ip_address  = "192.168.1.154"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "home.sflab.io"
  }
}

stack "proxmox_lxc_1" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-lxc?ref=${local.env.catalog_version}"

  path   = "dns-1"

  values = {
    version             = local.env.catalog_version
    env                 = local.env.environment_name
    app                 = "${local.app}-1"
    network_config      = local.network_config_1
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
  }
}

stack "proxmox_lxc_2" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-lxc?ref=${local.env.catalog_version}"

  path   = "dns-2"

  values = {
    version             = local.env.catalog_version
    env                 = local.env.environment_name
    app                 = "${local.app}-2"
    network_config      = local.network_config_2
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
  }
}
