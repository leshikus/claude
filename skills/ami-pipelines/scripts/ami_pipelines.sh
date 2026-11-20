#!/usr/bin/env bash
# Usage: ami_pipelines.sh REGION NAME_PREFIX [start]
# Lists Image Builder pipelines whose name starts with NAME_PREFIX, with recipe and newest image; `start` starts one build per pipeline.
set -euo pipefail
REGION=$1; PREFIX=$2; ACTION=${3:-}
[ -r ~/aws.sh ] || { echo "~/aws.sh is missing"; exit 2; }
set -a; . ~/aws.sh; set +a
aws sts get-caller-identity --query Account --output text >/dev/null 2>&1 \
    || { echo "AWS credentials in ~/aws.sh are expired or invalid - refresh ~/aws.sh"; exit 2; }
set -x

arns=$(aws imagebuilder list-image-pipelines --region "$REGION" \
    --query "imagePipelineList[?starts_with(name, '$PREFIX')].arn" --output text)
[ -n "$arns" ] || { echo "no pipeline starts with [$PREFIX]"; exit 1; }
for arn in $arns; do
    aws imagebuilder get-image-pipeline --region "$REGION" --image-pipeline-arn "$arn" \
        --query 'imagePipeline.[name,imageRecipeArn,dateLastRun]' --output text
    aws imagebuilder list-image-pipeline-images --region "$REGION" --image-pipeline-arn "$arn" \
        --query 'reverse(sort_by(imageSummaryList,&dateCreated))[:3].[version,state.status,dateCreated]' --output text
    if [ "$ACTION" = start ]; then
        aws imagebuilder start-image-pipeline-execution --region "$REGION" --image-pipeline-arn "$arn" \
            --query imageBuildVersionArn --output text
    fi
done
