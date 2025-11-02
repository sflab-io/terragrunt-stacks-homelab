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
├── root.hcl                    # Root Terragrunt config: provider generation, remote state, catalog URLs
├── {environment}/              # Environment directories (staging, production)
│   ├── environment.hcl         # Environment-specific variables
│   ├── shared-resources/       # Environment-wide shared resources (pools, networks, etc.)
│   │   └── terragrunt.stack.hcl
│   └── {stack-name}/           # Individual stack deployments
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
   - Proxmox provider configuration
   - S3 backend configuration (MinIO)
   - Catalog repository URLs
   - Reads environment variables from `environment.hcl`

2. **environment.hcl**: Environment-specific variables (e.g., `environment_name = "staging"`)

3. **terragrunt.stack.hcl**: Stack definition with multiple units
   - Each unit references a module from the catalog
   - Units can have dependencies on each other within the same stack
   - Local variables define stack-wide settings

### Shared Resources Pattern

The repository uses a **shared-resources** stack pattern for environment-wide resources:

- **shared-resources Stack**: Contains resources shared across multiple application stacks
  - Located at `{environment}/shared-resources/`
  - Currently manages the Proxmox resource pool for the environment
  - Must be deployed **before** application stacks that depend on these resources

- **Application Stacks**: Reference shared resources by ID/name (e.g., `pool_id = "pool-staging"`)
  - Do not create shared resources themselves
  - Depend on shared resources being pre-deployed
  - Examples: `docker-homelab-proxmox-vm`, `pki-homelab-proxmox-vm`

**Deployment Order**:
1. Deploy `shared-resources` stack first (one-time or when shared resources change)
2. Deploy application stacks in any order (they all reference the same shared pool)

### Remote State Backend

- Uses **MinIO** as S3-compatible backend
- Bucket naming: `{environment_name}-homelab-terragrunt-tfstates`
- Requires environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- MinIO endpoint: `http://minio.home.sflab.io:9000`

### Infrastructure Catalog

External module repository: `git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git`
- Contains reusable Terraform modules for infrastructure components
- Referenced via git source URLs in stack unit definitions
- Version pinning recommended via `?ref=vX.Y.Z` (currently using latest from default branch)

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
```

### Terragrunt Operations

```bash
# Navigate to a stack directory first
cd staging/docker-homelab-proxmox-vm

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
cd staging/docker-homelab-proxmox-vm/.terragrunt-stack/proxmox-vm

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

Proxmox authentication is handled via SSH agent (configured in root.hcl).

## Development Workflow

### Deploying Infrastructure (Standard Workflow)

```bash
# 1. Deploy shared resources first (one-time or when shared resources change)
cd staging/shared-resources
terragrunt stack run apply

# 2. Deploy application stacks (in any order)
cd staging/docker-homelab-proxmox-vm
terragrunt stack run apply

cd staging/pki-homelab-proxmox-vm
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
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment_name = local.environment_vars.locals.environment_name
  name = "my-app-${local.environment_name}"
}

unit "proxmox_vm" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm"
  path = "proxmox-vm"

  values = {
    version = "main"
    vm_name = "vm-myapp-${local.environment_name}"
    pool_id = "pool-${local.environment_name}"  # References shared pool
  }
}
```

### Adding a New Unit to Existing Stack

1. Edit `terragrunt.stack.hcl` in the stack directory
2. Add new `unit` block with source, path, and values
3. Units within the same stack can depend on each other using relative paths (e.g., `vm_unit_path = "../proxmox-vm"`)
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

- **Shared Resources First**: Always deploy the `shared-resources` stack before application stacks in each environment
- **Version Pinning**: Production stacks should pin catalog module versions using `?ref=vX.Y.Z` in source URLs
- **Stack vs Unit**: Most operations should be run at the stack level for consistency
- **Generated Files**: `provider.tf` and `backend.tf` are auto-generated by Terragrunt from root.hcl
- **Dependencies**:
  - Units within a stack can reference each other using relative paths (e.g., `vm_unit_path = "../proxmox-vm"`)
  - Cross-stack dependencies (like shared pools) are referenced by ID/name, not paths
- **State Management**: Each unit gets its own state file in the S3 bucket, organized by path
- **Proxmox Endpoint**: Currently configured for `proxmox.home.sflab.io:8006`
- **Cache Directories**: `.terragrunt-stack/` and `.terragrunt-cache/` are generated and should not be committed to git

## Troubleshooting

- **State backend issues**: Verify MinIO is accessible and credentials are set
- **SSH authentication to Proxmox**: Ensure SSH agent is running with appropriate keys loaded
- **Cache corruption**: Run `mise run terragrunt:cleanup` to remove all cache directories
- **Resource conflicts**: If multiple stacks try to create the same resource (e.g., pool), move it to `shared-resources` stack
- **Unit dependencies**:
  - Within same stack: Use relative paths (e.g., `vm_unit_path = "../proxmox-vm"`)
  - Across stacks: Reference by ID/name (e.g., `pool_id = "pool-staging"`)
- **Command not found**: Use `terragrunt stack run <command>` not `terragrunt stack <command>`

## Example Stacks

### Current Staging Stacks

1. **shared-resources** (`staging/shared-resources/`)
   - Purpose: Environment-wide shared resources
   - Contains: `proxmox_pool` unit
   - Deploy first

2. **docker-homelab-proxmox-vm** (`staging/docker-homelab-proxmox-vm/`)
   - Purpose: Docker host VM
   - Contains: `proxmox_vm`, `dns` units
   - References: `pool-staging` from shared-resources

3. **pki-homelab-proxmox-vm** (`staging/pki-homelab-proxmox-vm/`)
   - Purpose: PKI/Certificate management VM
   - Contains: `proxmox_vm`, `dns` units
   - References: `pool-staging` from shared-resources
