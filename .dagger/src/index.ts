/**
 * Dagger module for Terragrunt stack operations in the homelab infrastructure.
 *
 * Provides functions to run Terragrunt stack commands (apply, plan, destroy)
 * against the infrastructure-live repository, with live streaming output.
 */
import { dag, Directory, Socket, object, func } from "@dagger.io/dagger"

@object()
export class TerragruntStacksHomelab {

  @func()
  async generate(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    return dag.terragrunt().stackGenerate(source, stackDir, sshSocket, envVars)
  }

  @func()
  async plan(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    return dag.terragrunt().stackPlan(source, stackDir, sshSocket, envVars)
  }

  @func()
  async apply(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    return dag.terragrunt().stackApply(source, stackDir, sshSocket, envVars)
  }

  @func()
  async output(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    return dag.terragrunt().stackOutput(source, stackDir, sshSocket, envVars)
  }

  @func()
  async destroy(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    return dag.terragrunt().stackDestroy(source, stackDir, sshSocket, envVars)
  }
}
