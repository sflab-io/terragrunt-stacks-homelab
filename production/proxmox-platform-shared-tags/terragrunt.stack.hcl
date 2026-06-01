locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app = "platform"
}

unit "platform_shared_tags" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//units/netbox-tags?ref=${local.env.catalog_version}"

  path = "platform-shared-tags"

  values = {
    version = local.env.catalog_version
    tags    = ["${local.app}-${local.env.environment_name}"]
  }
}
