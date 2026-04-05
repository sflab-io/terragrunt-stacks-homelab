/**
 * Dagger module for Terragrunt stack operations in the homelab infrastructure.
 *
 * Provides functions to run Terragrunt stack commands (apply, plan, destroy)
 * against the infrastructure-live repository, with live streaming output.
 */
import { dag, Container, Directory, Secret, Socket, ReturnType, object, func } from "@dagger.io/dagger"

@object()
export class TerragruntStacksHomelab {
  /**
   * Runs 'terragrunt stack run apply -- --auto-approve' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param awsAccessKeyId - AWS_ACCESS_KEY_ID for MinIO state backend
   * @param awsSecretAccessKey - AWS_SECRET_ACCESS_KEY for MinIO state backend
   * @param proxmoxVeEndpoint - Proxmox VE API endpoint (e.g. https://proxmox.home.sflab.io:8006)
   * @param proxmoxVeApiToken - Proxmox VE API token (PROXMOX_VE_API_TOKEN)
   * @param netboxToken - NetBox API token (NETBOX_API_TOKEN / TF_VAR_netbox_token)
   * @param dnsKeySecret - DNS TSIG key secret (TF_VAR_dns_key_secret)
   * @param proxmoxContainerPassword - Password for LXC containers (PROXMOX_CONTAINER_PASSWORD)
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   */
  @func()
  async stackApply(
    source: Directory,
    stackDir: string,
    awsAccessKeyId: string,
    awsSecretAccessKey: Secret,
    proxmoxVeEndpoint: string,
    proxmoxVeApiToken: Secret,
    netboxToken: Secret,
    dnsKeySecret: Secret,
    proxmoxContainerPassword: Secret,
    sshSocket: Socket,
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, awsAccessKeyId, awsSecretAccessKey, proxmoxVeEndpoint, proxmoxVeApiToken, netboxToken, dnsKeySecret, proxmoxContainerPassword, sshSocket)
      .withExec(["sh", "-c", "terragrunt stack run apply --non-interactive 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack run plan' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param awsAccessKeyId - AWS_ACCESS_KEY_ID for MinIO state backend
   * @param awsSecretAccessKey - AWS_SECRET_ACCESS_KEY for MinIO state backend
   * @param proxmoxVeEndpoint - Proxmox VE API endpoint (e.g. https://proxmox.home.sflab.io:8006)
   * @param proxmoxVeApiToken - Proxmox VE API token (PROXMOX_VE_API_TOKEN)
   * @param netboxToken - NetBox API token (NETBOX_API_TOKEN / TF_VAR_netbox_token)
   * @param dnsKeySecret - DNS TSIG key secret (TF_VAR_dns_key_secret)
   * @param proxmoxContainerPassword - Password for LXC containers (PROXMOX_CONTAINER_PASSWORD)
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   */
  @func()
  async stackPlan(
    source: Directory,
    stackDir: string,
    awsAccessKeyId: string,
    awsSecretAccessKey: Secret,
    proxmoxVeEndpoint: string,
    proxmoxVeApiToken: Secret,
    netboxToken: Secret,
    dnsKeySecret: Secret,
    proxmoxContainerPassword: Secret,
    sshSocket: Socket,
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, awsAccessKeyId, awsSecretAccessKey, proxmoxVeEndpoint, proxmoxVeApiToken, netboxToken, dnsKeySecret, proxmoxContainerPassword, sshSocket)
      .withExec(["sh", "-c", "terragrunt stack run plan 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack run destroy --non-interactive' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param awsAccessKeyId - AWS_ACCESS_KEY_ID for MinIO state backend
   * @param awsSecretAccessKey - AWS_SECRET_ACCESS_KEY for MinIO state backend
   * @param proxmoxVeEndpoint - Proxmox VE API endpoint (e.g. https://proxmox.home.sflab.io:8006)
   * @param proxmoxVeApiToken - Proxmox VE API token (PROXMOX_VE_API_TOKEN)
   * @param netboxToken - NetBox API token (NETBOX_API_TOKEN / TF_VAR_netbox_token)
   * @param dnsKeySecret - DNS TSIG key secret (TF_VAR_dns_key_secret)
   * @param proxmoxContainerPassword - Password for LXC containers (PROXMOX_CONTAINER_PASSWORD)
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   */
  @func()
  async stackDestroy(
    source: Directory,
    stackDir: string,
    awsAccessKeyId: string,
    awsSecretAccessKey: Secret,
    proxmoxVeEndpoint: string,
    proxmoxVeApiToken: Secret,
    netboxToken: Secret,
    dnsKeySecret: Secret,
    proxmoxContainerPassword: Secret,
    sshSocket: Socket,
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, awsAccessKeyId, awsSecretAccessKey, proxmoxVeEndpoint, proxmoxVeApiToken, netboxToken, dnsKeySecret, proxmoxContainerPassword, sshSocket)
      .withExec(["sh", "-c", "terragrunt stack run destroy --non-interactive 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack generate' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param awsAccessKeyId - AWS_ACCESS_KEY_ID for MinIO state backend
   * @param awsSecretAccessKey - AWS_SECRET_ACCESS_KEY for MinIO state backend
   * @param proxmoxVeEndpoint - Proxmox VE API endpoint (e.g. https://proxmox.home.sflab.io:8006)
   * @param proxmoxVeApiToken - Proxmox VE API token (PROXMOX_VE_API_TOKEN)
   * @param netboxToken - NetBox API token (NETBOX_API_TOKEN / TF_VAR_netbox_token)
   * @param dnsKeySecret - DNS TSIG key secret (TF_VAR_dns_key_secret)
   * @param proxmoxContainerPassword - Password for LXC containers (PROXMOX_CONTAINER_PASSWORD)
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   */
  @func()
  async stackGenerate(
    source: Directory,
    stackDir: string,
    awsAccessKeyId: string,
    awsSecretAccessKey: Secret,
    proxmoxVeEndpoint: string,
    proxmoxVeApiToken: Secret,
    netboxToken: Secret,
    dnsKeySecret: Secret,
    proxmoxContainerPassword: Secret,
    sshSocket: Socket,
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, awsAccessKeyId, awsSecretAccessKey, proxmoxVeEndpoint, proxmoxVeApiToken, netboxToken, dnsKeySecret, proxmoxContainerPassword, sshSocket)
      .withExec(["sh", "-c", "terragrunt stack generate 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack output' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param awsAccessKeyId - AWS_ACCESS_KEY_ID for MinIO state backend
   * @param awsSecretAccessKey - AWS_SECRET_ACCESS_KEY for MinIO state backend
   * @param proxmoxVeEndpoint - Proxmox VE API endpoint (e.g. https://proxmox.home.sflab.io:8006)
   * @param proxmoxVeApiToken - Proxmox VE API token (PROXMOX_VE_API_TOKEN)
   * @param netboxToken - NetBox API token (NETBOX_API_TOKEN / TF_VAR_netbox_token)
   * @param dnsKeySecret - DNS TSIG key secret (TF_VAR_dns_key_secret)
   * @param proxmoxContainerPassword - Password for LXC containers (PROXMOX_CONTAINER_PASSWORD)
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   */
  @func()
  async stackOutput(
    source: Directory,
    stackDir: string,
    awsAccessKeyId: string,
    awsSecretAccessKey: Secret,
    proxmoxVeEndpoint: string,
    proxmoxVeApiToken: Secret,
    netboxToken: Secret,
    dnsKeySecret: Secret,
    proxmoxContainerPassword: Secret,
    sshSocket: Socket,
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, awsAccessKeyId, awsSecretAccessKey, proxmoxVeEndpoint, proxmoxVeApiToken, netboxToken, dnsKeySecret, proxmoxContainerPassword, sshSocket)
      .withExec(["sh", "-c", "terragrunt stack output 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  private terragruntContainer(
    source: Directory,
    stackDir: string,
    awsAccessKeyId: string,
    awsSecretAccessKey: Secret,
    proxmoxVeEndpoint: string,
    proxmoxVeApiToken: Secret,
    netboxToken: Secret,
    dnsKeySecret: Secret,
    proxmoxContainerPassword: Secret,
    sshSocket: Socket,
  ): Container {
    return dag
      .container()
      .from("devopsinfra/docker-terragrunt:ot-1.11.5-tg-0.99.5")
      .withMountedDirectory("/repo", source)
      .withWorkdir(`/repo/${stackDir}`)
      .withEnvVariable("AWS_ACCESS_KEY_ID", awsAccessKeyId)
      .withSecretVariable("AWS_SECRET_ACCESS_KEY", awsSecretAccessKey)
      .withEnvVariable("SSH_AUTH_SOCK", "/ssh-agent.sock")
      .withEnvVariable("GIT_SSH_COMMAND", "ssh -o StrictHostKeyChecking=no")
      .withEnvVariable("TF_IN_AUTOMATION", "1")
      .withEnvVariable("CHECKPOINT_DISABLE", "1")
      .withEnvVariable("PROXMOX_VE_ENDPOINT", proxmoxVeEndpoint)
      .withEnvVariable("PROXMOX_VE_INSECURE", "true")
      .withSecretVariable("PROXMOX_VE_API_TOKEN", proxmoxVeApiToken)
      .withSecretVariable("NETBOX_API_TOKEN", netboxToken)
      .withSecretVariable("TF_VAR_netbox_token", netboxToken)
      .withSecretVariable("TF_VAR_dns_key_secret", dnsKeySecret)
      .withSecretVariable("PROXMOX_CONTAINER_PASSWORD", proxmoxContainerPassword)
      .withUnixSocket("/ssh-agent.sock", sshSocket)
  }
}
