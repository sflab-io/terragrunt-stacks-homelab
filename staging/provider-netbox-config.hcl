locals {
  netbox_server_url = "http://netbox.home.sflab.io"
  netbox_skip_version_check = true
  netbox_token              = get_env("NETBOX_API_TOKEN")
}
