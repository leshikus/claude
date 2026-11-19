#!/usr/bin/env bash
# usage: ssm_diagnose.sh REGION:INSTANCE [REGION:INSTANCE ...]
set -euo pipefail
[ $# -ge 1 ] || { echo "usage: $0 REGION:INSTANCE [REGION:INSTANCE ...]"; exit 64; }
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

for target in "$@"; do
    region=${target%%:*}; instance=${target#*:}
    echo "##### $instance ($region)"
    echo "-- EC2: type, state, subnet, vpc, profile, imds tokens, hop limit, security groups"
    aws ec2 describe-instances --region "$region" --instance-ids "$instance" \
        --query 'Reservations[].Instances[].[InstanceType,State.Name,SubnetId,VpcId,IamInstanceProfile.Arn,MetadataOptions.HttpTokens,MetadataOptions.HttpPutResponseHopLimit,SecurityGroups[].GroupId|join(`,`,@)]' --output text || true
    echo "-- SSM registration: ping, last ping, agent, latest, association, last association run, ip"
    aws ssm describe-instance-information --region "$region" --filters "Key=InstanceIds,Values=$instance" \
        --query 'InstanceInformationList[].[PingStatus,LastPingDateTime,AgentVersion,IsLatestVersion,AssociationStatus,LastAssociationExecutionDate,IPAddress]' --output text || true
    echo "-- SSM recent commands: requested, status, details"
    aws ssm list-command-invocations --region "$region" --instance-id "$instance" --max-results 6 \
        --query 'CommandInvocations[].[RequestedDateTime,Status,StatusDetails]' --output text || true
    vpc=$(aws ec2 describe-instances --region "$region" --instance-ids "$instance" --query 'Reservations[].Instances[].VpcId' --output text || true)
    profile=$(aws ec2 describe-instances --region "$region" --instance-ids "$instance" --query 'Reservations[].Instances[].IamInstanceProfile.Arn' --output text || true)
    echo "-- IAM: may the instance role use the SSM channels"
    role=$(aws iam get-instance-profile --instance-profile-name "${profile##*/}" --query 'InstanceProfile.Roles[0].Arn' --output text || true)
    aws iam simulate-principal-policy --policy-source-arn "$role" \
        --action-names ssm:UpdateInstanceInformation ec2messages:GetMessages ssmmessages:CreateDataChannel \
        --query 'EvaluationResults[].[EvalActionName,EvalDecision]' --output text || true
    echo "-- VPC endpoints of $vpc (empty: traffic uses the internet path)"
    aws ec2 describe-vpc-endpoints --region "$region" --filters "Name=vpc-id,Values=$vpc" \
        --query 'VpcEndpoints[].[ServiceName,State]' --output text || true
done
