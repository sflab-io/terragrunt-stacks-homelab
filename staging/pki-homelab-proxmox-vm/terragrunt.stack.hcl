locals {
  # Load environment variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # Extract variables we need for easy access
  environment_name = local.environment_vars.locals.environment_name

  # Use environment_name in stack name
  name = "pki-homelab-proxmox-vm-${local.environment_name}"
}

unit "proxmox_vm" {
  // You'll typically want to pin this to a particular version of your catalog repo.
  // e.g.
  // source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=v0.1.0"
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm"

  path = "proxmox-vm"

  values = {
    // This version here is used as the version passed down to the unit
    // to use when fetching the OpenTofu/Terraform module.
    version = "main"

    vm_name = "vm-pki-${local.environment_name}"
    pool_id = "pool-${local.environment_name}"
  }
}

unit "dns" {
  // You'll typically want to pin this to a particular version of your catalog repo.
  // e.g.
  // source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v0.1.0"
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns"

  path = "dns"

  values = {
    // This version here is used as the version passed down to the unit
    // to use when fetching the OpenTofu/Terraform module.
    version = "main"

    zone          = "home.sflab.io."
    name          = local.environment_name == "staging" ? "pki.staging" : "pki"
    dns_server    = "192.168.1.13"
    dns_port      = 5353
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha512"

    vm_unit_path  = "../proxmox-vm"
  }
}
