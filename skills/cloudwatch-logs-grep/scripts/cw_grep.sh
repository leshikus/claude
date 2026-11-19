#!/usr/bin/env bash
# usage: cw_grep.sh LOG_GROUP FILTER_PATTERN MINUTES REGION [REGION ...]
set -euo pipefail
[ $# -ge 4 ] || { echo "usage: $0 LOG_GROUP FILTER_PATTERN MINUTES REGION [REGION ...]"; exit 64; }
group=$1; pattern=$2; minutes=$3; shift 3
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

start=$(( ($(date +%s) - minutes * 60) * 1000 ))
for region in "$@"; do
    echo "##### $region"
    aws logs filter-log-events --region "$region" --log-group-name "$group" --start-time "$start" \
        --filter-pattern "$pattern" --max-items 50 --query 'events[].[logStreamName,timestamp,message]' --output json \
        | jq -r '.[] | "\(.[0]) \(.[1] / 1000 | todate) \(.[2])"' | cut -c1-240 || true
done
