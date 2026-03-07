locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "vault"
  # Optional: Customize VM resources
  memory    = 4096
  disk_size = 8
  # Optional: Customize network configuration
  network_config = {
    type        = "static"
    ip_address  = "192.168.1.33"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "home.sflab.io"
  }
  # Optional: Customize DNS record types
  record_types = {
    normal   = true
    wildcard = false
  }
}

unit "proxmox_vm" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.env.catalog_version}"

  path = "proxmox-vm"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    network_config = local.network_config

    memory    = local.memory
    disk_size = local.disk_size

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.ansible_ssh_public_key_path
  }
}

unit "dns" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.env.catalog_version}"

  path = "dns"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    record_types = local.record_types
    zone         = local.env.zone

    compute_path = "../proxmox-vm"
  }
}
