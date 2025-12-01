locals {
  version = "main"

  # Load environment variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # Extract variables we need for easy access
  environment_name = local.environment_vars.locals.environment_name

  # Use environment_name in stack name
  pool_id = "pool-${local.environment_name}"
}

unit "proxmox_pool" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${local.version}"

  path = "proxmox-pool"

  values = {
    // This version here is used as the version passed down to the unit
    // to use when fetching the OpenTofu/Terraform module.
    version = local.version

    pool_id = "pool-${local.environment_name}"
  }
}
