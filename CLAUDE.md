# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Terragrunt infrastructure-live repository** for managing homelab infrastructure (Proxmox VMs and LXC containers). It uses:
- **Terragrunt Stacks** for organizing infrastructure deployments
- **MinIO** as an S3-compatible backend for Terraform state storage
- **Proxmox** as the target infrastructure platform
- **mise** for tool version management and task automation
- **Dagger** for running Terragrunt stack operations in CI/CD pipelines
- Environment-based organization (staging, production)

The repository follows Terragrunt's "infrastructure-live" pattern where configurations reference reusable modules from a separate "infrastructure-catalog" repository.
The local catalog repository is located at: `../terragrunt-catalog-homelab/`

### Required Tools (Managed by mise)

The following tools are automatically installed and managed via `mise.toml`:
- **Go**: 1.26.3
- **OpenTofu**: 1.12.1
- **Terragrunt**: 1.0.6
- **Dagger**: latest (via `aqua:dagger`)
- **mc (MinIO Client)**: latest
- **Vault**: 1.21.1
- **fnox**: latest (secrets management, via mise plugin `fnox-env`)
- **pre-commit**: latest

Run `mise install` to install all required tools, or simply enter the directory (mise will auto-install via hooks).

## Key Architecture Concepts

### Repository Structure

```
├── root.hcl                    # Root Terragrunt config: remote state, catalog URLs
├── provider-proxmox-config.hcl # Proxmox provider configuration
├── provider-dns-config.hcl     # DNS provider configuration
├── dagger.json                 # Dagger module configuration
├── .dagger/                    # Dagger TypeScript module source
├── fnox.toml                   # fnox config for Vault secrets mapping (replaces .teller.yml)
├── .pre-commit-config.yaml     # Pre-commit hooks (gitleaks, tofu-fmt, catalog version check)
├── keys/                       # SSH public keys for VM access
│   ├── ansible_id_ecdsa.pub    # Ansible SSH public key
│   └── admin_id_ecdsa.pub      # Admin SSH public key
├── .hooks/                     # Git hooks scripts
│   └── check-staging-catalog-version.sh # Pre-commit hook: enforces catalog_version = "main" in staging
├── .mise/                      # mise configuration and automation
│   ├── common.sh               # Shared shell functions for mise tasks (logging, colors)
│   └── tasks/                  # Automation tasks via mise
├── {environment}/              # Environment directories (staging, production)
│   ├── environment.hcl         # Environment-specific variables
│   ├── backend-config.hcl      # Environment-specific backend configuration
│   ├── provider-netbox-config.hcl # NetBox provider configuration (per environment)
│   ├── proxmox-pool/           # Proxmox resource pool stack
│   │   └── terragrunt.stack.hcl
│   └── {stack-name}/           # Individual stack deployments (e.g., proxmox-vault-vm)
│       └── terragrunt.stack.hcl # Stack definition with units
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
   - Proxmox authentication uses API token (`PROXMOX_VE_API_TOKEN` env var)

3. **provider-dns-config.hcl**: DNS provider configuration
   - DNS server: 192.168.1.13:53
   - Key name: `ddnskey.`
   - Key algorithm: hmac-sha256
   - Used for automatic DNS record creation for VMs
   - Note: TSIG key name and secret are auto-loaded from Vault via fnox as `TSIG_KEY_NAME` and `TSIG_KEY_SECRET`

4. **provider-netbox-config.hcl**: NetBox provider configuration (per environment)
   - Both staging and production use: `http://netbox.home.sflab.io` (`skip_version_check = true`)
   - Both environments use `NETBOX_API_TOKEN` (shared NetBox instance)
   - Used for registering VMs/LXC containers in NetBox IPAM/DCIM
   - When `NETBOX_API_TOKEN` is not set, falls back to `"unset_while_netbox_not_available"` (allows deploying stacks before NetBox is available)

5. **environment.hcl**: Environment-specific variables shared by all stacks
   - `environment_name`: e.g., `"staging"` or `"production"`
   - `pool_id`: e.g., `"pool-staging"` or `"pool-production"`
   - `catalog_version`: e.g., `"main"` (staging) or `"v0.22.0"` (production)
   - `zone`: DNS zone, e.g., `"home.sflab.io"`
   - `ansible_ssh_public_key_path`: Path to ansible SSH public key
   - `admin_ssh_public_key_path`: Path to admin SSH public key
   - `netbox_cluster_name`: Proxmox cluster name in NetBox (e.g., `"proxmox-staging"`)
   - `netbox_tenant_name`: NetBox tenant (e.g., `"platform-team"`)
   - `netbox_site_name`: NetBox site (e.g., `"sflab-homelab-staging"`)

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
  - Examples: `proxmox-vault-vm`, `proxmox-netbox-vm`, `proxmox-mgm-cluster`

**Deployment Order**:
1. Deploy `proxmox-pool` stack first (one-time or when pool configuration changes)
2. Deploy application stacks in any order (they all reference the same pool)

### Remote State Backend

- Uses **MinIO** as S3-compatible backend
- Bucket naming: `{prefix}-tfstates` (e.g., `staging-terragrunt-tfstates`, `production-terragrunt-tfstates`)
  - Staging prefix: `staging-terragrunt` (defined in `staging/backend-config.hcl`)
  - Production prefix: `production-terragrunt` (defined in `production/backend-config.hcl`)
- Requires environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- MinIO endpoint: `http://192.168.1.20:9000` (configured in `backend-config.hcl`)
- Configuration is environment-specific via `backend-config.hcl` files

### Infrastructure Catalog

External module repository: `git@github.com:sflab-io/terragrunt-catalog-homelab.git`
- Contains reusable Terraform modules for infrastructure components
- Referenced via git source URLs in stack definitions
- Version pinning via `?ref=branch-or-tag`
  - Staging: `?ref=main` (tracks latest catalog changes via `catalog_version = "main"` in environment.hcl)
  - Production: `?ref=v0.22.0` (pinned for stability via `catalog_version = "v0.22.0"` in environment.hcl)
- **Note**: `root.hcl` configures `catalog {}` with URL `https://github.com/sflab-io/terragrunt-infrastructure-catalog-homelab.git` for the `terragrunt catalog` browse command — this is a different URL than the git SSH source used in stack `source` fields (`git@github.com:sflab-io/terragrunt-catalog-homelab.git`)

**Available Catalog Items** (as used in current stacks):
- `stacks/homelab-proxmox-vm`: Combined VM + DNS stack (use `stack {}` block)
- `stacks/homelab-proxmox-lxc`: Combined LXC + DNS stack (use `stack {}` block)
- `stacks/homelab-netbox-k8s-cluster`: NetBox Kubernetes cluster registration (use `stack {}` block)
- `units/proxmox-pool`: Proxmox resource pool management (use `unit {}` block)
- `units/netbox-tags`: NetBox tag management (use `unit {}` block)

### Vault & fnox Integration

The repository uses **fnox** (`fnox.toml`) to map HashiCorp Vault secrets to environment variables. The mise `fnox-env` plugin loads secrets automatically on directory entry:

- **Vault address**: `https://vault.home.sflab.io` (also set as `VAULT_ADDR` env var by mise)
- **TLS verification**: `VAULT_SKIP_VERIFY = "true"` is set by mise (self-signed cert in homelab)
- **Secrets loaded** (defined in `fnox.toml`):
  - `secrets_homelab/netbox/api_token` → `NETBOX_API_TOKEN`
  - `secrets_homelab/technitium/tsig_key_name` → `TSIG_KEY_NAME`
  - `secrets_homelab/technitium/tsig_key_secret` → `TSIG_KEY_SECRET`
- **Startup sequence on directory entry**:
  1. `mise.toml` sets `VAULT_TOKEN` via `{{ exec(command='cat ~/.vault-token') }}`
  2. `fnox-env` plugin loads secrets from Vault using `VAULT_TOKEN`
  3. The `enter` hook runs the `hooks:enter` task (`.mise/tasks/hooks/enter`), which runs `mise install`, installs pre-commit hooks, and runs `vault:create-token` (`.mise/tasks/vault/create-token`) to create/refresh the Vault AppRole token and save it to `~/.vault-token`
- **AppRole credentials**: provided via `VAULT_ROLE_ID` / `VAULT_SECRET_ID` environment variables (e.g. from `.env` or `.creds.env.yaml`), used by the `vault:create-token` task
- Note: The AppRole `secret_id` must be configured for multiple uses (`secret_id_num_uses = 0`) in Vault

**Pre-commit hooks** (`.pre-commit-config.yaml`) enforce:
- `gitleaks`: Secret scanning before every commit
- `end-of-file-fixer` / `trailing-whitespace`: File formatting
- `tofu-fmt` / `tofu-validate`: Terraform formatting and validation
- `check-staging-catalog-version`: Prevents commits where staging `catalog_version` is not `"main"`

### Dagger Integration

The repository uses a **Dagger module** (`.dagger/src/index.ts`) to run Terragrunt stack operations. The mise tasks delegate to Dagger by default:

- `dagger call apply` → `terragrunt stack run apply --non-interactive`
- `dagger call plan` → `terragrunt stack run plan`
- `dagger call destroy` → `terragrunt stack run destroy --non-interactive`
- `dagger call generate` → `terragrunt stack run generate`
- `dagger call output` → `terragrunt stack run output`

All Dagger tasks pass the following environment variables into the container: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`, `PROXMOX_VE_INSECURE=true`, `NETBOX_API_TOKEN`, `TSIG_KEY_NAME`, `TSIG_KEY_SECRET`, `PROXMOX_CONTAINER_PASSWORD`.

Tasks with `-old` suffix (e.g., `terragrunt:stack:apply-old`) bypass Dagger and call `terragrunt stack run apply --provider-cache` directly.

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

# Interactive stack apply via Dagger (prompts for environment and stack selection)
mise run terragrunt:stack:apply

# Interactive stack apply directly (bypasses Dagger, uses --provider-cache)
mise run terragrunt:stack:apply-old

# Interactive stack destroy via Dagger
mise run terragrunt:stack:destroy

# Interactive stack generate via Dagger
mise run terragrunt:stack:generate

# Interactive stack plan via Dagger
mise run terragrunt:stack:plan

# Interactive stack output via Dagger
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
- Local tasks in `.mise/tasks/` cover: `minio/list`, `minio/setup`, `terragrunt/cleanup`, `terragrunt/stack/apply`, `terragrunt/stack/apply-old`, `terragrunt/stack/destroy`, `terragrunt/stack/destroy-old`, `terragrunt/stack/generate`, `terragrunt/stack/generate-old`, `terragrunt/stack/output`, `terragrunt/stack/output-old`, `terragrunt/stack/plan`, `terragrunt/stack/plan-old`, `hooks/enter` (directory-entry hook), `vault/create-token` (refreshes `~/.vault-token` via AppRole), `claude-code/setup` (prints Claude Code plugin setup instructions)
- All interactive tasks accept optional positional arguments: `mise run terragrunt:stack:apply <env> <stack>`

### Terragrunt Operations (Direct)

```bash
# Navigate to a stack directory first
cd staging/proxmox-vault-vm

# View stack plan
terragrunt stack run plan

# Apply stack changes (interactive confirmation)
terragrunt stack run apply

# Apply stack changes (non-interactive)
terragrunt stack run apply --non-interactive

# Destroy stack resources
terragrunt stack run destroy

# Destroy stack resources (non-interactive)
terragrunt stack run destroy --non-interactive

# Generate stack without applying
terragrunt stack run generate

# View stack outputs
terragrunt stack run output

# Browse available catalog modules
terragrunt catalog
```

### Working with Individual Units

```bash
# Navigate to a specific unit directory
cd staging/proxmox-vault-vm/.terragrunt-stack/homelab-proxmox-vm

# Standard Terragrunt commands work on individual units
terragrunt plan
terragrunt apply
terragrunt destroy

# Note: .terragrunt-stack/ directories are generated by terragrunt stack run generate
# and should not be committed to version control
```

## Environment Variables Required

These must be set before running Terragrunt commands:

```bash
AWS_ACCESS_KEY_ID              # MinIO access key for state backend
AWS_SECRET_ACCESS_KEY          # MinIO secret key for state backend
MINIO_USERNAME                 # MinIO admin username (for setup tasks)
MINIO_PASSWORD                 # MinIO admin password (for setup tasks)
PROXMOX_VE_ENDPOINT            # Proxmox API endpoint (e.g., https://proxmox.home.sflab.io:8006)
PROXMOX_VE_API_TOKEN           # Proxmox API token for authentication
PROXMOX_CONTAINER_PASSWORD     # Password for LXC containers (for container stacks)
TSIG_KEY_SECRET                # DNS TSIG key secret — auto-loaded via fnox from Vault (REQUIRED by tasks)
TSIG_KEY_NAME                  # DNS TSIG key name — auto-loaded via fnox from Vault
NETBOX_API_TOKEN               # NetBox API token — auto-loaded via fnox from Vault (OPTIONAL: tasks warn if missing, provider uses fallback "unset_while_netbox_not_available")
# Vault credentials (required for fnox auto-loading):
VAULT_TOKEN                    # Vault token — auto-set by mise from ~/.vault-token
VAULT_ADDR                     # Vault address — auto-set by mise to https://vault.home.sflab.io
VAULT_SKIP_VERIFY              # Auto-set to "true" by mise (homelab uses self-signed TLS cert)
VAULT_ROLE_ID                  # Vault AppRole role_id — used by the `vault:create-token` task to refresh ~/.vault-token on directory entry
VAULT_SECRET_ID                # Vault AppRole secret_id — used by the `vault:create-token` task to refresh ~/.vault-token on directory entry
```

**Note**: Environment variables are loaded automatically from:
- `~/.env` (optional, user home directory)
- `.env` (optional, project root)
- `.creds.env.yaml` (encrypted with SOPS, project root)
- Vault via fnox (`fnox.toml`, loaded by `fnox-env` mise plugin on directory entry)

## Development Workflow

### Deploying Infrastructure (Standard Workflow)

```bash
# 1. Deploy proxmox-pool first (one-time or when pool configuration changes)
cd staging/proxmox-pool
terragrunt stack run apply

# 2. Deploy application stacks (in any order)
cd staging/proxmox-vault-vm
terragrunt stack run apply

cd staging/proxmox-netbox-vm
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
  - Production: `catalog_version = "v0.22.0"` (pinned for stability)
- **Stack vs Unit**: Application stacks use `stack {}` blocks (referencing catalog stacks); `proxmox-pool`, `proxmox-mgm-shared-tags`, and `proxmox-platform-shared-tags` use `unit {}` blocks (referencing catalog units)
- **Environment Locals**: All stacks use `local.env = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals` to reference shared settings (`catalog_version`, `pool_id`, `zone`, `environment_name`, `ansible_ssh_public_key_path`, `admin_ssh_public_key_path`, `netbox_cluster_name`, `netbox_tenant_name`, `netbox_site_name`)
- **NetBox naming**: All NetBox identifiers use lowercase with hyphens (e.g., `proxmox-staging`, `platform-team`, `sflab-homelab-staging`)
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
- **Proxmox Endpoint**: `https://proxmox.home.sflab.io:8006/` (configured via `PROXMOX_VE_ENDPOINT` env var)
- **Cache Directories**: `.terragrunt-stack/` and `.terragrunt-cache/` are generated and should not be committed to git

## Troubleshooting

- **State backend issues**: Verify MinIO is accessible and credentials are set
- **Proxmox authentication**: Ensure `PROXMOX_VE_API_TOKEN` and `PROXMOX_VE_ENDPOINT` are set
- **NetBox authentication**: Ensure `NETBOX_API_TOKEN` is set (loaded automatically via fnox if Vault is accessible)
- **Cache corruption**: Run `mise run terragrunt:cleanup` to remove all cache directories
- **Resource conflicts**: If multiple stacks try to create the same resource (e.g., pool), move it to `proxmox-pool` stack
- **Unit dependencies**:
  - Within same stack: Use relative paths (e.g., `compute_path = "../proxmox-vm"`)
  - Across stacks: Reference by ID/name (e.g., `pool_id = "pool-staging"`)
- **Dagger cache issues**: If `mise run terragrunt:stack:apply` shows "Apply complete" but VM is missing, check state and use direct terragrunt (`mise run terragrunt:stack:apply-old`) instead
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

2. **proxmox-mgm-cluster** (`staging/proxmox-mgm-cluster/`)
   - Purpose: Management K3s cluster VMs (1 control plane + 2 workers) + NetBox K8s cluster registration
   - Contains: `vm_cp1`, `vm_w1`, `vm_w2` stacks + `netbox_k8s_cluster` stack
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only
   - Memory: 8192MB, Cores: 2, Disk: 32GB
   - SSH key: `keys/admin_id_ecdsa.pub`
   - Tags: node-specific tags + shared `mgm-staging` tag (via `extra_tags`)
   - NetBox K8s cluster: `mgm-staging`

3. **proxmox-mgm-shared-tags** (`staging/proxmox-mgm-shared-tags/`)
   - Purpose: NetBox tags shared across all mgm cluster nodes
   - Contains: `mgm_shared_tags` unit
   - Tags: `["mgm-staging"]`
   - Note: Uses `units/netbox-tags` catalog unit

4. **proxmox-authentik-vm** (`staging/proxmox-authentik-vm/`)
   - Purpose: Authentik SSO/identity provider VM
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal + wildcard
   - Memory: 2048MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`

5. **proxmox-vault-vm** (`staging/proxmox-vault-vm/`)
   - Purpose: HashiCorp Vault VM for secrets management
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: Static IP (192.168.1.33/24, gateway 192.168.1.1)
   - DNS servers: 192.168.1.13, 192.168.1.154
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`
   - Note: `virtual_machines = []` set to avoid circular dependency on first deploy

6. **proxmox-github-runner-vm** (`staging/proxmox-github-runner-vm/`)
   - Purpose: GitHub Actions runner VM
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - CPU type: `host` (required for Dagger support)
   - SSH key: `keys/admin_id_ecdsa.pub`

7. **proxmox-gitlab-runner-vm** (`staging/proxmox-gitlab-runner-vm/`)
   - Purpose: GitLab CI runner VM
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 16GB
   - CPU type: `host` (required for Dagger support)
   - SSH key: `keys/admin_id_ecdsa.pub`

8. **proxmox-dns-lxc** (`staging/proxmox-dns-lxc/`)
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

9. **proxmox-netbox-vm** (`staging/proxmox-netbox-vm/`)
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

10. **proxmox-example-vm** (`staging/proxmox-example-vm/`)
    - Purpose: Example/template VM stack for reference
    - Contains: `homelab_proxmox_vm` stack (VM + DNS)
    - Network: Static IP (192.168.1.45/24, gateway 192.168.1.1)
    - DNS records: normal only (no wildcard)
    - Memory: 2048MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`

11. **proxmox-example-lxc** (`staging/proxmox-example-lxc/`)
    - Purpose: Example/template LXC stack for reference
    - Contains: `homelab_proxmox_lxc` stack (LXC + DNS)
    - Network: Static IP (192.168.1.44/24, gateway 192.168.1.1)
    - DNS records: normal only (no wildcard)
    - Memory: 4096MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`
    - Requires: `PROXMOX_CONTAINER_PASSWORD` environment variable

12. **proxmox-platform-cluster** (`staging/proxmox-platform-cluster/`)
    - Purpose: Platform K3s cluster VMs (3 combined CP/worker nodes) + NetBox K8s cluster registration
    - Contains: `vm_cp1_w1`, `vm_cp2_w2`, `vm_cp_3_w3` stacks + `netbox_k8s_cluster` stack
    - References: `pool-staging` from proxmox-pool stack
    - DNS zone: `home.sflab.io.`
    - Network: DHCP
    - DNS records: normal only
    - Memory: 4096MB, Cores: 2, Disk: 32GB
    - SSH key: `keys/admin_id_ecdsa.pub`
    - Tags: node-specific tags + shared `platform-staging` tag (via `extra_tags`)
    - NetBox K8s cluster: `platform-staging`

13. **proxmox-platform-shared-tags** (`staging/proxmox-platform-shared-tags/`)
    - Purpose: NetBox tags shared across all platform cluster nodes
    - Contains: `platform_shared_tags` unit
    - Tags: `["platform-staging"]`
    - Note: Uses `units/netbox-tags` catalog unit

14. **proxmox-vaultwarden-vm** (`staging/proxmox-vaultwarden-vm/`)
    - Purpose: Vaultwarden password manager VM (self-hosted Bitwarden-compatible server)
    - Contains: `homelab_proxmox_vm` stack (VM + DNS)
    - References: `pool-staging` from proxmox-pool stack
    - DNS zone: `home.sflab.io.`
    - Network: DHCP
    - DNS records: normal + wildcard
    - Memory: 2048MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`

### Current Production Stacks

1. **proxmox-pool** (`production/proxmox-pool/`)
   - Purpose: Proxmox resource pool for production environment
   - Contains: `proxmox_pool` unit
   - Deploy first (required by other stacks)

2. **proxmox-mgm-cluster** (`production/proxmox-mgm-cluster/`)
   - Purpose: Management K3s cluster VMs — HA setup (3 control planes + 2 workers) + NetBox K8s cluster registration
   - Contains: `vm_cp1`, `vm_cp2`, `vm_cp3`, `vm_w1`, `vm_w2` stacks + `netbox_k8s_cluster` stack
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only
   - Memory: 4096MB, Cores: 2, Disk: 32GB
   - SSH key: `keys/admin_id_ecdsa.pub`
   - Tags: node-specific tags + shared `mgm-production` tag (via `extra_tags`)
   - NetBox K8s cluster: `mgm-production`

3. **proxmox-mgm-shared-tags** (`production/proxmox-mgm-shared-tags/`)
   - Purpose: NetBox tags shared across all mgm cluster nodes
   - Contains: `mgm_shared_tags` unit
   - Tags: `["mgm-production"]`
   - Note: Uses `units/netbox-tags` catalog unit

4. **proxmox-authentik-vm** (`production/proxmox-authentik-vm/`)
   - Purpose: Authentik SSO/identity provider VM (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal + wildcard
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`

5. **proxmox-vault-vm** (`production/proxmox-vault-vm/`)
   - Purpose: HashiCorp Vault VM for secrets management (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: Static IP (192.168.1.34/24, gateway 192.168.1.1)
   - DNS servers: 192.168.1.13, 192.168.1.154
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 8GB
   - SSH key: `keys/ansible_id_ecdsa.pub`
   - Note: `virtual_machines = []` set to avoid circular dependency on first deploy

6. **proxmox-github-runner-vm** (`production/proxmox-github-runner-vm/`)
   - Purpose: GitHub Actions runner VM (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - Memory: 4096MB, Disk: 16GB
   - CPU type: `host` (required for Dagger support)
   - SSH key: `keys/admin_id_ecdsa.pub`

7. **proxmox-gitlab-runner-vm** (`production/proxmox-gitlab-runner-vm/`)
   - Purpose: GitLab CI runner VM (production)
   - Contains: `homelab_proxmox_vm` stack (VM + DNS)
   - References: `pool-production` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
   - Network: DHCP
   - DNS records: normal only (no wildcard)
   - Memory: 8192MB, Disk: 16GB
   - CPU type: `host` (required for Dagger support)
   - SSH key: `keys/admin_id_ecdsa.pub`

8. **proxmox-dns-lxc** (`production/proxmox-dns-lxc/`)
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

9. **proxmox-netbox-vm** (`production/proxmox-netbox-vm/`)
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

10. **proxmox-example-vm** (`production/proxmox-example-vm/`)
    - Purpose: Example/template VM stack for reference (production)
    - Contains: `homelab_proxmox_vm` stack (VM + DNS)
    - Network: Static IP (192.168.1.45/24, gateway 192.168.1.1)
    - DNS records: normal only (no wildcard)
    - Memory: 4096MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`

11. **proxmox-example-lxc** (`production/proxmox-example-lxc/`)
    - Purpose: Example/template LXC stack for reference (production)
    - Contains: `homelab_proxmox_lxc` stack (LXC + DNS)
    - Network: Static IP (192.168.1.44/24, gateway 192.168.1.1)
    - DNS records: normal only (no wildcard)
    - Memory: 4096MB, Disk: 8GB
    - SSH key: `keys/ansible_id_ecdsa.pub`
    - Requires: `PROXMOX_CONTAINER_PASSWORD` environment variable

12. **proxmox-platform-cluster** (`production/proxmox-platform-cluster/`)
    - Purpose: Platform K3s cluster VMs (3 combined CP/worker nodes) + NetBox K8s cluster registration
    - Contains: `vm_cp1_w1`, `vm_cp2_w2`, `vm_cp_3_w3` stacks + `netbox_k8s_cluster` stack
    - References: `pool-production` from proxmox-pool stack
    - DNS zone: `home.sflab.io.`
    - Network: DHCP
    - DNS records: normal only
    - Memory: 4096MB, Cores: 2, Disk: 32GB
    - SSH key: `keys/admin_id_ecdsa.pub`
    - Tags: node-specific tags + shared `platform-production` tag (via `extra_tags`)
    - NetBox K8s cluster: `platform-production`

13. **proxmox-platform-shared-tags** (`production/proxmox-platform-shared-tags/`)
    - Purpose: NetBox tags shared across all platform cluster nodes
    - Contains: `platform_shared_tags` unit
    - Tags: `["platform-production"]`
    - Note: Uses `units/netbox-tags` catalog unit
