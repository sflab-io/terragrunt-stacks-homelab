locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
}

unit "proxmox_pool" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//units/proxmox-pool?ref=${local.env.catalog_version}"

  path = "proxmox-pool"

  values = {
    # This version here is used as the version passed down to the unit
    # to use when fetching the OpenTofu/Terraform module.
    version = local.env.catalog_version

    pool_id = local.env.pool_id
  }
}
