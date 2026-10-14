---
name: aws-deploy
description: Merge a ClickHouse/clickhouse-private PR that changes CI infrastructure (tests/ci/terraform) and monitor the AWSDeployPush run on master that applies it; triage a failed "AWS deploy apply". Trigger on "monitor aws deploy", "watch the deploy", "merge when ready and monitor deploy", or an AWSDeployPush failure on master.
---

# AWS deploy

A push to `master` of `ClickHouse/clickhouse-private` starts the `AWSDeployPush` workflow. Its `AWS deploy apply` job runs `tofu apply` in `tests/ci/terraform`. PR CI runs no `tofu plan`, so only this run proves a terraform change.

## Watch

Run the watcher as a `Monitor` with `timeout_ms` 1800000; re-arm it on expiry:

```bash
~/.claude/skills/aws-deploy/scripts/watch_deploy.sh <pr> [--merge]
```

- **`--merge`** merges the PR (merge commit) once it is not a draft and every check is green or skipped. It stops on a red check and does not merge.
- **Superseded runs.** The workflow cancels a queued run when a newer push arrives. The run for the merge commit is often `cancelled` with no jobs. The watcher follows any later run whose head contains the merge commit (`compare` status `ahead` or `identical`).
- **Exit.** `DONE: deploy conclusion=<c>` on the first such run that completes without being cancelled.

Report every run URL and the `AWS deploy apply` job URL.

## Triage a failure

```bash
gh run view <id> --repo ClickHouse/clickhouse-private --log-failed | grep -A4 -E 'Error|Exception'
```

1. Compare the failing commit with the merge commit. Failures on commits from before the merge are not caused by the PR. Say which commit each failure belongs to.
2. Every later deploy fails at the same step until a fix merges. Offer a revert or a fix PR.

Known failure:

| Error | Cause | Fix |
|---|---|---|
| `ServiceQuotaExceededException ... Launch Templates Modified per Distribution Configuration` on `aws_imagebuilder_distribution_configuration.ci_runner` | The image builder distribution in `ami_builder.tf` lists more than 20 launch templates | Let the new ASG share an existing launch template with the same disk and image; the ASG sets its own `instance_types` and `github:runner-type` tag. Example: #81268 |

## After success

Changes that depend on the new infrastructure wait for this run, for example a public `ClickHouse/ClickHouse` workflow switch to a new runner label. Tell the user that the dependent change can now merge; do not merge it yourself.
