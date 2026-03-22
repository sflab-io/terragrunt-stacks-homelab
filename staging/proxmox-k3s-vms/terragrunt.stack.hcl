locals {
  env    = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app    = "k3s"
  memory = 4096
  cores  = 2

  record_types = {
    normal   = true
    wildcard = false
  }

  #
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
  role_name_cp = "Control Plane"
  role_name_w  = "Worker"
}

stack "vm_cp1" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-cp1"

  values = {
    version             = local.env.catalog_version
    app                 = "${local.app}-cp1"
    env                 = local.env.environment_name
    cores               = local.cores
    memory              = local.memory
    record_types        = local.record_types
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
    role_name    = local.role_name_cp
  }
}

stack "vm_w1" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-w1"

  values = {
    version             = local.env.catalog_version
    app                 = "${local.app}-w1"
    env                 = local.env.environment_name
    cores               = local.cores
    memory              = local.memory
    record_types        = local.record_types
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
    role_name    = local.role_name_w
  }
}
