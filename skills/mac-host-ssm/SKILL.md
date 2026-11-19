---
name: mac-host-ssm
description: Run a shell snippet on one EC2 Mac CI host through SSM and print its status, stdout and stderr. Use for any check or change on a Mac runner host - disks, processes, logs, files, reboots. The snippet is a file; the script takes the region and the instance as parameters. Prepare it through the aws-elevated rules - the user runs it.
---

# mac-host-ssm

`scripts/ssm_run.sh SNIPPET_FILE REGION:INSTANCE [REGION:INSTANCE ...]` runs the shell commands in `SNIPPET_FILE` as root on each instance, one after the other, through `AWS-RunShellScript`. It prints the status, the standard output and the standard error of each host. The exit code is 0 only when every status is `Success`.

Write the commands of a check as a snippet file, not as a new AWS script. The script holds all AWS code: the credential check, the polling with a deadline and the output.

`scripts/host_state.sh REGION:INSTANCE [REGION:INSTANCE ...]` only reads. It prints the EC2 type, state, image and launch time, and the SSM ping status of each host. Run it first when `ssm_run.sh` reports `Pending`: the agent of a host that is rebooting or stopped does not pick up the command.

## Rules

1. Follow the `aws-elevated` rules: show the script and the snippet with `cat`, say whether the snippet only reads or changes something, and give the command as `! bash <path>`. Never run it yourself.
2. The region and the instance have no default value. Give them as arguments, one `REGION:INSTANCE` per host. No shell loop is needed, so the command is the same in zsh and bash.
3. SSM keeps the first 2500 characters of the output. Keep the snippet output short with `head` and `cut`, or write a file on the host and read it in parts.
4. A reboot in the snippet must be immediate (`shutdown -r now`). A delayed `shutdown -r +N` ends together with the SSM command.
5. The default deadline is 120 seconds per host. Set `SSM_DEADLINE=<seconds>` in the environment for a long snippet.

## Example

```bash
bash ~/.claude/skills/mac-host-ssm/scripts/ssm_run.sh tmp/probe.sh <region-1>:<instance-1> <region-2>:<instance-2>
```
