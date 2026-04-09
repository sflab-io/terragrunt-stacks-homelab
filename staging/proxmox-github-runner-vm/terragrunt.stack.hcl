locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "github-runner"
  cpu_type  = "host" # running dagger on gitlab runner requires VM CPU-Typ 'host' instead of 'qemu64' (default)

  network_config = {
    type = "dhcp"
  }

  record_types = {
    normal   = true
    wildcard = false
  }

  #
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
}

stack "homelab_proxmox_vm" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path = "homelab-proxmox-vm"

  values = {
    version = local.env.catalog_version

    app = local.app
    env = local.env.environment_name

    cpu_type = local.cpu_type

    network_config = local.network_config

    record_types = local.record_types

    dns_zone = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
  }
}
