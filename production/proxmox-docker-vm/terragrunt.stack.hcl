locals {
  version = "main"

  # Load environment variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # Extract variables we need for easy access
  environment_name = local.environment_vars.locals.environment_name

  # Use environment_name in stack name
  pool_id = "pool-${local.environment_name}"

  app = "docker"
  zone = "home.sflab.io."

  # SSH public key path for Ansible access
  ssh_public_key_path = "${get_terragrunt_dir()}/../../keys/ansible_id_ecdsa.pub"
}

unit "proxmox_vm" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"

  path = "proxmox-vm"

  values = {
    version = local.version

    env = local.environment_name
    app = local.app

    pool_id = local.pool_id
    ssh_public_key_path = local.ssh_public_key_path
    # network_config = {
    #   type = "dhcp"
    # }
  }
}

unit "dns" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.version}"

  path = "dns"

  values = {
    version = local.version

    app = local.app
    env = local.environment_name

    record_types = {
      normal   = true
      wildcard = true
    }
    zone = local.zone

    compute_path = "../proxmox-vm"
  }
}
