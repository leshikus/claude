#!/usr/bin/env bash
# usage: ssm_run.sh REGION INSTANCE SNIPPET_FILE [DEADLINE_SECONDS]
set -euo pipefail
[ $# -ge 3 ] || { echo "usage: $0 REGION INSTANCE SNIPPET_FILE [DEADLINE_SECONDS]"; exit 64; }
region=$1; instance=$2; snippet=$3; deadline_s=${4:-120}
[ -r "$snippet" ] || { echo "snippet is missing: $snippet"; exit 64; }
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

command_id=$(aws ssm send-command --region "$region" --instance-ids "$instance" --document-name AWS-RunShellScript \
    --timeout-seconds "$deadline_s" --parameters "$(jq -cn --rawfile cmd "$snippet" '{commands: [$cmd]}')" \
    --query Command.CommandId --output text)

end=$(( $(date +%s) + deadline_s ))
while status=$(aws ssm get-command-invocation --region "$region" --command-id "$command_id" --instance-id "$instance" \
        --query Status --output text 2>/dev/null); [ "$status" = Pending ] || [ "$status" = InProgress ] || [ -z "$status" ]; do
    [ "$(date +%s)" -lt "$end" ] || { echo "ssm: $command_id is still ${status:-unknown} after ${deadline_s}s"; exit 1; }
    sleep 5
done

aws ssm get-command-invocation --region "$region" --command-id "$command_id" --instance-id "$instance" --output json \
    | jq -r '"status: \(.Status)", "--- stdout", .StandardOutputContent, "--- stderr", .StandardErrorContent'
[ "$status" = Success ]
