locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app       = "netbox"
  memory    = 4096
  disk_size = 16

  network_config = {
    type        = "static"
    ip_address  = "192.168.1.88"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "home.sflab.io"
  }

  record_types = {
    normal   = true
    wildcard = true
  }
}

stack "homelab_proxmox_vm" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path   = "homelab-proxmox-vm"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    memory    = local.memory
    disk_size = local.disk_size

    network_config = local.network_config

    record_types = local.record_types

    dns_zone = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.ansible_ssh_public_key_path

    # Set to empty list to avoid try to add the vm to netbox before netbox is available.
    virtual_machines = []
  }
}
