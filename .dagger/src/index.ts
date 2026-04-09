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
    const command = "stack run generate"

    return dag.terragrunt().run(source, stackDir, sshSocket, command, { envVars })
  }

  @func()
  async plan(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const command = "stack run plan"

    return dag.terragrunt().run(source, stackDir, sshSocket, command, { envVars })
  }

  @func()
  async apply(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const command = "stack run apply --non-interactive"
    return dag.terragrunt().run(source, stackDir, sshSocket, command, { envVars })
  }

  @func()
  async output(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const command = "stack run output"

    return dag.terragrunt().run(source, stackDir, sshSocket, command, { envVars })
  }

  @func()
  async destroy(
    source: Directory,
    stackDir: string,
    sshSocket: Socket,
    envVars: string[],
  ): Promise<string> {
    const command = "stack run destroy --non-interactive"

    return dag.terragrunt().run(source, stackDir, sshSocket, command, { envVars })
  }
}
