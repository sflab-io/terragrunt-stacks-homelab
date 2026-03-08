locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "example-lxc"
}

stack "homelab_proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-lxc?ref=${local.env.catalog_version}"
  path   = "homelab-proxmox-lxc"

  values = {
    version = "${local.env.catalog_version}"

    env = local.env.environment_name
    app = local.app

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    zone = local.env.zone
  }
}
