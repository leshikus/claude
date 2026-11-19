---
name: mac-host-ssm
description: Run a shell snippet on one EC2 Mac CI host through SSM and print its status, stdout and stderr. Use for any check or change on a Mac runner host - disks, processes, logs, files, reboots. The snippet is a file; the script takes the region and the instance as parameters. Prepare it through the aws-elevated rules - the user runs it.
---

# mac-host-ssm

`scripts/ssm_run.sh REGION INSTANCE SNIPPET_FILE [DEADLINE_SECONDS]` runs the shell commands in `SNIPPET_FILE` on the instance as root through `AWS-RunShellScript`. It prints the status, the standard output and the standard error. The exit code is 0 only when the status is `Success`.

Write the commands of a check as a snippet file, not as a new AWS script. The script holds all AWS code: the credential check, the polling with a deadline and the output.

## Rules

1. Follow the `aws-elevated` rules: show the script and the snippet with `cat`, say whether the snippet only reads or changes something, and give the command as `! bash <path>`. Never run it yourself.
2. The region and the instance have no default value. Give them as arguments. Run several hosts with a shell loop in the command line.
3. SSM keeps the first 2500 characters of the output. Keep the snippet output short with `head` and `cut`, or write a file on the host and read it in parts.
4. A reboot in the snippet must be immediate (`shutdown -r now`). A delayed `shutdown -r +N` ends together with the SSM command.
5. The default deadline is 120 seconds. Pass a larger value as the fourth argument for a long snippet.

## Example

```bash
for h in "<region-1> <instance-1>" "<region-2> <instance-2>"; do
    bash ~/.claude/skills/mac-host-ssm/scripts/ssm_run.sh $h tmp/probe.sh
done
```
