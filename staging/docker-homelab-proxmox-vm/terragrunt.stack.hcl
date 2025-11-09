locals {
  version = "feat/next"

  # Load environment variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # Extract variables we need for easy access
  environment_name = local.environment_vars.locals.environment_name

  # Use environment_name in stack name
  pool_id = "pool-${local.environment_name}"

  vm_name = "docker-vm-${local.environment_name}"

  zone = try(values.dns_zone, "${local.environment_name}.home.sflab.io.")
}

unit "proxmox_vm" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"

  path = "proxmox-vm"

  values = {
    version = local.version

    vm_name = local.vm_name
    pool_id = local.pool_id

    pool_unit_path = "../proxmox-pool"
  }
}

# unit "dns" {
#   source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns"

#   path = "dns"

#   values = {
#     version = local.version

#     zone          = local.zone
#     name          = local.vm_name

#     vm_unit_path  = "../proxmox-vm"
#   }
# }
