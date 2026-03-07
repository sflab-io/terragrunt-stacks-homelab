locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
  app = "github-runner"
}

unit "proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${local.env.catalog_version}"

  path = "proxmox-lxc"

  values = {
    version = local.env.catalog_version
    app     = local.app
    env     = local.env.environment_name

    network_config = {
      type = "dhcp"
    }

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path
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
      wildcard = false
    }
    zone         = local.env.zone
    compute_path = "../proxmox-lxc"
  }
}
