#!/usr/bin/env bash
# usage: ssm_history.sh START END REGION:INSTANCE [REGION:INSTANCE ...]   (START and END are ISO UTC times, e.g. 2026-11-11T20:00:00Z)
set -euo pipefail
[ $# -ge 3 ] || { echo "usage: $0 START END REGION:INSTANCE [REGION:INSTANCE ...]"; exit 64; }
start=$1; end=$2; shift 2
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

for target in "$@"; do
    region=${target%%:*}; instance=${target#*:}
    echo "##### $instance ($region): State Manager associations"
    aws ssm describe-instance-associations-status --region "$region" --instance-id "$instance" \
        --query 'InstanceAssociationStatusInfos[].[Name,Status,DetailedStatus,ExecutionDate,ErrorCode]' --output text || true
done

for region in $(printf '%s\n' "$@" | cut -d: -f1 | sort -u) us-east-1; do
    echo "##### $region: write events from $start to $end, by source and name (count)"
    aws cloudtrail lookup-events --region "$region" --start-time "$start" --end-time "$end" \
        --lookup-attributes AttributeKey=ReadOnly,AttributeValue=false --max-items 600 \
        --query 'Events[].[EventSource,EventName]' --output text | sort | uniq -c | sort -rn | head -n 30 || true
done
