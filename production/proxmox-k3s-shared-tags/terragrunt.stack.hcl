locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "k3s"
}

unit "k3s_shared_tags" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//units/netbox-tags?ref=${local.env.catalog_version}"

  path = "k3s-shared-tags"

  values = {
    version = local.env.catalog_version
    tags    = ["${local.app}-${local.env.environment_name}"]
  }
}
