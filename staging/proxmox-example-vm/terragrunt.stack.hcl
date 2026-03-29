locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app       = "example-vm"
  memory    = 4096
  disk_size = 8000

  network_config = {
    type        = "static"
    ip_address  = "192.168.1.45"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "${local.env.zone}"
  }

  record_types = {
    normal   = true
    wildcard = false
  }

  #
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
  role_name    = "Example VM"
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

    #
    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
    role_name    = local.role_name
  }
}
