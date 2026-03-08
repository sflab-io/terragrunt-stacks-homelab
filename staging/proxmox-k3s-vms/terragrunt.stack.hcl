locals {
  env    = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
  app    = "k3s"
  memory = 4096
  cores  = 2

  record_types = {
    normal   = true
    wildcard = false
  }
}

unit "vm_cp1" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-cp1"

  values = {
    version             = local.env.catalog_version
    env                 = local.env.environment_name
    app                 = "${local.app}-cp1"
    cores               = local.cores
    memory              = local.memory
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
  }
}

unit "dns_cp1" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.env.catalog_version}"

  path = "dns-cp1"

  values = {
    version = local.env.catalog_version
    env     = local.env.environment_name
    app     = "${local.app}-cp1"

    record_types = local.record_types
    zone         = local.env.zone
    compute_path = "../${local.app}-cp1"
  }
}

unit "vm_w1" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-w1"

  values = {
    version             = local.env.catalog_version
    env                 = local.env.environment_name
    app                 = "${local.app}-w1"
    cores               = local.cores
    memory              = local.memory
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
  }
}

unit "dns_w1" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.env.catalog_version}"

  path = "dns-w1"

  values = {
    version = local.env.catalog_version
    env     = local.env.environment_name
    app     = "${local.app}-w1"

    record_types = local.record_types
    zone         = local.env.zone
    compute_path = "../${local.app}-w1"
  }
}
