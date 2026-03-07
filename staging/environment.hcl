# Set environment wide variables. These are automatically pulled in to configure the remote state bucket in the root
# root.hcl configuration.
locals {
  environment_name = "staging"
  pool_id          = "pool-${local.environment_name}"

  # Shared catalog configuration
  # Tracks latest catalog changes. Promotes to production after validation.
  catalog_version = "main"
  zone            = "home.sflab.io."

  # SSH public key paths
  ansible_ssh_public_key_path = "${get_terragrunt_dir()}/../keys/ansible_id_ecdsa.pub"
  admin_ssh_public_key_path   = "${get_terragrunt_dir()}/../keys/admin_id_ecdsa.pub"
}
