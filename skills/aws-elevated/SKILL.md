---
name: aws-elevated
description: Prepare AWS CLI scripts that source the user's elevated credentials from ~/aws.sh, show them, and have the user run them. Use for any AWS command - describe/get queries, SSM commands to CI hosts, reboots, praktika deploys, update_userdata.py, quota requests, host allocation.
---

# aws-elevated

The user keeps temporary elevated credentials in `~/aws.sh` as `export AWS_...=` lines. A script that sources it holds the credentials for its own process only; the Bash tool's shell does not keep them between calls.

## Rules

1. **Never read, print or copy `~/aws.sh`.** Only source it, inside a script.
2. **The human runs every script.** Write the script to a file, show it with `cat` (a Bash call, so the user sees the exact bytes), then give the command as `! bash <path>`: the user runs it with the `!` prefix, so its output lands in the conversation. Never run it yourself, read-only or not.
3. **Say what it changes.** Before the run command, state whether the script only reads or what it changes (stops, reboots, allocates, deploys, requests quota).
4. **Credentials are checked first.** Every script starts with the template's check, so an expired token fails in one line instead of a traceback halfway through.
5. **Continue from the output.** The `!` output appears in the next turn; read it there and continue. No tee file or background wait is needed.
6. **Fail loudly and trace.** Every script runs with `set -euo pipefail`, and turns on `set -x` right after the credential check, never before sourcing `~/aws.sh`.

## Script template

Write scripts under the current repository's `tmp/` (or `~/tmp/`), not in `/tmp`.

```bash
#!/usr/bin/env bash
set -euo pipefail
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x  # only after sourcing: tracing the source line would print the secrets

# ... the work ...
```

On exit code 2, tell the user to refresh `~/aws.sh` and rerun the same script; do not retry in a loop.

## SSM commands to a host

Poll with a deadline: a command picked up just before a reboot stays `InProgress` until the one-hour execution timeout.

```bash
ssm() {  # ssm REGION INSTANCE 'shell command'
    local c s deadline=$(( $(date +%s) + 120 ))
    c=$(aws ssm send-command --region "$1" --instance-ids "$2" --document-name AWS-RunShellScript --timeout-seconds 60 \
        --parameters "$(jq -cn --arg cmd "$3" '{commands: [$cmd]}')" --query Command.CommandId --output text) || return 1
    while s=$(aws ssm get-command-invocation --region "$1" --command-id "$c" --instance-id "$2" --query Status --output text 2>/dev/null); \
          [ "$s" = Pending ] || [ "$s" = InProgress ] || [ -z "$s" ]; do
        [ "$(date +%s)" -lt "$deadline" ] || { echo "ssm: $c still $s"; return 1; }
        sleep 5
    done
    aws ssm get-command-invocation --region "$1" --command-id "$c" --instance-id "$2" --query '[Status,StandardOutputContent,StandardErrorContent]' --output text
}
```

SSM keeps only the first 2500 characters of output; for more, write to a file on the host and read it back in parts.

A reboot over SSM must be immediate (`shutdown -r now`): a delayed `shutdown -r +N` dies with the SSM command ("can't detach from console"). Detect the new boot by comparing `sysctl -n kern.boottime` with the time the reboot was sent, not by ping status.
