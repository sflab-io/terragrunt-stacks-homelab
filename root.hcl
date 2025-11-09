locals {
  s3_backend_vars = read_terragrunt_config(find_in_parent_folders("backend-config.hcl"))

  s3_backend_prefix                      = local.s3_backend_vars.locals.prefix
  s3_backend_region                      = local.s3_backend_vars.locals.region
  s3_backend_endpoint                    = local.s3_backend_vars.locals.endpoint
  s3_backend_skip_credentials_validation = local.s3_backend_vars.locals.skip_credentials_validation
  s3_backend_force_path_style            = local.s3_backend_vars.locals.force_path_style
  s3_backend_access_key                  = local.s3_backend_vars.locals.access_key
  s3_backend_secret_key                  = local.s3_backend_vars.locals.secret_key
}

# Generate the remote backend
remote_state {
  backend = "s3"

  config = {
    bucket                      = "${local.s3_backend_prefix}-tfstates"
    key                         = "${path_relative_to_include()}/tofu.tfstate"
    region                      = local.s3_backend_region
    endpoint                    = local.s3_backend_endpoint
    skip_credentials_validation = local.s3_backend_skip_credentials_validation
    force_path_style            = local.s3_backend_force_path_style
    access_key                  = local.s3_backend_access_key
    secret_key                  = local.s3_backend_secret_key
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure what repositories to search when you run 'terragrunt catalog'
catalog {
  urls = [
    "https://github.com/abes140377/terragrunt-infrastructure-catalog-homelab.git",
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
# inputs = merge(
#   local.environment_vars.locals,
#   # local.region_vars.locals,
# )
