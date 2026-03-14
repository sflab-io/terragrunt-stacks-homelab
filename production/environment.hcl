# Set environment wide variables.
# These are automatically pulled in to provide default values for units in this stack.
locals {
  environment_name = "production"
  pool_id          = "pool-${local.environment_name}"

  # Shared catalog configuration
  # Pin to a specific tag for production stability. Update deliberately after testing in staging.
  catalog_version = "v0.4.0"
  zone            = "home.sflab.io."

  # SSH public key paths
  ansible_ssh_public_key_path = "${get_terragrunt_dir()}/../keys/ansible_id_ecdsa.pub"
  admin_ssh_public_key_path   = "${get_terragrunt_dir()}/../keys/admin_id_ecdsa.pub"
}
