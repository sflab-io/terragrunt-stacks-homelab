locals {
  env    = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app    = "mgm"
  memory = 4096
  cores  = 2
  disk_size = 32

  network_config = {
    type = "dhcp"
  }

  record_types = {
    normal   = true
    wildcard = false
  }

  #
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
  shared_tags  = ["${local.app}-${local.env.environment_name}"]

  # Path of the K8s cluster stack in this file (path attribute of stack "netbox_k8s_cluster")
  cluster_stack_path = "netbox-k8s-cluster"
}

# =======================
# K3s Control Plane Nodes
# =======================
stack "vm_cp1" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-cp1"

  values = {
    version = local.env.catalog_version

    app = "${local.app}-cp1"
    env = local.env.environment_name

    cores     = local.cores
    memory    = local.memory
    disk_size = local.disk_size

    record_types = local.record_types
    dns_zone     = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name       = local.cluster_name
    tenant_name        = local.tenant_name
    site_name          = local.site_name
    tags               = ["${local.app}-cp1-${local.env.environment_name}"]
    extra_tags         = local.shared_tags
    cluster_stack_path = local.cluster_stack_path
  }
}

# ================
# K3s Worker Nodes
# ================
stack "vm_w1" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-w1"

  values = {
    version = local.env.catalog_version

    app = "${local.app}-w1"
    env = local.env.environment_name

    cores     = local.cores
    memory    = local.memory
    disk_size = local.disk_size

    record_types = local.record_types
    dns_zone     = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name       = local.cluster_name
    tenant_name        = local.tenant_name
    site_name          = local.site_name
    tags               = ["${local.app}-w1-${local.env.environment_name}"]
    extra_tags         = local.shared_tags
    cluster_stack_path = local.cluster_stack_path
  }
}

stack "vm_w2" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"

  path = "${local.app}-w2"

  values = {
    version = local.env.catalog_version

    app = "${local.app}-w2"
    env = local.env.environment_name

    cores     = local.cores
    memory    = local.memory
    disk_size = local.disk_size

    record_types = local.record_types
    dns_zone     = local.env.zone

    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    #
    cluster_name       = local.cluster_name
    tenant_name        = local.tenant_name
    site_name          = local.site_name
    tags               = ["${local.app}-w2-${local.env.environment_name}"]
    extra_tags         = local.shared_tags
    cluster_stack_path = local.cluster_stack_path
  }
}

# =======================
# NetBox K8s Cluster
# =======================
stack "netbox_k8s_cluster" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-netbox-k8s-cluster?ref=${local.env.catalog_version}"

  path = "netbox-k8s-cluster"

  values = {
    version = local.env.catalog_version

    clusters = [
      {
        name        = "${local.app}-${local.env.environment_name}"
        tenant_name = local.env.netbox_tenant_name
        site_name   = local.env.netbox_site_name
        description = "Kubernetes Management Cluster (staging)"
        tags        = local.shared_tags
      }
    ]
  }
}
