# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Terragrunt infrastructure-live repository** for managing homelab infrastructure (Proxmox VMs and LXC containers). It uses:
- **Terragrunt Stacks** for organizing infrastructure deployments
- **MinIO** as an S3-compatible backend for Terraform state storage
- **Proxmox** as the target infrastructure platform
- Environment-based organization (staging, production)

The repository follows Terragrunt's "infrastructure-live" pattern where configurations reference reusable modules from a separate "infrastructure-catalog" repository.
The local catalog repository is located at: `../terragrunt-infrastructure-catalog-homelab/`

## Key Architecture Concepts

### Repository Structure

```
├── root.hcl                    # Root Terragrunt config: remote state, catalog URLs
├── provider-config.hcl         # Proxmox provider configuration
├── dns-config.hcl              # DNS provider configuration
├── {environment}/              # Environment directories (staging, production)
│   ├── environment.hcl         # Environment-specific variables
│   ├── backend-config.hcl      # Environment-specific backend configuration
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
- **Source**: Units reference modules from the catalog repository: `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/{unit-name}`
- **Path**: Where the unit is deployed within the `.terragrunt-stack/` directory
- **Values**: Configuration passed to the underlying Terraform module

### Configuration Hierarchy

1. **root.hcl**: Defines global settings inherited by all stacks
   - S3 backend configuration (reads from `backend-config.hcl`)
   - Catalog repository URLs
   - Note: Provider configuration has been moved to separate files

2. **provider-config.hcl**: Proxmox provider configuration
   - Generates `provider.tf` for Proxmox provider
   - Configured for SSH agent authentication

3. **dns-config.hcl**: DNS provider configuration
   - DNS server: 192.168.1.13:5353
   - Key settings for dynamic DNS updates (hmac-sha512)
   - Used for automatic DNS record creation for VMs

4. **environment.hcl**: Environment-specific variables (e.g., `environment_name = "staging"`)

5. **backend-config.hcl**: Environment-specific backend configuration
   - Defines S3 backend prefix, endpoint, and credentials
   - Located in each environment directory
   - Note: Currently only configured for staging environment

6. **terragrunt.stack.hcl**: Stack definition with multiple units
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
  - Examples: `proxmox-docker-vm`, `proxmox-pki-vm`

**Deployment Order**:
1. Deploy `proxmox-pool` stack first (one-time or when pool configuration changes)
2. Deploy application stacks in any order (they all reference the same pool)

### Remote State Backend

- Uses **MinIO** as S3-compatible backend
- Bucket naming: `{prefix}-tfstates` (e.g., `staging-terragrunt-tfstates`)
  - Prefix is defined in `{environment}/backend-config.hcl`
- Requires environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- MinIO endpoint: `http://minio.home.sflab.io:9000`
- Configuration is environment-specific via `backend-config.hcl` files

### Infrastructure Catalog

External module repository: `git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git`
- Contains reusable Terraform modules for infrastructure components
- Referenced via git source URLs in stack unit definitions
- Version pinning via `?ref=branch-or-tag` (currently using `?ref=feat/next` for staging stacks)

**Available Units** (as used in current stacks):
- `proxmox-pool`: Proxmox resource pool management
- `proxmox-vm`: Proxmox virtual machine provisioning
- `dns`: Dynamic DNS record creation (depends on compute_path)

## Common Commands

### Mise Task Management

```bash
# List all available tasks
mise tasks

# Setup MinIO backend (creates bucket, service account)
mise run minio:setup

# List MinIO bucket contents
mise run minio:list

# Edit encrypted secrets (SOPS)
mise run secrets:edit

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
```

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

# View stack dependencies
terragrunt stack graph

# Generate stack without applying
terragrunt stack generate

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
AWS_ACCESS_KEY_ID          # MinIO access key for state backend
AWS_SECRET_ACCESS_KEY      # MinIO secret key for state backend
MINIO_USERNAME             # MinIO admin username (for setup tasks)
MINIO_PASSWORD             # MinIO admin password (for setup tasks)
```

Proxmox authentication is handled via SSH agent (configured in provider-config.hcl).

## Development Workflow

### Deploying Infrastructure (Standard Workflow)

```bash
# 1. Deploy proxmox-pool first (one-time or when pool configuration changes)
cd staging/proxmox-pool
terragrunt stack run apply

# 2. Deploy application stacks (in any order)
cd staging/proxmox-docker-vm
terragrunt stack run apply

cd staging/proxmox-pki-vm
terragrunt stack run apply
```

### Adding a New Stack

1. Create directory: `{environment}/{stack-name}/`
2. Create `terragrunt.stack.hcl` with unit definitions
3. Reference catalog modules via git URLs (with optional version pinning via `?ref=branch-or-tag`)
4. Define unit values (referencing shared resources by ID if needed)
5. Run `terragrunt stack run plan` to preview changes
6. Run `terragrunt stack run apply` to deploy

**Example Stack Structure**:
```hcl
locals {
  version = "feat/next"

  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment_name = local.environment_vars.locals.environment_name

  pool_id = "pool-${local.environment_name}"
  vm_name = "myapp-vm-${local.environment_name}"
  zone = "home.sflab.io."
}

unit "proxmox_vm" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${local.version}"
  path = "proxmox-vm"

  values = {
    version = local.version
    vm_name = local.vm_name
    pool_id = local.pool_id  # References shared pool
  }
}

unit "dns" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${local.version}"
  path = "dns"

  values = {
    version = local.version
    zone = local.zone
    name = local.vm_name
    compute_path = "../proxmox-vm"  # References VM unit in same stack
  }
}
```

### Adding a New Unit to Existing Stack

1. Edit `terragrunt.stack.hcl` in the stack directory
2. Add new `unit` block with source, path, and values
3. Units within the same stack can depend on each other using relative paths (e.g., `compute_path = "../proxmox-vm"`)
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
- **Version Pinning**: Currently using `?ref=feat/next` for staging stacks; production stacks should use stable tags
- **Stack vs Unit**: Most operations should be run at the stack level for consistency
- **Generated Files**: `provider.tf` and `backend.tf` are auto-generated by Terragrunt
  - Provider configuration from `provider-config.hcl`
  - Backend configuration from `root.hcl` (which reads `backend-config.hcl`)
- **Configuration Files**:
  - `provider-config.hcl`: Proxmox provider settings (at repository root)
  - `dns-config.hcl`: DNS provider settings (at repository root)
  - `backend-config.hcl`: S3 backend settings (per environment)
- **Dependencies**:
  - Units within a stack can reference each other using relative paths (e.g., `compute_path = "../proxmox-vm"`)
  - Cross-stack dependencies (like shared pools) are referenced by ID/name, not paths
- **State Management**: Each unit gets its own state file in the S3 bucket, organized by path
- **Proxmox Endpoint**: Currently configured for `https://proxmox.home.sflab.io:8006/`
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

## Example Stacks

### Current Staging Stacks

1. **proxmox-pool** (`staging/proxmox-pool/`)
   - Purpose: Proxmox resource pool for staging environment
   - Contains: `proxmox_pool` unit
   - Deploy first (required by other stacks)

2. **proxmox-docker-vm** (`staging/proxmox-docker-vm/`)
   - Purpose: Docker host VM
   - Contains: `proxmox_vm`, `dns` units
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`

3. **proxmox-pki-vm** (`staging/proxmox-pki-vm/`)
   - Purpose: PKI/Certificate management VM
   - Contains: `proxmox_vm`, `dns` units
   - References: `pool-staging` from proxmox-pool stack
   - DNS zone: `home.sflab.io.`
