# Terragrunt Stacks Homelab

Infrastructure-as-Code repository for managing homelab infrastructure using Terragrunt Stacks, OpenTofu, and Proxmox.

## Overview

This repository manages homelab infrastructure (VMs and LXC containers) on Proxmox using:

- **[Terragrunt Stacks](https://terragrunt.gruntwork.io/docs/features/stacks/)** - Multi-unit infrastructure deployments
- **[OpenTofu](https://opentofu.org/)** - Open-source Terraform fork
- **[Proxmox](https://www.proxmox.com/)** - Virtualization platform
- **[MinIO](https://min.io/)** - S3-compatible backend for state storage
- **[mise](https://mise.jdx.dev/)** - Development tool version management

## Repository Structure

```
.
├── root.hcl                    # Global Terragrunt configuration
├── provider-proxmox-config.hcl # Proxmox provider settings
├── provider-dns-config.hcl     # DNS provider settings
├── mise.toml                   # Tool version management
├── keys/                       # SSH public keys
│   ├── ansible_id_ecdsa.pub
│   └── admin_id_ecdsa.pub
├── staging/                    # Staging environment
│   ├── environment.hcl
│   ├── backend-config.hcl
│   ├── provider-netbox-config.hcl
│   ├── proxmox-pool/
│   ├── proxmox-docker-vm/
│   ├── proxmox-k3s-vms/
│   ├── proxmox-vault-vm/
│   ├── proxmox-github-runner-vm/
│   ├── proxmox-gitlab-runner-vm/
│   ├── proxmox-dns-lxc/
│   ├── proxmox-netbox-vm/
│   ├── proxmox-example-vm/
│   └── proxmox-example-lxc/
└── production/                 # Production environment
    ├── environment.hcl
    ├── backend-config.hcl
    ├── provider-netbox-config.hcl
    └── [same stacks as staging]
```

## Quick Start

### Prerequisites

- **SSH agent** with Proxmox SSH key loaded
- **Environment variables** configured (see [Configuration](#configuration))
- **mise** installed ([installation guide](https://mise.jdx.dev/getting-started.html))

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd terragrunt-stacks-homelab
   ```

2. **Install tools** (mise will auto-install on directory entry)
   ```bash
   mise install
   ```

3. **Configure environment variables**
   ```bash
   # Edit encrypted secrets file
   mise run secrets:edit .creds.env.yaml
   ```

4. **Setup MinIO backend**
   ```bash
   mise run minio:setup
   ```

### Deploy Infrastructure

1. **Deploy resource pool** (required first)
   ```bash
   cd staging/proxmox-pool
   terragrunt stack run apply
   ```

2. **Deploy application stacks**
   ```bash
   # Interactive mode (recommended)
   mise run terragrunt:stack:apply

   # Or navigate to specific stack
   cd staging/proxmox-docker-vm
   terragrunt stack run apply
   ```

## Configuration

### Required Environment Variables

```bash
# MinIO state backend
AWS_ACCESS_KEY_ID=<minio-access-key>
AWS_SECRET_ACCESS_KEY=<minio-secret-key>

# MinIO admin (for setup tasks)
MINIO_USERNAME=<minio-admin-username>
MINIO_PASSWORD=<minio-admin-password>

# LXC containers (dns-lxc, example-lxc stacks)
PROXMOX_CONTAINER_PASSWORD=<container-password>

# DNS dynamic updates
TF_VAR_dns_key_secret=<dns-tsig-key-secret>

# NetBox API token (for IPAM/DCIM registration)
TF_VAR_netbox_token=<netbox-api-token>
```

Environment variables are loaded from:
- `~/.env` (optional)
- `.env` (optional, project root)
- `.creds.env.yaml` (encrypted with SOPS, project root)

### Tool Versions

Managed automatically via `mise.toml`:
- **Go**: 1.24.2
- **OpenTofu**: 1.11.5
- **Terragrunt**: 0.99.4
- **MinIO Client**: latest

## Common Commands

### Mise Tasks

```bash
# List available tasks
mise tasks

# MinIO management
mise run minio:setup              # Setup MinIO backend
mise run minio:list               # List bucket contents

# Terragrunt stack operations (interactive)
mise run terragrunt:stack:plan    # Plan stack changes
mise run terragrunt:stack:apply   # Apply stack changes
mise run terragrunt:stack:destroy # Destroy stack resources
mise run terragrunt:stack:output  # View stack outputs

# Utilities
mise run terragrunt:cleanup       # Clean cache directories
mise run network:configure        # Configure network settings
mise run network:status           # View network status
mise run secrets:edit <file>      # Edit SOPS-encrypted secrets
```

### Terragrunt Commands

```bash
# Navigate to stack directory
cd staging/proxmox-docker-vm

# Stack operations
terragrunt stack run plan         # Preview changes
terragrunt stack run apply        # Apply changes
terragrunt stack run destroy      # Destroy resources
terragrunt stack generate         # Generate stack files
terragrunt stack output           # View outputs
terragrunt stack clean            # Clean generated files

# Catalog browsing
terragrunt catalog                # Browse available modules
```

## Infrastructure Stacks

### Staging Environment

| Stack | Purpose | Type | Network |
|-------|---------|------|---------|
| **proxmox-pool** | Resource pool | Unit | - |
| **proxmox-docker-vm** | Docker host | VM + DNS | DHCP |
| **proxmox-k3s-vms** | K3s cluster (1 CP + 1 Worker) | 2× VM + DNS | DHCP |
| **proxmox-vault-vm** | HashiCorp Vault | VM + DNS | Static (192.168.1.33) |
| **proxmox-github-runner-vm** | GitHub Actions runner | VM + DNS | DHCP |
| **proxmox-gitlab-runner-vm** | GitLab CI runner | VM + DNS | DHCP |
| **proxmox-dns-lxc** | Technitium DNS (primary + secondary) | 2× LXC + DNS | Static (192.168.1.153-154) |
| **proxmox-netbox-vm** | NetBox IPAM/DCIM | VM + DNS | Static (192.168.1.88) |
| **proxmox-example-vm** | Example VM template | VM + DNS | Static (192.168.1.45) |
| **proxmox-example-lxc** | Example LXC template | LXC + DNS | Static (192.168.1.44) |

### Production Environment

| Stack | Purpose | Type | Network |
|-------|---------|------|---------|
| **proxmox-pool** | Resource pool | Unit | - |
| **proxmox-docker-vm** | Docker host | VM + DNS | DHCP |
| **proxmox-k3s-vms** | K3s cluster (1 CP + 1 Worker) | 2× VM + DNS | DHCP |
| **proxmox-vault-vm** | HashiCorp Vault | VM + DNS | Static (192.168.1.34) |
| **proxmox-github-runner-vm** | GitHub Actions runner | VM + DNS | DHCP |
| **proxmox-gitlab-runner-vm** | GitLab CI runner | VM + DNS | DHCP |
| **proxmox-dns-lxc** | Technitium DNS secondary | LXC + DNS | Static (192.168.1.154) |
| **proxmox-netbox-vm** | NetBox IPAM/DCIM | VM + DNS | Static (192.168.1.89) |
| **proxmox-example-vm** | Example VM template | VM + DNS | Static (192.168.1.45) |
| **proxmox-example-lxc** | Example LXC template | LXC + DNS | Static (192.168.1.44) |

## Development Workflow

### Adding a New Stack

1. Create stack directory: `{environment}/{stack-name}/`
2. Create `terragrunt.stack.hcl` with unit definitions
3. Reference catalog modules:
   ```hcl
   stack "homelab_proxmox_vm" {
     source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//stacks/homelab-proxmox-vm?ref=${local.env.catalog_version}"
     path   = "homelab-proxmox-vm"
     values = { ... }
   }
   ```
   > **Note**: Use `stack {}` blocks for catalog stacks (VM, LXC). Only `proxmox-pool` uses `unit {}` blocks.
4. Plan and apply:
   ```bash
   terragrunt stack run plan
   terragrunt stack run apply
   ```

### Modifying Infrastructure

1. Edit `terragrunt.stack.hcl` in stack directory
2. Review changes: `terragrunt stack run plan`
3. Apply changes: `terragrunt stack run apply`

### Troubleshooting

**Cache issues:**
```bash
mise run terragrunt:cleanup
```

**State backend issues:**
- Verify MinIO accessibility: `http://192.168.1.20:9000`
- Check credentials: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

**SSH authentication:**
- Ensure SSH agent is running
- Load Proxmox SSH key: `ssh-add ~/.ssh/proxmox_key`

**DHCP IP conflicts:**
- VMs cloned from same template may share `/etc/machine-id`
- Template must have empty `/etc/machine-id` (regenerated on first boot)

## Architecture

### Terragrunt Stacks Pattern

- **Stack**: Collection of related infrastructure units
- **Unit**: Single infrastructure component (VM, LXC, DNS record)
- **Catalog**: External repository with reusable modules

### Shared Resources

- **proxmox-pool**: Environment-wide resource pool (deploy first)
- Application stacks reference pool: `pool_id = "pool-staging"`

### State Management

- Each unit gets dedicated state file in MinIO
- Bucket naming: `{environment}-terragrunt-tfstates`
- State organized by unit path

### Configuration Hierarchy

1. `root.hcl` - Global settings, backend config
2. `provider-proxmox-config.hcl` - Proxmox provider (SSH agent auth)
3. `provider-dns-config.hcl` - DNS provider (TSIG key auth)
4. `{environment}/provider-netbox-config.hcl` - NetBox provider (per environment)
5. `{environment}/environment.hcl` - Environment variables + NetBox metadata
6. `{environment}/backend-config.hcl` - Backend settings
7. `{stack}/terragrunt.stack.hcl` - Stack units and values

## Infrastructure Catalog

External module repository: [terragrunt-infrastructure-catalog-homelab](https://github.com/sflab-io/terragrunt-infrastructure-catalog-homelab)

**Available catalog items:**
- `stacks/homelab-proxmox-vm` - Combined VM + DNS + NetBox stack (use `stack {}` block)
- `stacks/homelab-proxmox-lxc` - Combined LXC + DNS + NetBox stack (use `stack {}` block)
- `units/proxmox-pool` - Proxmox resource pool management (use `unit {}` block)

## Important Notes

- Deploy `proxmox-pool` stack before application stacks
- Use `terragrunt stack run <command>` (not `terragrunt stack <command>`)
- Cache directories (`.terragrunt-stack/`, `.terragrunt-cache/`) are auto-generated
- Provider and backend configs are auto-generated by Terragrunt
- Proxmox endpoint: `https://proxmox.home.sflab.io:8006/`
- DNS server: `192.168.1.13:53`
- NetBox: Staging at `http://netbox-staging.home.sflab.io`, Production at `http://netbox.home.sflab.io`
- `proxmox-netbox-vm` must be deployed with `virtual_machines = []` on first run to avoid circular dependency

## Additional Resources

- **CLAUDE.md** - Detailed documentation for Claude Code
- **[Terragrunt Documentation](https://terragrunt.gruntwork.io/)**
- **[OpenTofu Documentation](https://opentofu.org/docs/)**
- **[Proxmox Documentation](https://pve.proxmox.com/pve-docs/)**
