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
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   * @param envVars - Environment variables as KEY=VALUE strings (e.g. "AWS_ACCESS_KEY_ID=abc")
   */
  @func()
  async stackApply(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, sshSocket, envVars)
      .withExec(["sh", "-c", "terragrunt stack run apply --non-interactive 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack run plan' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   * @param envVars - Environment variables as KEY=VALUE strings (e.g. "AWS_ACCESS_KEY_ID=abc")
   */
  @func()
  async stackPlan(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, sshSocket, envVars)
      .withExec(["sh", "-c", "terragrunt stack run plan 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack run destroy --non-interactive' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   * @param envVars - Environment variables as KEY=VALUE strings (e.g. "AWS_ACCESS_KEY_ID=abc")
   */
  @func()
  async stackDestroy(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, sshSocket, envVars)
      .withExec(["sh", "-c", "terragrunt stack run destroy --non-interactive 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack generate' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   * @param envVars - Environment variables as KEY=VALUE strings (e.g. "AWS_ACCESS_KEY_ID=abc")
   */
  @func()
  async stackGenerate(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, sshSocket, envVars)
      .withExec(["sh", "-c", "terragrunt stack generate 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  /**
   * Runs 'terragrunt stack output' in the given stack directory.
   *
   * @param source - The repository root directory to mount into the container
   * @param stackDir - Relative path to the stack directory (e.g. "staging/proxmox-k3s-vms")
   * @param sshSocket - SSH agent socket for git authentication (e.g. unix:///run/user/1000/ssh-agent.socket)
   * @param envVars - Environment variables as KEY=VALUE strings (e.g. "AWS_ACCESS_KEY_ID=abc")
   */
  @func()
  async stackOutput(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const ctr = this.terragruntContainer(source, stackDir, sshSocket, envVars)
      .withExec(["sh", "-c", "terragrunt stack output 2>&1"], { expect: ReturnType.Any })
    return (await ctr.stdout()) + (await ctr.stderr())
  }

  private terragruntContainer(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Container {
    let ctr = dag
      .container()
      .from("devopsinfra/docker-terragrunt:ot-1.11.5-tg-0.99.5")
      .withMountedDirectory("/repo", source)
      .withWorkdir(`/repo/${stackDir}`)
      .withEnvVariable("SSH_AUTH_SOCK", "/ssh-agent.sock")
      .withEnvVariable("GIT_SSH_COMMAND", "ssh -o StrictHostKeyChecking=no")
      .withEnvVariable("TF_IN_AUTOMATION", "1")
      .withEnvVariable("CHECKPOINT_DISABLE", "1")
      .withUnixSocket("/ssh-agent.sock", sshSocket)

    for (const envVar of envVars) {
      const idx = envVar.indexOf("=")
      if (idx === -1) continue
      const name = envVar.substring(0, idx)
      const value = envVar.substring(idx + 1)
      ctr = ctr.withEnvVariable(name, value)
    }

    return ctr
  }
}
