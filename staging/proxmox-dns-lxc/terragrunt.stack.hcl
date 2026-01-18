locals {
  version = "main"

  # Load environment variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # Extract variables we need for easy access
  environment_name = local.environment_vars.locals.environment_name

  # default VM specs
  memory = 2048
  cores  = 2

  # Use environment_name in stack name
  pool_id = "pool-${local.environment_name}"

  app = "technitium-dns"
  zone = "home.sflab.io."

  # SSH public key path for Ansible access
  ssh_public_key_path = "${get_terragrunt_dir()}/../../keys/admin_id_ecdsa.pub"
}

unit "proxmox_lxc_1" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${local.version}"

  path = "proxmox-lxc-1"

  values = {
    version = local.version

    app = "${local.app}-1"
    env = local.environment_name

    network_config = {
      type        = "static"
      ip_address  = "192.168.1.153"
      cidr        = 24
      gateway     = "192.168.1.1"
      dns_servers = ["192.168.1.1"]
    }

    pool_id = local.pool_id

    ssh_public_key_path = local.ssh_public_key_path
  }
}

unit "proxmox_lxc_2" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${local.version}"

  path = "proxmox-lxc-2"

  values = {
    version = local.version

    app = "${local.app}-2"
    env = local.environment_name

    network_config = {
      type        = "static"
      ip_address  = "192.168.1.154"
      cidr        = 24
      gateway     = "192.168.1.1"
      dns_servers = ["192.168.1.1"]
    }

    pool_id = local.pool_id

    ssh_public_key_path = local.ssh_public_key_path
  }
}
