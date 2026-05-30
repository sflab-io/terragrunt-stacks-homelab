locals {
  netbox_server_url = "http://netbox.home.sflab.io"
  netbox_skip_version_check = true
  netbox_token              = get_env("NETBOX_API_TOKEN_PRODUCTION")
  # optional: if you have a separate staging instance of netbox, set the url here. otherwise it will default to the production instance.
  # netbox_server_url = "http://netbox-staging.home.sflab.io"
  # netbox_token      = get_env("NETBOX_API_TOKEN_STAGING")
}
