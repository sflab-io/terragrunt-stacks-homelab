# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # proxmox_endpoint = "https://proxmox.home.sflab.io:8006/"
  proxmox_endpoint = "https://192.168.1.12:8006/"
}

# Generate Proxmox provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "proxmox" {
  endpoint  = "${local.proxmox_endpoint}"
  insecure  = true

  ssh {
    agent = true
  }
}
EOF
}
