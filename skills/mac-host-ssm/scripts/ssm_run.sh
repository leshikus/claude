#!/usr/bin/env bash
# usage: ssm_run.sh SNIPPET_FILE REGION:INSTANCE [REGION:INSTANCE ...]   (SSM_DEADLINE seconds per host, default 120)
set -euo pipefail
[ $# -ge 2 ] || { echo "usage: $0 SNIPPET_FILE REGION:INSTANCE [REGION:INSTANCE ...]"; exit 64; }
snippet=$1; shift
deadline_s=${SSM_DEADLINE:-120}
[ -r "$snippet" ] || { echo "snippet is missing: $snippet"; exit 64; }
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

failed=0
for target in "$@"; do
    region=${target%%:*}; instance=${target#*:}
    echo "##### $instance ($region)"
    command_id=$(aws ssm send-command --region "$region" --instance-ids "$instance" --document-name AWS-RunShellScript \
        --timeout-seconds "$deadline_s" --parameters "$(jq -cn --rawfile cmd "$snippet" '{commands: [$cmd]}')" \
        --query Command.CommandId --output text) || { failed=1; continue; }
    end=$(( $(date +%s) + deadline_s ))
    while status=$(aws ssm get-command-invocation --region "$region" --command-id "$command_id" --instance-id "$instance" \
            --query Status --output text 2>/dev/null); [ "$status" = Pending ] || [ "$status" = InProgress ] || [ -z "$status" ]; do
        [ "$(date +%s)" -lt "$end" ] || { echo "ssm: $command_id is still ${status:-unknown} after ${deadline_s}s"; break; }
        sleep 5
    done
    aws ssm get-command-invocation --region "$region" --command-id "$command_id" --instance-id "$instance" --output json \
        | jq -r '"status: \(.Status)", "--- stdout", .StandardOutputContent, "--- stderr", .StandardErrorContent'
    [ "$status" = Success ] || failed=1
done
exit $failed
