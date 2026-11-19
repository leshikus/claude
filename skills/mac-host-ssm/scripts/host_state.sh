#!/usr/bin/env bash
# usage: host_state.sh REGION:INSTANCE [REGION:INSTANCE ...]
set -euo pipefail
[ $# -ge 1 ] || { echo "usage: $0 REGION:INSTANCE [REGION:INSTANCE ...]"; exit 64; }
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

for target in "$@"; do
    region=${target%%:*}; instance=${target#*:}
    echo "##### $instance ($region): type, state, image, launch time"
    aws ec2 describe-instances --region "$region" --instance-ids "$instance" \
        --query 'Reservations[].Instances[].[InstanceType,State.Name,ImageId,LaunchTime]' --output text || true
    echo "##### $instance: SSM ping status, last ping, agent version"
    aws ssm describe-instance-information --region "$region" --filters "Key=InstanceIds,Values=$instance" \
        --query 'InstanceInformationList[].[PingStatus,LastPingDateTime,AgentVersion]' --output text || true
done
