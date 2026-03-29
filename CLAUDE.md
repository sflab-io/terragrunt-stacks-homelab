# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Terragrunt infrastructure-live repository** for managing homelab infrastructure (Proxmox VMs and LXC containers). It uses:
- **Terragrunt Stacks** for organizing infrastructure deployments
- **MinIO** as an S3-compatible backend for Terraform state storage
- **Proxmox** as the target infrastructure platform
- **mise** for tool version management and task automation
- Environment-based organization (staging, production)

The repository follows Terragrunt's "infrastructure-live" pattern where configurations reference reusable modules from a separate "infrastructure-catalog" repository.
The local catalog repository is located at: `../terragrunt-infrastructure-catalog-homelab/`

### Required Tools (Managed by mise)

The following tools are automatically installed and managed via `mise.toml`:
- **Go**: 1.24.2
- **OpenTofu**: 1.11.5
- **Terragrunt**: 0.99.4
- **mc (MinIO Client)**: latest

Run `mise install` to install all required tools, or simply enter the directory (mise will auto-install via hooks).

## Key Architecture Concepts

### Repository Structure

```
├── root.hcl                    # Root Terragrunt config: remote state, catalog URLs
├── provider-proxmox-config.hcl # Proxmox provider configuration
├── provider-dns-config.hcl     # DNS provider configuration
├── keys/                       # SSH public keys for VM access
│   ├── ansible_id_ecdsa.pub    # Ansible SSH public key
│   └── admin_id_ecdsa.pub      # Admin SSH public key
├── {environment}/              # Environment directories (staging, production)
│   ├── environment.hcl         # Environment-specific variables
│   ├── backend-config.hcl      # Environment-specific backend configuration
│   ├── provider-netbox-config.hcl # NetBox provider configuration (per environment)
│   ├── proxmox-pool/           # Proxmox resource pool stack
│   │   └── terragrunt.stack.hcl
│   └── {stack-name}/           # Individual stack deployments (e.g., proxmox-docker-vm)
│       └── terragrunt.stack.hcl # Stack definition with units
└── .mise/tasks/                # Automation tasks via mise
```

### Terragrunt Stacks

This repository uses Terragrunt's **Stacks** feature for managing multi-unit deployments:

- **Stack**: A collection of related infrastructure units (defined in `terragrunt.stack.hcl`)
- **Unit**: A single infrastructure component (e.g., `proxmox_pool`, `db`, `asg`)
- **Source**: Units reference modules from the catalog repository: `git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//units/{unit-name}`
- **Path**: Where the unit is deployed within the `.terragrunt-stack/` directory
- **Values**: Configuration passed to the underlying Terraform module

### Configuration Hierarchy

1. **root.hcl**: Defines global settings inherited by all stacks
   - S3 backend configuration (reads from `backend-config.hcl`)
   - Catalog repository URLs
   - Note: Provider configuration has been moved to separate files

2. **provider-proxmox-config.hcl**: Proxmox provider configuration
   - Defines locals: `proxmox_host`, `proxmox_port` (8006), `proxmox_insecure` (true)
   - Configured for SSH agent authentication

3. **provider-dns-config.hcl**: DNS provider configuration
   - DNS server: 192.168.1.13:53
   - Key name: `ddnskey.`
   - Key algorithm: hmac-sha256
   - Used for automatic DNS record creation for VMs
   - Note: Key secret is stored in environment variable `TF_VAR_dns_key_secret`

4. **provider-netbox-config.hcl**: NetBox provider configuration (per environment)
   - Staging: `http://netbox-staging.home.sflab.io` (`skip_version_check = true`)
   - Production: `http://netbox.home.sflab.io` (`skip_version_check = true`)
   - Used for registering VMs/LXC containers in NetBox IPAM/DCIM

5. **environment.hcl**: Environment-specific variables shared by all stacks
   - `environment_name`: e.g., `"staging"` or `"production"`
   - `pool_id`: e.g., `"pool-staging"` or `"pool-production"`
   - `catalog_version`: e.g., `"main"` (staging) or `"v0.8.0"` (production)
   - `zone`: DNS zone, e.g., `"home.sflab.io"`
   - `ansible_ssh_public_key_path`: Path to ansible SSH public key
   - `admin_ssh_public_key_path`: Path to admin SSH public key
   - `netbox_cluster_name`: Proxmox cluster name in NetBox (e.g., `"Proxmox Cluster Staging"`)
   - `netbox_tenant_name`: NetBox tenant (e.g., `"Platform Team"`)
   - `netbox_site_name`: NetBox site (e.g., `"SFLAB Homelab Site Staging"`)

6. **backend-config.hcl**: Environment-specific backend configuration
   - Defines S3 backend prefix, endpoint, and credentials
   - Located in each environment directory
   - Configured for both staging and production environments

7. **terragrunt.stack.hcl**: Stack definition with multiple units
   - Each unit references a module from the catalog
   - Units can have dependencies on each other within the same stack
   - Local variables define stack-wide settings

### Shared Resources Pattern

The repository uses a **proxmox-pool** stack pattern for environment-wide resources:

- **proxmox-pool Stack**: Contains the Proxmox resource pool shared across multiple application stacks
  - Located at `{environment}/proxmox-pool/`
  - Manages the Proxmox resource pool for the environment
  - Must be deployed **before** application stacks that depend on this resource

- **Application Stacks**: Reference the shared pool by ID/name (e.g., `pool_id = "pool-staging"`)
  - Do not create the pool themselves
  - Depend on the pool being pre-deployed
  - Examples: `proxmox-docker-vm`, `proxmox-vault-vm`, `proxmox-netbox-vm`

**Deployment Order**:
1. Deploy `proxmox-pool` stack first (one-time or when pool configuration changes)
2. Deploy application stacks in any order (they all reference the same pool)

### Remote State Backend

- Uses **MinIO** as S3-compatible backend
- Bucket naming: `{prefix}-tfstates` (e.g., `staging-terragrunt-tfstates`, `production-terragrunt-tfstates`)
  - Staging prefix: `staging-terragrunt` (defined in `staging/backend-config.hcl`)
  - Production prefix: `production-terragrunt` (defined in `production/backend-config.hcl`)
- Requires environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- MinIO endpoint: `http://192.168.1.20:9000` (alternative: `http://minio.home.sflab.io:9000`)
- Configuration is environment-specific via `backend-config.hcl` files

### Infrastructure Catalog

External module repository: `git@github.com:sflab-io/terragrunt-catalog-homelab.git`
- Contains reusable Terraform modules for infrastructure components
- Referenced via git source URLs in stack definitions
- Version pinning via `?ref=branch-or-tag`
  - Staging: `?ref=main` (tracks latest catalog changes via `catalog_version = "main"` in environment.hcl)
  - Production: `?ref=v0.8.0` (pinned for stability via `catalog_version = "v0.8.0"` in environment.hcl)

**Available Catalog Items** (as used in current stacks):
- `stacks/homelab-proxmox-vm`: Combined VM + DNS stack (use `stack {}` block)
- `stacks/homelab-proxmox-lxc`: Combined LXC + DNS stack (use `stack {}` block)
- `units/proxmox-pool`: Proxmox resource pool management (use `unit {}` block)

## Common Commands

### Mise Task Management

```bash
# List all available tasks
mise tasks

# Setup MinIO backend (creates bucket, service account)
mise run minio:setup

# List MinIO bucket contents
mise run minio:list

# Cleanup all Terragrunt/Terraform cache directories
mise run terragrunt:cleanup

# Interactive stack apply (prompts for environment and stack selection)
mise run terragrunt:stack:apply

# Interactive stack destroy (prompts for environment and stack selection)
mise run terragrunt:stack:destroy

# Interactive stack generate (prompts for environment and stack selection)
mise run terragrunt:stack:generate

# Interactive stack plan (prompts for environment and stack selection)
mise run terragrunt:stack:plan

# Interactive stack output (prompts for environment and stack selection)
mise run terragrunt:stack:output

# Configure network settings
mise run network:configure

# Print current network configuration
mise run network:status

# Edit SOPS-encrypted secrets file
mise run secrets:edit .creds.env.yaml
```

**Notes**:
- The `secrets:edit` task is available as a global mise task from `~/.config/mise/tasks/secrets/edit`
- The `network:configure` and `network:status` tasks are global mise tasks (not defined in this repo)
- Local tasks in `.mise/tasks/` cover: `minio/list`, `minio/setup`, `terragrunt/cleanup`, `terragrunt/stack/apply`, `terragrunt/stack/destroy`, `terragrunt/stack/generate`, `terragrunt/stack/output`, `terragrunt/stack/plan`

### Terragrunt Operations

```bash
# Navigate to a stack directory first
cd staging/proxmox-docker-vm

# View stack plan
terragrunt stack run plan

# Apply stack changes (interactive confirmation)
terragrunt stack run apply

# Apply stack changes (auto-approve, no confirmation)
terragrunt stack run apply -- --auto-approve

# Destroy stack resources (interactive confirmation)
terragrunt stack run destroy

# Destroy stack resources (auto-approve, no confirmation)
terragrunt stack run destroy -- --auto-approve

# Generate stack without applying
terragrunt stack generate

# View stack outputs
terragrunt stack output

# Clean generated stack files
terragrunt stack clean

# Browse available catalog modules
terragrunt catalog
```

### Working with Individual Units

```bash
# Navigate to a specific unit directory
cd staging/proxmox-docker-vm/.terragrunt-stack/proxmox-vm

# Standard Terragrunt commands work on individual units
terragrunt plan
terragrunt apply
terragrunt destroy

# Note: .terragrunt-stack/ directories are generated by terragrunt stack generate
# and should not be committed to version control
```

## Environment Variables Required

These must be set before running Terragrunt commands:

```bash
AWS_ACCESS_KEY_ID           # MinIO access key for state backend
AWS_SECRET_ACCESS_KEY       # MinIO secret key for state backend
MINIO_USERNAME              # MinIO admin username (for setup tasks)
MINIO_PASSWORD              # MinIO admin password (for setup tasks)
PROXMOX_CONTAINER_PASSWORD  # Password for LXC containers (for container stacks)
TF_VAR_dns_key_secret       # DNS TSIG key secret for dynamic DNS updates
```

**Note**: Environment variables are loaded automatically from:
- `~/.env` (optional, user home directory)
- `.env` (optional, project root)
- `.creds.env.yaml` (encrypted with SOPS, project root)

Proxmox authentication is handled via SSH agent (configured in provider-proxmox-config.hcl).

## Development Workflow

### Deploying Infrastructure (Standard Workflow)

```bash
# 1. Deploy proxmox-pool first (one-time or when pool configuration changes)
cd staging/proxmox-pool
terragrunt stack run apply

# 2. Deploy application stacks (in any order)
cd staging/proxmox-docker-vm
terragrunt stack run apply

cd staging/proxmox-vault-vm
terragrunt stack run apply
```

### Adding a New Stack

1. Create directory: `{environment}/{stack-name}/`
2. Create `terragrunt.stack.hcl` with unit definitions
3. Reference catalog modules via git URLs (with optional version pinning via `?ref=branch-or-tag`)
4. Define unit values (referencing shared resources by ID if needed)
5. Run `terragrunt stack run plan` to preview changes
6. Run `terragrunt stack run apply` to deploy

**Example VM Stack Structure**:
```hcl
locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app       = "myapp"
  memory    = 4096
  disk_size = 8000

  # Example: DHCP network configuration
  network_config = {
    type = "dhcp"
  }

  # Example: Static IP configuration
  # network_config = {
  #   type        = "static"
  #   ip_address  = "192.168.1.50"
  #   cidr        = 24
  #   gateway     = "192.168.1.1"
  #   dns_servers = ["192.168.1.13", "192.168.1.154"]
  #   domain      = "home.sflab.io"
  # }

  record_types = {
    normal   = true
    wildcard = false
  }

  # NetBox integration (from environment.hcl)
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
  role_name    = "MyApp"
}

stack "homelab_proxmox_vm" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"
  path   = "homelab-proxmox-vm"

  values = {
    version = local.env.catalog_version

    env       = local.env.environment_name
    app       = local.app
    memory    = local.memory
    disk_size = local.disk_size

    network_config      = local.network_config
    record_types        = local.record_types
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.ansible_ssh_public_key_path

    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
    role_name    = local.role_name
  }
}
```

**Example LXC Container Stack Structure**:
```hcl
locals {
  env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals

  app       = "my-runner"
  memory    = 4096
  disk_size = 8000

  network_config = {
    type = "dhcp"
  }

  record_types = {
    normal   = true
    wildcard = false
  }

  # NetBox integration (from environment.hcl)
  cluster_name = local.env.netbox_cluster_name
  tenant_name  = local.env.netbox_tenant_name
  site_name    = local.env.netbox_site_name
  role_name    = "My Runner"
}

stack "homelab_proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-lxc?ref=${local.env.catalog_version}"
  path   = "homelab-proxmox-lxc"

  values = {
    version = local.env.catalog_version

    env       = local.env.environment_name
    app       = local.app
    memory    = local.memory
    disk_size = local.disk_size

    network_config      = local.network_config
    record_types        = local.record_types
    dns_zone            = local.env.zone
    pool_id             = local.env.pool_id
    ssh_public_key_path = local.env.admin_ssh_public_key_path

    cluster_name = local.cluster_name
    tenant_name  = local.tenant_name
    site_name    = local.site_name
    role_name    = local.role_name
  }
}
```

### Adding a New Stack to Existing Stack

1. Edit `terragrunt.stack.hcl` in the stack directory
2. Add new `stack` block with source, path, and values
3. Use `local.env.*` to reference shared environment variables
4. Run `terragrunt stack run plan` to preview

### Modifying Infrastructure

1. Edit values in `terragrunt.stack.hcl`
2. Run `terragrunt stack run plan` to review changes
3. Run `terragrunt stack run apply` to apply changes
4. Cache is stored in `.terragrunt-stack/` and `.terragrunt-cache/` directories

### Cleanup

When encountering cache issues or wanting a fresh start:
```bash
mise run terragrunt:cleanup
```

This removes:
- `.terragrunt-stack/` directories
- `.terragrunt-cache/` directories
- `.terraform/` directories
- `.terraform.lock.hcl` files

## Important Notes

- **Pool First**: Always deploy the `proxmox-pool` stack before application stacks in each environment
- **Version Pinning**: Managed via `catalog_version` in each environment's `environment.hcl`
  - Staging: `catalog_version = "main"` (tracks latest catalog changes)
  - Production: `catalog_version = "v0.8.0"` (pinned for stability)
- **Stack vs Unit**: Application stacks use `stack {}` blocks (referencing catalog stacks); only `proxmox-pool` uses `unit {}` blocks (referencing catalog units)
- **Environment Locals**: All stacks use `local.env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals` to reference shared settings (`catalog_version`, `pool_id`, `zone`, `environment_name`, `ansible_ssh_public_key_path`, `admin_ssh_public_key_path`, `netbox_cluster_name`, `netbox_tenant_name`, `netbox_site_name`)
- **Generated Files**: `provider.tf` and `backend.tf` are auto-generated by Terragrunt
  - Provider configuration from `provider-proxmox-config.hcl`
  - Backend configuration from `root.hcl` (which reads `backend-config.hcl`)
- **Configuration Files**:
  - `provider-proxmox-config.hcl`: Proxmox provider settings (at repository root)
  - `provider-dns-config.hcl`: DNS provider settings (at repository root)
  - `provider-netbox-config.hcl`: NetBox provider settings (per environment directory)
  - `backend-config.hcl`: S3 backend settings (per environment)
- **Dependencies**:
  - DNS is included within catalog stacks (no separate `dns` unit needed)
  - Cross-stack dependencies (like shared pools) are referenced by ID/name, not paths
- **State Management**: Each unit gets its own state file in the S3 bucket, organized by path
- **Proxmox Endpoint**: `https://proxmox.home.sflab.io:8006/` (configured in `provider-proxmox-config.hcl`)
- **Cache Directories**: `.terragrunt-stack/` and `.terragrunt-cache/` are generated and should not be committed to git

## Troubleshooting

- **State backend issues**: Verify MinIO is accessible and credentials are set
- **SSH authentication to Proxmox**: Ensure SSH agent is running with appropriate keys loaded
- **Cache corruption**: Run `mise run terragrunt:cleanup` to remove all cache directories
- **Resource conflicts**: If multiple stacks try to create the same resource (e.g., pool), move it to `proxmox-pool` stack
- **Unit dependencies**:
  - Within same stack: Use relative paths (e.g., `compute_path = "../proxmox-vm"`)
  - Across stacks: Reference by ID/name (e.g., `pool_id = "pool-staging"`)
- **Command not found**: Use `terragrunt stack run <command>` not `terragrunt stack <command>`
- **Multiple VMs getting same IP address (DHCP)**:
  - Root cause: VMs cloned from same template share the same `/etc/machine-id`
  - DHCP client uses machine-id to generate client identifier, causing IP conflicts
  - Solution: Template must have empty `/etc/machine-id` (regenerated on first boot)
  - Template provisioner should include:
    ```bash
    truncate -s 0 /etc/machine-id
    rm /var/lib/dbus/machine-id
    ln -s /etc/machine-id /var/lib/dbus/machine-id
    ```
  - See: `homelab-packer-templates/ubuntu-24.04.pkrvars.hcl` for reference

## Example Stacks

### Current Staging Stacks

1. **proxmox-pool** (`staging/proxmox-pool/`)
   - Purpose: Proxmox resource pool for staging environment
   - Contains: `proxmox_pool` unit
   - Deploy first (required by other stacks)

2. **proxmox-docker-vm** (`staging/proxmox-docker-vm/`)
   - Purpose: Docker host VM
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal + wildcard
   - Memory: 2048MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`

3. **proxmox-k3s-vms** (`staging/proxmox-k3s-vms/`)
   - Purpose: K3s Kubernetes cluster VMs (control plane and worker nodes)
   - Contains: `vm_cp1`, `vm_w1` stacks (2 nodes: 1 control plane, 1 worker)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP (no explicit network_config set)
   - DNS records: normal only
   - Memory: 4096MB, Cores: 2
   - SSH key: `keys/admin_id_ecdsa.pub`

4. **proxmox-vault-vm** (`staging/proxmox-vault-vm/`)
   - Purpose: HashiCorp Vault VM for secrets management
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: Static IP (192.168.1.33/24, gateway 192.168.1.1)
   - DNS servers: 192.168.1.13, 192.168.1.154
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`

5. **proxmox-github-runner-vm** (`staging/proxmox-github-runner-vm/`)
   - Purpose: GitHub Actions runner VM
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - SSH key: `keys/admin_id_ecdsa.pub`
   - NetBox role: `"Github Runner"`

6. **proxmox-gitlab-runner-vm** (`staging/proxmox-gitlab-runner-vm/`)
   - Purpose: GitLab CI runner VM
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - SSH key: `keys/admin_id_ecdsa.pub`
   - NetBox role: `"Gitlab Runner"`

7. **proxmox-dns-lxc** (`staging/proxmox-dns-lxc/`)
   - Purpose: Technitium DNS servers (primary and secondary) for homelab DNS infrastructure
   - Contains: `proxmox_lxc_1`, `proxmox_lxc_2` stacks (app names: `technitium-dns-1`, `technitium-dns-2`)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.` (dns_zone is passed but these ARE the DNS servers)
   - Network: Static IP configuration
     - DNS 1: 192.168.1.153/24 (technitium-dns-1-staging)
     - DNS 2: 192.168.1.154/24 (technitium-dns-2-staging)
     - Gateway: 192.168.1.1
     - DNS servers: 192.168.1.13, 192.168.1.154
   - SSH key: `keys/admin_id_ecdsa.pub`
   - Requires: `PROXMOX_CONTAINER_PASSWORD` environment variable

8. **proxmox-netbox-vm** (`staging/proxmox-netbox-vm/`)
   - Purpose: NetBox IPAM/DCIM VM for network documentation
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: Static IP (192.168.1.88/24, gateway 192.168.1.1)
   - DNS servers: 192.168.1.13, 192.168.1.154
   - DNS records: normal + wildcard
   - Memory: 4096MB, Disk: 16GB
   - SSH key: `keys/ansible_id_ecdsa.pub`
   - Note: `virtual_machines = []` set to avoid circular dependency on first deploy

9. **proxmox-example-vm** (`staging/proxmox-example-vm/`)
   - Purpose: Example/template VM stack for reference
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - Network: Static IP (192.168.1.45/24, gateway 192.168.1.1)
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`
   - NetBox role: `"Example VM"`

10. **proxmox-example-lxc** (`staging/proxmox-example-lxc/`)
    - Purpose: Example/template LXC stack for reference
    - Contains: `homelab_proxmox_lxc` stack (LXC + DNS)
    - Network: Static IP (192.168.1.44/24, gateway 192.168.1.1)
    - DNS records: normal only (no wildcard)
    - Memory: 4096MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`
    - NetBox role: `"Example LXC"`
    - Requires: `PROXMOX_CONTAINER_PASSWORD` environment variable

### Current Production Stacks

1. **proxmox-pool** (`production/proxmox-pool/`)
   - Purpose: Proxmox resource pool for production environment
   - Contains: `proxmox_pool` unit
   - Deploy first (required by other stacks)

2. **proxmox-docker-vm** (`production/proxmox-docker-vm/`)
   - Purpose: Docker host VM (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal + wildcard
   - Memory: 2048MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`

3. **proxmox-k3s-vms** (`production/proxmox-k3s-vms/`)
   - Purpose: K3s Kubernetes cluster VMs (control plane and worker nodes)
   - Contains: `vm_cp1`, `vm_w1` stacks (2 nodes: 1 control plane, 1 worker)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP (no explicit network_config set)
   - DNS records: normal only
   - Memory: 4096MB, Cores: 2
   - SSH key: `keys/admin_id_ecdsa.pub`

4. **proxmox-vault-vm** (`production/proxmox-vault-vm/`)
   - Purpose: HashiCorp Vault VM for secrets management (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: Static IP (192.168.1.34/24, gateway 192.168.1.1)
   - DNS servers: 192.168.1.13, 192.168.1.154
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`

5. **proxmox-github-runner-vm** (`production/proxmox-github-runner-vm/`)
   - Purpose: GitHub Actions runner VM (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - SSH key: `keys/admin_id_ecdsa.pub`
   - NetBox role: `"Github Runner"`

6. **proxmox-gitlab-runner-vm** (`production/proxmox-gitlab-runner-vm/`)
   - Purpose: GitLab CI runner VM (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - SSH key: `keys/admin_id_ecdsa.pub`
   - NetBox role: `"Gitlab Runner"`

7. **proxmox-dns-lxc** (`production/proxmox-dns-lxc/`)
   - Purpose: Technitium DNS secondary server for homelab DNS infrastructure
   - Contains: `proxmox_lxc` stack (app name: `technitium-dns-secondary`)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.` (dns_zone is passed to catalog stack)
   - Network: Static IP configuration
     - IP: 192.168.1.154/24 (technitium-dns-secondary-production)
     - Gateway: 192.168.1.1
     - DNS servers: 192.168.1.13, 192.168.1.154
   - SSH key: `keys/admin_id_ecdsa.pub`
   - Requires: `PROXMOX_CONTAINER_PASSWORD` environment variable

8. **proxmox-netbox-vm** (`production/proxmox-netbox-vm/`)
   - Purpose: NetBox IPAM/DCIM VM for network documentation (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: Static IP (192.168.1.89/24, gateway 192.168.1.1)
   - DNS servers: 192.168.1.13, 192.168.1.154
   - DNS records: normal + wildcard
   - Memory: 4096MB, Disk: 16GB
   - SSH key: `keys/ansible_id_ecdsa.pub`
   - Note: `virtual_machines = []` set to avoid circular dependency on first deploy

9. **proxmox-example-vm** (`production/proxmox-example-vm/`)
   - Purpose: Example/template VM stack for reference (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - Network: Static IP (192.168.1.45/24, gateway 192.168.1.1)
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`
   - NetBox role: `"Example VM"`

10. **proxmox-example-lxc** (`production/proxmox-example-lxc/`)
    - Purpose: Example/template LXC stack for reference (production)
    - Contains: `homelab_proxmox_lxc` stack (LXC + DNS)
    - Network: Static IP (192.168.1.44/24, gateway 192.168.1.1)
    - DNS records: normal only (no wildcard)
    - Memory: 4096MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`
    - NetBox role: `"Example LXC"`
    - Requires: `PROXMOX_CONTAINER_PASSWORD` environment variable
