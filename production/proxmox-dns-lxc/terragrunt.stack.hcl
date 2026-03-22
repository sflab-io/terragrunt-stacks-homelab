locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "technitium-dns-secondary"

  network_config = {
    type        = "static"
    ip_address  = "192.168.1.154"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.154"]
    domain      = "${local.env.zone}"
  }

  #
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
  role_name    = "DNS Secondary"
}

stack "proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-lxc?ref=${local.env.catalog_version}"

  path   = "dns"

  values = {
    version             = local.env.catalog_version
    env                 = local.env.environment_name
    app                 = local.app
    network_config      = local.network_config
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
    role_name    = local.role_name_dns2
  }
}
