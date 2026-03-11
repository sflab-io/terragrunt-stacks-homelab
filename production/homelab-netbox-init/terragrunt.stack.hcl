locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  # Variables for NetBox organization module
  regions = [
    {
      name        = "SFLAB Homelab Region"
      description = "SFLAB Homelab Region Description"
    }
  ]

  sites = [
    {
      name        = "SFLAB Homelab Site"
      facility    = "SFLAB Homelab Facility"
      latitude    = "48.7844"
      longitude   = "9.2078"
      timezone    = "Europe/Berlin"
      region_name = "SFLAB Homelab Region"
    }
  ]

  tenant_groups = [
    {
      name = "internal"
    }
  ]

  tenants = [
    {
      name       = "Platform Team"
      group_name = "internal"
    }
  ]

  contact_groups = [
    {
      name = "Platform Team Contacts"
    }
  ]

  contact_roles = [
    {
      name = "Business Contact"
    },
    {
      name = "Private Contact"
    }
  ]

  contacts = [
    {
      name       = "Sebastian Freund"
      email      = "abes140377@web.de"
      phone      = "123-123123"
      group_name = "Platform Team Contacts"
      role_name  = "Business Contact"
    }
  ]

  # Variables for NetBox racks module
  # Racks variables for NetBox racks module
  rack_manufacturers = [
    {
      name = "GeeekPi"
    }
  ]

  rack_types = [
    {
      model         = "DeskPi RackMate T1"
      manufacturer  = "GeeekPi"
      form_factor   = "4-post-cabinet"
      width         = 10
      u_height      = 8
      starting_unit = 1
    }
  ]

  racks = [
    {
      name      = "Rack 1"
      site_name = "SFLAB Homelab Site"
      status    = "active"
      rack_type = "DeskPi RackMate T1"
    }
  ]

  # Variables for NetBox devices module
  device_roles = {
    "Hypervisor" = {
      color_hex = "8a2be2"
      vm_role   = false
    }
    "Server" = {
      color_hex = "ffff00"
      vm_role   = true
    }
    "Router" = {
      color_hex = "00ffff"
      vm_role   = false
    }
    "Firewall" = {
      color_hex = "ff00ff"
      vm_role   = false
    }
    "Switch" = {
      color_hex = "00ff00"
      vm_role   = false
    }
    "AP" = {
      color_hex = "0000ff"
      vm_role   = false
    }
    "VM" = {
      color_hex = "ffa500"
      vm_role   = true
    }
    "LXC" = {
      color_hex = "800000"
      vm_role   = true
    }
    "K8s Control Plane" = {
      color_hex = "ff0000"
      vm_role   = true
    }
    "K8s Worker" = {
      color_hex = "008080"
      vm_role   = true
    }
  }

  device_manufacturers = [
    {
      name = "Minisforum"
    },
    {
      name = "Netgear"
    },
    {
      name = "Protectli"
    },
    {
      name = "Raspberry Pi Foundation"
    }
  ]

  device_types = [
    {
      model             = "MS-01 Work Station"
      manufacturer_name = "Minisforum"
      u_height          = "1"
    },
    {
      model             = "FW4C-0-8-120"
      manufacturer_name = "Protectli"
      u_height          = "1"
    },
    {
      model             = "GS108Ev4"
      manufacturer_name = "Netgear"
      u_height          = "1"
    },
    {
      model             = "WAX210"
      manufacturer_name = "Netgear"
      u_height          = "1"
    },
    {
      model             = "PI5-4GB"
      manufacturer_name = "Raspberry Pi Foundation"
      u_height          = "1"
    }
  ]

  devices = [
    {
      name        = "SFLAB-HYPERVISOR-01"
      device_type = "MS-01 Work Station"
      role_name   = "Hypervisor"
      site_name   = "SFLAB Homelab Site"
      tenant_name = "Platform Team"
      rack_name   = "Rack 1"
      interfaces  = [
        {
          name = "eth0"
          type = "1000base-t"
          ip_addresses = [
            {
              address     = "192.168.1.12/32"
              dns_name    = "netbox.home.sflab.io"
              status      = "active"
              description = "Hypervisor management ipv4 address"
            }
          ]
        }
      ]
    },
    {
      name        = "SFLAB-FIREWALL-01"
      device_type = "FW4C-0-8-120"
      role_name   = "Firewall"
      site_name   = "SFLAB Homelab Site"
      tenant_name = "Platform Team"
      rack_name   = "Rack 1"
      interfaces  = [
        {
          name = "eth0"
          type = "1000base-t"
          ip_addresses = [
            {
              address     = "192.168.1.1/32"
              dns_name    = "opnsense.home.sflab.io"
              status      = "active"
              description = "Firewall management ipv4 address"
            }
          ]
        }
      ]
    },
    {
      name        = "SFLAB-SWITCH-01"
      device_type = "GS108Ev4"
      role_name   = "Router"
      site_name   = "SFLAB Homelab Site"
      tenant_name = "Platform Team"
      rack_name   = "Rack 1"
      interfaces  = [
        {
          name = "eth0"
          type = "1000base-t"
          ip_addresses = [
            {
              address     = "192.168.1.10/32"
              dns_name    = "switch.home.sflab.io"
              status      = "active"
              description = "Core switch management ipv4 address"
            }
          ]
        }
      ]
    },
    {
      name        = "SFLAB-AP-01"
      device_type = "WAX210"
      role_name   = "AP"
      site_name   = "SFLAB Homelab Site"
      tenant_name = "Platform Team"
      rack_name   = "Rack 1"
      interfaces  = [
        {
          name = "eth0"
          type = "1000base-t"
          ip_addresses = [
            {
              address     = "192.168.1.11/32"
              dns_name    = "ap.home.sflab.io"
              status      = "active"
              description = "Wireless access point management ipv4 address"
            }
          ]
        }
      ]
    },
    {
      name        = "SFLAB-DNS-01"
      device_type = "PI5-4GB"
      role_name   = "Server"
      site_name   = "SFLAB Homelab Site"
      tenant_name = "Platform Team"
      rack_name   = "Rack 1"
      interfaces  = [
        {
          name = "eth0"
          type = "1000base-t"
          ip_addresses = [
            {
              address     = "192.168.1.13/32"
              status      = "active"
              description = "DNS Primary Server ipv4 address"
            }
          ]
        }
      ]
    }
  ]

  # Variables for NetBox ipam module
  vlans = [
    {
      name        = "Default"
      vid         = 1
      description = "Default VLAN"
    },
    {
      name        = "USER"
      vid         = 10
      description = "User VLAN"
    },
    {
      name        = "IOT"
      vid         = 20
      description = "IoT VLAN"
    },
    {
      name        = "GUEST"
      vid         = 30
      description = "Guest VLAN"
    }
  ]

  prefixes = [
    {
      prefix      = "192.168.1.0/24"
      status      = "active"
      description = "Default prefix"
      vlan_id     = 1
    },
    {
      prefix      = "192.168.10.0/24"
      status      = "active"
      description = "User VLAN prefix"
      vlan_id     = 10
    },
    {
      prefix      = "192.168.20.0/24"
      status      = "active"
      description = "IoT VLAN prefix"
      vlan_id     = 20
    },
    {
      prefix      = "192.168.30.0/24"
      status      = "active"
      description = "Guest VLAN prefix"
      vlan_id     = 30
    }
  ]

  # Variables for NetBox virtualization module
  cluster_types = [
    {
      name = "Proxmox VE Cluster"
    },
    {
      name = "Kubernetes K3s Cluster"
    }
  ]

  clusters = [
    {
      name              = "Proxmox Cluster Production"
      cluster_type_name = "Proxmox VE Cluster"
      site_name         = "SFLAB Homelab Site"
      tenant_name       = "Platform Team"
    }
  ]

  # Variables for NetBox wireless module
  wireless_lans = [
    {
      ssid        = "LAN Solo"
      description = "Primary home network"
      status      = "active"
      auth_type   = "wpa-personal"
      auth_cipher = "aes"
      vlan_name   = "USER"
      tenant_name = "Platform Team"
    },
    {
      ssid        = "LAN Solo IoT"
      description = "IoT devices network"
      status      = "active"
      auth_type   = "wpa-personal"
      auth_cipher = "aes"
      vlan_name   = "IOT"
      tenant_name = "Platform Team"
    },
    {
      ssid        = "LAN Solo Guest"
      description = "Guest network"
      status      = "active"
      auth_type   = "wpa-personal"
      auth_cipher = "aes"
      vlan_name   = "GUEST"
      tenant_name = "Platform Team"
    }
  ]
}

stack "netbox_init" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-netbox-init?ref=${local.env.catalog_version}"

  path = "netbox_init"

  values = {
    version = local.env.catalog_version

    # Required values for NetBox organization module
    regions        = local.regions
    sites          = local.sites
    tenant_groups  = local.tenant_groups
    tenants        = local.tenants
    contact_groups = local.contact_groups
    contact_roles  = local.contact_roles
    contacts       = local.contacts

    # Variables for NetBox racks module
    rack_manufacturers = local.rack_manufacturers
    rack_types         = local.rack_types
    racks              = local.racks

    # Variables for NetBox devices module
    device_roles         = local.device_roles
    device_manufacturers = local.device_manufacturers
    device_types         = local.device_types
    devices              = local.devices

    # Variables for NetBox IPAM module
    vlans    = local.vlans
    prefixes = local.prefixes

    # Variables for NetBox virtualization module
    cluster_types = local.cluster_types
    clusters      = local.clusters

    # Variables for NetBox wireless module
    wireless_lans = local.wireless_lans
  }
}
