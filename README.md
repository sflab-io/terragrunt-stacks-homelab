# Terragrunt Stacks Homelab

Infrastructure-as-Code repository for managing homelab infrastructure using Terragrunt Stacks, OpenTofu, and Proxmox.

## Overview

This repository manages homelab infrastructure (VMs and LXC containers) on Proxmox using:

- **[Terragrunt Stacks](https://terragrunt.gruntwork.io/docs/features/stacks/)** - Multi-unit infrastructure deployments
- **[OpenTofu](https://opentofu.org/)** - Open-source Terraform fork
- **[Proxmox](https://www.proxmox.com/)** - Virtualization platform
- **[MinIO](https://min.io/)** - S3-compatible backend for state storage
- **[Dagger](https://dagger.io/)** - CI/CD pipeline for running stack operations
- **[mise](https://mise.jdx.dev/)** - Development tool version management
- **[HashiCorp Vault](https://www.vaultproject.io/)** + **[Teller](https://tlr.dev/)** - Secrets management and automatic env var injection

## Repository Structure

```
.
├── root.hcl                    # Global Terragrunt configuration
├── provider-proxmox-config.hcl # Proxmox provider settings
├── provider-dns-config.hcl     # DNS provider settings
├── dagger.json                 # Dagger module configuration
├── .dagger/                    # Dagger TypeScript module source
├── .teller.yml                 # Teller config: maps Vault secrets to env vars
├── .pre-commit-config.yaml     # Pre-commit hooks (gitleaks, tofu-fmt, catalog version check)
├── mise.toml                   # Tool version management
├── keys/                       # SSH public keys
│   ├── ansible_id_ecdsa.pub
│   └── admin_id_ecdsa.pub
├── scripts/                    # Helper scripts (added to PATH via mise)
│   └── load-vault-secrets.sh   # Auto-sourced on directory entry — loads secrets from Vault via Teller
├── .hooks/                     # Git hook scripts
│   └── check-staging-catalog-version.sh  # Pre-commit: enforces catalog_version="main" in staging
├── staging/                    # Staging environment
│   ├── environment.hcl
│   ├── backend-config.hcl
│   ├── provider-netbox-config.hcl
│   ├── proxmox-pool/
│   ├── proxmox-authentik-vm/
│   ├── proxmox-mgm-cluster/
│   ├── proxmox-mgm-shared-tags/
│   ├── proxmox-vault-vm/
│   ├── proxmox-github-runner-vm/
│   ├── proxmox-gitlab-runner-vm/
│   ├── proxmox-dns-lxc/
│   ├── proxmox-netbox-vm/
│   ├── proxmox-platform-cluster/
│   ├── proxmox-platform-shared-tags/
│   ├── proxmox-example-vm/
│   └── proxmox-example-lxc/
└── production/                 # Production environment
    ├── environment.hcl
    ├── backend-config.hcl
    ├── provider-netbox-config.hcl
    ├── proxmox-pool/
    ├── proxmox-authentik-vm/
    ├── proxmox-mgm-cluster/
    ├── proxmox-mgm-shared-tags/
    ├── proxmox-vault-vm/
    ├── proxmox-github-runner-vm/
    ├── proxmox-gitlab-runner-vm/
    ├── proxmox-dns-lxc/
    ├── proxmox-netbox-vm/
    ├── proxmox-platform-cluster/
    ├── proxmox-platform-shared-tags/
    ├── proxmox-example-vm/
    └── proxmox-example-lxc/
```

## Quick Start

### Prerequisites

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
   # Interactive mode via Dagger (recommended)
   mise run terragrunt:stack:apply

   # Or navigate to specific stack
   cd staging/proxmox-vault-vm
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

# Proxmox API authentication
PROXMOX_VE_ENDPOINT=https://proxmox.home.sflab.io:8006
PROXMOX_VE_API_TOKEN=<proxmox-api-token>

# NetBox API tokens — auto-loaded from Vault via Teller on directory entry
NETBOX_API_TOKEN_PRODUCTION=<netbox-api-token>   # loaded from Vault: secrets_homelab/netbox_production
NETBOX_API_TOKEN_STAGING=<netbox-api-token>      # loaded from Vault: secrets_homelab/netbox_staging

# DNS TSIG key — auto-loaded from Vault via Teller on directory entry
TECHNITIUM_TSIG_KEY_NAME=<tsig-key-name>         # loaded from Vault: secrets_homelab/technitium
TECHNITIUM_TSIG_KEY_SECRET=<tsig-key-secret>     # loaded from Vault: secrets_homelab/technitium

# LXC containers (dns-lxc, example-lxc stacks)
PROXMOX_CONTAINER_PASSWORD=<container-password>

# Vault credentials (required for automatic NetBox token injection via Teller)
VAULT_TOKEN=<vault-token>         # or stored in ~/.vault-token
VAULT_ROLE_ID=<role-id>           # for AppRole login (alternative to token)
VAULT_SECRET_ID=<secret-id>       # for AppRole login (alternative to token)
```

Environment variables are loaded from:
- `~/.env` (optional)
- `.env` (optional, project root)
- `.creds.env.yaml` (encrypted with SOPS, project root)
- **Vault via Teller** (`load-vault-secrets.sh`) — automatically sourced by mise on directory entry

### Tool Versions

Managed automatically via `mise.toml`:
- **Go**: 1.26.3
- **OpenTofu**: 1.12.1
- **Terragrunt**: 1.0.6
- **Dagger**: latest
- **MinIO Client**: latest
- **Vault**: 1.21.1

## Common Commands

### Mise Tasks

```bash
# List available tasks
mise tasks

# MinIO management
mise run minio:setup              # Setup MinIO backend
mise run minio:list               # List bucket contents

# Terragrunt stack operations via Dagger (interactive)
mise run terragrunt:stack:plan    # Plan stack changes
mise run terragrunt:stack:apply   # Apply stack changes
mise run terragrunt:stack:destroy # Destroy stack resources
mise run terragrunt:stack:generate # Generate stack files
mise run terragrunt:stack:output  # View stack outputs

# Direct terragrunt (bypasses Dagger, uses --provider-cache)
mise run terragrunt:stack:apply-old
mise run terragrunt:stack:plan-old
mise run terragrunt:stack:generate-old
mise run terragrunt:stack:destroy-old
mise run terragrunt:stack:output-old

# Utilities
mise run terragrunt:cleanup       # Clean cache directories
mise run network:configure        # Configure network settings
mise run network:status           # View network status
mise run secrets:edit <file>      # Edit SOPS-encrypted secrets
```

All interactive tasks accept optional positional arguments:
```bash
mise run terragrunt:stack:apply staging proxmox-vault-vm
```

### Terragrunt Commands (Direct)

```bash
# Navigate to stack directory
cd staging/proxmox-vault-vm

# Stack operations
terragrunt stack run plan           # Preview changes
terragrunt stack run apply          # Apply changes
terragrunt stack run apply --non-interactive  # Apply without prompts
terragrunt stack run destroy        # Destroy resources
terragrunt stack run generate       # Generate stack files
terragrunt stack run output         # View outputs

# Catalog browsing
terragrunt catalog                  # Browse available modules
```

## Infrastructure Stacks

### Staging Environment

| Stack | Purpose | Type | Network |
|-------|---------|------|---------|
| **proxmox-pool** | Resource pool | Unit | - |
| **proxmox-authentik-vm** | Authentik SSO | VM + DNS | DHCP |
| **proxmox-mgm-cluster** | Management K3s cluster (1 CP + 2 Workers) + NetBox K8s | 3× VM + DNS + K8s | DHCP |
| **proxmox-mgm-shared-tags** | Mgm cluster shared NetBox tags | Unit | - |
| **proxmox-vault-vm** | HashiCorp Vault | VM + DNS | Static (192.168.1.33) |
| **proxmox-github-runner-vm** | GitHub Actions runner | VM + DNS | DHCP |
| **proxmox-gitlab-runner-vm** | GitLab CI runner | VM + DNS | DHCP |
| **proxmox-dns-lxc** | Technitium DNS (primary + secondary) | 2× LXC + DNS | Static (192.168.1.153-154) |
| **proxmox-netbox-vm** | NetBox IPAM/DCIM | VM + DNS | Static (192.168.1.88) |
| **proxmox-platform-cluster** | Platform K3s cluster (3× combined CP/Worker) + NetBox K8s | 3× VM + DNS + K8s | DHCP |
| **proxmox-platform-shared-tags** | Platform cluster shared NetBox tags | Unit | - |
| **proxmox-example-vm** | Example VM template | VM + DNS | Static (192.168.1.45) |
| **proxmox-example-lxc** | Example LXC template | LXC + DNS | Static (192.168.1.44) |

### Production Environment

| Stack | Purpose | Type | Network |
|-------|---------|------|---------|
| **proxmox-pool** | Resource pool | Unit | - |
| **proxmox-authentik-vm** | Authentik SSO | VM + DNS | DHCP |
| **proxmox-mgm-cluster** | Management K3s cluster HA (3 CP + 2 Workers) + NetBox K8s | 5× VM + DNS + K8s | DHCP |
| **proxmox-mgm-shared-tags** | Mgm cluster shared NetBox tags | Unit | - |
| **proxmox-vault-vm** | HashiCorp Vault | VM + DNS | Static (192.168.1.34) |
| **proxmox-github-runner-vm** | GitHub Actions runner | VM + DNS | DHCP |
| **proxmox-gitlab-runner-vm** | GitLab CI runner | VM + DNS | DHCP |
| **proxmox-dns-lxc** | Technitium DNS secondary | LXC + DNS | Static (192.168.1.154) |
| **proxmox-netbox-vm** | NetBox IPAM/DCIM | VM + DNS | Static (192.168.1.89) |
| **proxmox-platform-cluster** | Platform K3s cluster (3× combined CP/Worker) + NetBox K8s | 3× VM + DNS + K8s | DHCP |
| **proxmox-platform-shared-tags** | Platform cluster shared NetBox tags | Unit | - |
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
   > **Note**: Use `stack {}` blocks for catalog stacks (VM, LXC, K8s cluster). Use `unit {}` blocks for `proxmox-pool` and shared-tags stacks (e.g., `proxmox-mgm-shared-tags`, `proxmox-platform-shared-tags`).
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

**Proxmox authentication:**
- Ensure `PROXMOX_VE_API_TOKEN` and `PROXMOX_VE_ENDPOINT` are set

**NetBox / DNS authentication:**
- `NETBOX_API_TOKEN_PRODUCTION`, `NETBOX_API_TOKEN_STAGING`, `TECHNITIUM_TSIG_KEY_NAME`, `TECHNITIUM_TSIG_KEY_SECRET` must be set
- These are loaded automatically from Vault via Teller if `VAULT_TOKEN` (or `~/.vault-token`) is available

**Vault / Teller not loading secrets:**
- Check `VAULT_ADDR` is reachable: `https://vault.home.sflab.io:8200`
- Ensure a valid `VAULT_TOKEN` is set or `~/.vault-token` exists
- For AppRole login, set `VAULT_ROLE_ID` and `VAULT_SECRET_ID`

**Dagger cache issues:**
- If apply shows success but VM is missing, check state and use `-old` variant:
  ```bash
  mise run terragrunt:stack:apply-old
  ```

**DHCP IP conflicts:**
- VMs cloned from same template may share `/etc/machine-id`
- Template must have empty `/etc/machine-id` (regenerated on first boot)

## Architecture

### Terragrunt Stacks Pattern

- **Stack**: Collection of related infrastructure units
- **Unit**: Single infrastructure component (VM, LXC, DNS record, K8s cluster)
- **Catalog**: External repository with reusable modules

### Vault & Teller Integration

Secrets are managed via **HashiCorp Vault** and loaded automatically using **Teller** (`.teller.yml`) when entering the directory:

1. `mise.toml` sources `scripts/load-vault-secrets.sh` on directory entry
2. The script resolves a Vault token (`$VAULT_TOKEN` → `~/.vault-token` → AppRole login)
3. Teller reads secrets from Vault and exports them as environment variables:
   - `secrets_homelab/netbox_production.api_token` → `NETBOX_API_TOKEN_PRODUCTION`
   - `secrets_homelab/netbox_staging.api_token` → `NETBOX_API_TOKEN_STAGING`
   - `secrets_homelab/technitium.tsig_key_name` → `TECHNITIUM_TSIG_KEY_NAME`
   - `secrets_homelab/technitium.tsig_key_secret` → `TECHNITIUM_TSIG_KEY_SECRET`

### Dagger Integration

Mise tasks delegate to a **Dagger module** (`.dagger/src/index.ts`) for running Terragrunt operations. Tasks with `-old` suffix bypass Dagger and call Terragrunt directly with `--provider-cache`.

### Shared Resources

- **proxmox-pool**: Environment-wide resource pool (deploy first)
- Application stacks reference pool: `pool_id = "pool-staging"`

### State Management

- Each unit gets dedicated state file in MinIO
- Bucket naming: `{environment}-terragrunt-tfstates`
- State organized by unit path

### Configuration Hierarchy

1. `root.hcl` - Global settings, backend config
2. `provider-proxmox-config.hcl` - Proxmox provider (API token auth via `PROXMOX_VE_API_TOKEN`)
3. `provider-dns-config.hcl` - DNS provider (TSIG key auth)
4. `{environment}/provider-netbox-config.hcl` - NetBox provider (per environment)
5. `{environment}/environment.hcl` - Environment variables + NetBox metadata
6. `{environment}/backend-config.hcl` - Backend settings
7. `{stack}/terragrunt.stack.hcl` - Stack units and values

## Infrastructure Catalog

External module repository: [terragrunt-catalog-homelab](https://github.com/sflab-io/terragrunt-catalog-homelab)

**Available catalog items:**
- `stacks/homelab-proxmox-vm` - Combined VM + DNS + NetBox stack (use `stack {}` block)
- `stacks/homelab-proxmox-lxc` - Combined LXC + DNS + NetBox stack (use `stack {}` block)
- `stacks/homelab-netbox-k8s-cluster` - NetBox Kubernetes cluster registration (use `stack {}` block)
- `units/proxmox-pool` - Proxmox resource pool management (use `unit {}` block)
- `units/netbox-tags` - NetBox tag management (use `unit {}` block)

## Important Notes

- Deploy `proxmox-pool` stack before application stacks
- Use `terragrunt stack run <command>` (not `terragrunt stack <command>`)
- Cache directories (`.terragrunt-stack/`, `.terragrunt-cache/`) are auto-generated
- Provider and backend configs are auto-generated by Terragrunt
- Proxmox endpoint: `https://proxmox.home.sflab.io:8006/`
- DNS server: `192.168.1.13:53`
- NetBox: `http://netbox.home.sflab.io` (both environments)
- `proxmox-netbox-vm` must be deployed with `virtual_machines = []` on first run to avoid circular dependency

## Additional Resources

- **CLAUDE.md** - Detailed documentation for Claude Code
- **[Terragrunt Documentation](https://terragrunt.gruntwork.io/)**
- **[OpenTofu Documentation](https://opentofu.org/docs/)**
- **[Proxmox Documentation](https://pve.proxmox.com/pve-docs/)**
- **[Dagger Documentation](https://docs.dagger.io/)**
