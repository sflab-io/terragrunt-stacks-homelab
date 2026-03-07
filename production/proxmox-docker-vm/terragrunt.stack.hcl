locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
  app = "docker"
}

unit "proxmox_vm" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.env.catalog_version}"

  path = "proxmox-vm"

  values = {
    version             = local.env.catalog_version
    app                 = local.app
    env                 = local.env.environment_name
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.ansible_ssh_public_key_path
  }
}

unit "dns" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.env.catalog_version}"

  path = "dns"

  values = {
    version = local.env.catalog_version
    app     = local.app
    env     = local.env.environment_name

    record_types = {
      normal   = true
      wildcard = true
    }
    zone         = local.env.zone
    compute_path = "../proxmox-vm"
  }
}
