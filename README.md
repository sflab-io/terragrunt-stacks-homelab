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
├── provider-config.hcl         # Proxmox provider settings
├── dns-config.hcl              # DNS provider settings
├── mise.toml                   # Tool version management
├── keys/                       # SSH public keys
│   ├── ansible_id_ecdsa.pub
│   └── admin_id_ecdsa.pub
├── staging/                    # Staging environment
│   ├── environment.hcl
│   ├── backend-config.hcl
│   ├── proxmox-pool/
│   ├── proxmox-docker-vm/
│   ├── proxmox-k3s-vms/
│   ├── proxmox-vault-vm/
│   ├── proxmox-github-runner-lxc/
│   └── proxmox-dns-lxc/
└── production/                 # Production environment
    ├── environment.hcl
    ├── backend-config.hcl
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

# LXC containers
PROXMOX_CONTAINER_PASSWORD=<container-password>

# DNS dynamic updates
TF_VAR_dns_key_secret=<dns-tsig-key-secret>
```

Environment variables are loaded from:
- `~/.env` (optional)
- `.env` (optional, project root)
- `.creds.env.yaml` (encrypted with SOPS, project root)

### Tool Versions

Managed automatically via `mise.toml`:
- **Go**: 1.24.2
- **OpenTofu**: 1.9.0
- **Terragrunt**: 0.78.0
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

| Stack | Purpose | Components | Network |
|-------|---------|------------|---------|
| **proxmox-pool** | Resource pool | `proxmox_pool` | - |
| **proxmox-docker-vm** | Docker host | VM + DNS | DHCP |
| **proxmox-k3s-vms** | K3s cluster | 1 CP + 1 Worker | DHCP |
| **proxmox-vault-vm** | Vault server | VM + DNS | Static (192.168.1.33) |
| **proxmox-github-runner-lxc** | GitHub Actions runner | LXC + DNS | DHCP |
| **proxmox-dns-lxc** | DNS servers | 2 LXC containers | Static (192.168.1.153-154) |

### Production Environment

| Stack | Purpose | Components | Network |
|-------|---------|------------|---------|
| **proxmox-pool** | Resource pool | `proxmox_pool` | - |
| **proxmox-docker-vm** | Docker host | VM + DNS | DHCP |
| **proxmox-k3s-vms** | K3s cluster | 1 CP + 2 Workers | DHCP |
| **proxmox-vault-vm** | Vault server | VM + DNS | Static (192.168.1.34) |
| **proxmox-github-runner-lxc** | GitHub Actions runner | LXC + DNS | DHCP |
| **proxmox-dns-lxc** | DNS secondary | 1 LXC container | Static (192.168.1.154) |

## Development Workflow

### Adding a New Stack

1. Create stack directory: `{environment}/{stack-name}/`
2. Create `terragrunt.stack.hcl` with unit definitions
3. Reference catalog modules:
   ```hcl
   unit "proxmox_vm" {
     source = "git::git@github.com:sflab-io/terragrunt-catalog-homelab.git//units/proxmox-vm?ref=main"
     path = "proxmox-vm"
     values = { ... }
   }
   ```
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
2. `provider-config.hcl` - Proxmox provider (SSH agent auth)
3. `dns-config.hcl` - DNS provider (TSIG key auth)
4. `{environment}/environment.hcl` - Environment variables
5. `{environment}/backend-config.hcl` - Backend settings
6. `{stack}/terragrunt.stack.hcl` - Stack units and values

## Infrastructure Catalog

External module repository: [terragrunt-infrastructure-catalog-homelab](https://github.com/sflab-io/terragrunt-infrastructure-catalog-homelab)

**Available units:**
- `proxmox-pool` - Proxmox resource pool
- `proxmox-vm` - Virtual machine provisioning
- `proxmox-lxc` - LXC container provisioning
- `dns` - Dynamic DNS record creation

## Important Notes

- Deploy `proxmox-pool` stack before application stacks
- Use `terragrunt stack run <command>` (not `terragrunt stack <command>`)
- Cache directories (`.terragrunt-stack/`, `.terragrunt-cache/`) are auto-generated
- Provider and backend configs are auto-generated by Terragrunt
- Proxmox endpoint: `https://192.168.1.12:8006/`
- DNS server: `192.168.1.13:53`

## Additional Resources

- **CLAUDE.md** - Detailed documentation for Claude Code
- **[Terragrunt Documentation](https://terragrunt.gruntwork.io/)**
- **[OpenTofu Documentation](https://opentofu.org/docs/)**
- **[Proxmox Documentation](https://pve.proxmox.com/pve-docs/)**

## License

[Your License Here]

## Contributing

[Your Contributing Guidelines Here]
