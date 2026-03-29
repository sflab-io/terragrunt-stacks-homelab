locals {
  netbox_server_url = "http://netbox.home.sflab.io"
  # optional: if you have a separate staging instance of netbox, set the url here. otherwise it will default to the production instance.
  # netbox_server_url  = "http://netbox-staging.home.sflab.io"
  netbox_skip_version_check = true
}
