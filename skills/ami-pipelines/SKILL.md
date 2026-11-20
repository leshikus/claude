---
name: ami-pipelines
description: List the EC2 Image Builder pipelines with a name prefix, their recipe and newest images, and optionally start one AMI build per pipeline. Use to rebuild the CI runner AMIs after a change to the image script, or to check the newest AMI builds. Prepare it through the aws-elevated rules - the user runs it.
---

# ami-pipelines

`scripts/ami_pipelines.sh REGION NAME_PREFIX [start]`

- Without `start` it only reads: pipeline name, recipe ARN (the recipe version is in it), last run, and the three newest images with their status.
- With `start` it also starts one build per pipeline and prints each build ARN. A build takes about 25 minutes. When it succeeds, the distribution configuration sets the new AMI as the default version of every listed launch template.

Run it through the `aws-elevated` rules: show it with `cat`, give the user `! bash <path> ...`, never run it yourself. Check first, without `start`, that the recipe version matches the version in the repository.
