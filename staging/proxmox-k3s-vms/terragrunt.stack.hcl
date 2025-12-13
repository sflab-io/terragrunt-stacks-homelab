locals {
  version = "main"

  # Load environment variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # Extract variables we need for easy access
  environment_name = local.environment_vars.locals.environment_name

  # Use environment_name in stack name
  pool_id = "pool-${local.environment_name}"

  app = "k3s"
  zone = "home.sflab.io."

  # SSH public key path for Ansible access
  ssh_public_key_path = "${get_terragrunt_dir()}/../../keys/admin_id_ecdsa.pub"
}

unit "vm_cp1" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"

  path = "${local.app}-cp1"

  values = {
    version = local.version

    env = local.environment_name
    app = "${local.app}-cp1"

    pool_id = local.pool_id
    ssh_public_key_path = local.ssh_public_key_path
    network_config = {
      type = "dhcp"
    }
  }
}

unit "dns_cp1" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.version}"

  path = "dns-cp1"

  values = {
    version = local.version

    env = local.environment_name
    app = "${local.app}-cp1"

    zone = local.zone

    compute_path = "../${local.app}-cp1"
  }
}

# unit "vm_cp2" {
#   source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"

#   path = "${local.app}-cp2"

#   values = {
#     version = local.version

#     env = local.environment_name
#     app = "${local.app}-cp2"

#     pool_id = local.pool_id
#     ssh_public_key_path = local.ssh_public_key_path
#     network_config = {
#       type = "dhcp"
#     }
#   }
# }

# unit "dns_cp2" {
#   source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.version}"

#   path = "dns-cp2"

#   values = {
#     version = local.version

#     env = local.environment_name
#     app = "${local.app}-cp2"

#     zone = local.zone

#     compute_path = "../${local.app}-cp2"
#   }
# }

# unit "vm_cp3" {
#   source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"

#   path = "${local.app}-cp3"

#   values = {
#     version = local.version

#     env = local.environment_name
#     app = "${local.app}-cp3"

#     pool_id = local.pool_id
#     ssh_public_key_path = local.ssh_public_key_path
#     network_config = {
#       type = "dhcp"
#     }
#   }
# }

# unit "dns_cp3" {
#   source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.version}"

#   path = "dns-cp3"

#   values = {
#     version = local.version

#     env = local.environment_name
#     app = "${local.app}-cp3"

#     zone = local.zone

#     compute_path = "../${local.app}-cp3"
#   }
# }

unit "vm_w1" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"

  path = "${local.app}-w1"

  values = {
    version = local.version

    env = local.environment_name
    app = "${local.app}-w1"

    pool_id = local.pool_id
    ssh_public_key_path = local.ssh_public_key_path
    network_config = {
      type = "dhcp"
    }
  }
}

unit "dns_w1" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.version}"

  path = "dns-w1"

  values = {
    version = local.version

    env = local.environment_name
    app = "${local.app}-w1"

    zone = local.zone

    compute_path = "../${local.app}-w1"
  }
}
