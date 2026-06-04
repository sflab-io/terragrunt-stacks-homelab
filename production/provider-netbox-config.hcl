locals {
  netbox_server_url = "http://netbox.home.sflab.io"
  netbox_skip_version_check = true
  # unset default is required to avoid error when NETBOX_API_TOKEN is not set in the environment.
  # this is only required when initializing the stack before netbox is available, e.g. initializing the infrastructure.
  netbox_token = get_env("NETBOX_API_TOKEN", "unset_while_netbox_not_available")
}
