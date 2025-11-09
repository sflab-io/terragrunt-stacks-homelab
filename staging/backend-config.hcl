locals {
  prefix  = "staging-terragrunt"

  region = "eu-central-1"
  endpoint  = "http://minio.home.sflab.io:9000"
  skip_credentials_validation = true
  force_path_style = true
  access_key = get_env("AWS_ACCESS_KEY_ID")
  secret_key = get_env("AWS_SECRET_ACCESS_KEY")
}
