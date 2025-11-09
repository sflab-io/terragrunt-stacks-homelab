# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  dns_server = "192.168.1.13"
  dns_port   = 53
  dns_key_name   = "ddnskey."
  dns_key_algorithm = "hmac-sha256"
}

# Generate DNS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "dns_key_secret" {
  description = "TSIG key secret for DNS authentication"
  type        = string
  sensitive   = true
}

provider "dns" {
  update {
    server        = "${local.dns_server}"
    port          = ${local.dns_port}
    key_name      = "${local.dns_key_name}"
    key_algorithm = "${local.dns_key_algorithm}"
    key_secret    = var.dns_key_secret
  }
}
EOF
}
