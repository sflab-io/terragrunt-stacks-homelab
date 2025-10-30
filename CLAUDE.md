# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Terragrunt infrastructure-live repository** for managing homelab infrastructure (Proxmox VMs and LXC containers). It uses:
- **Terragrunt Stacks** for organizing infrastructure deployments
- **MinIO** as an S3-compatible backend for Terraform state storage
- **Proxmox** as the target infrastructure platform
- Environment-based organization (staging, production)

The repository follows Terragrunt's "infrastructure-live" pattern where configurations reference reusable modules from a separate "infrastructure-catalog" repository.

## Key Architecture Concepts

### Repository Structure

```
├── root.hcl                    # Root Terragrunt config: provider generation, remote state, catalog URLs
├── {environment}/              # Environment directories (staging, production)
│   ├── environment.hcl         # Environment-specific variables
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
   - Units can have dependencies on each other
   - Local variables define stack-wide settings

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
```

### Terragrunt Operations

```bash
# Navigate to a stack directory first
cd staging/docker-homelab-proxmox-vm

# View stack plan
terragrunt stack plan

# Apply stack changes
terragrunt stack apply

# Destroy stack resources
terragrunt stack destroy

# View stack dependencies
terragrunt stack graph

# Browse available catalog modules
terragrunt catalog
```

### Working with Individual Units

```bash
# Navigate to a specific unit directory
cd staging/docker-homelab-proxmox-vm/.terragrunt-stack/proxmox-pool

# Standard Terragrunt commands work on individual units
terragrunt plan
terragrunt apply
terragrunt destroy
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

### Adding a New Stack

1. Create directory: `{environment}/{stack-name}/`
2. Create `terragrunt.stack.hcl` with unit definitions
3. Reference catalog modules via git URLs
4. Define unit values and dependencies
5. Run `terragrunt stack plan` to preview changes

### Adding a New Unit to Existing Stack

1. Edit `terragrunt.stack.hcl` in the stack directory
2. Add new `unit` block with source, path, and values
3. Use relative paths for dependencies between units (e.g., `sg_path = "../../sgs/asg"`)
4. Run `terragrunt stack plan` to preview

### Modifying Infrastructure

1. Edit values in `terragrunt.stack.hcl`
2. Run `terragrunt stack plan` to review changes
3. Run `terragrunt stack apply` to apply changes
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

- **Version Pinning**: Production stacks should pin catalog module versions using `?ref=vX.Y.Z` in source URLs
- **Stack vs Unit**: Most operations should be run at the stack level for consistency
- **Generated Files**: `provider.tf` and `backend.tf` are auto-generated by Terragrunt from root.hcl
- **Dependencies**: Units within a stack can reference each other using relative paths
- **State Management**: Each unit gets its own state file in the S3 bucket, organized by path
- **Proxmox Endpoint**: Currently configured for `proxmox.home.sflab.io:8006`

## Troubleshooting

- **State backend issues**: Verify MinIO is accessible and credentials are set
- **SSH authentication to Proxmox**: Ensure SSH agent is running with appropriate keys loaded
- **Cache corruption**: Run `mise run terragrunt:cleanup` to remove all cache directories
- **Unit dependencies**: Check that relative paths in `values` correctly reference other units
