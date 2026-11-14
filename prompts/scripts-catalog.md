# Scripts catalog

One line per script: path, what it does, whether it reads or changes something, skill. The rules are in `generic.md`, section "Scripts". This repository is public: do not write secret values, account or instance IDs, or SSM parameter paths here.

Skill: none for every script below. A skill is created only when a script must be written a second time.

## Release recovery, 2026-11

- `~/tmp/robot-token-check.sh` — reads the release robot token from SSM and prints its GitHub user, repository permissions and branch protection. Reads only.
- `~/tmp/force-push-release.sh` — force-pushes `rebased/<branch>` to the public release branch with the robot token and a lease. Changes the public repository.
- `~/tmp/backport-131375.sh` — cherry-picks the merged PR 131375 onto older release branches with the robot token and opens the PRs. Without `--apply` it prints the plan; with it, it changes.
- `~/tmp/release-after-ci.sh` — waits for the `Build` and `Sign macOS` jobs of `ReleaseBranchCI` for a SHA, then dispatches `CreateRelease` for it. Changes the public repository. Similar to `enable-after-26.9.sh`.
- `~/tmp/enable-after-26.9.sh` — waits for a `CreateRelease` run and for the merge of a PR, then enables `AutoReleases` and `WeeklyOfficialDocker`. Changes workflow states. Similar to `release-after-ci.sh`.
- `/tmp/rb.sh` — rebases a public release branch onto its internal branch and resolves the known conflicts. Local only.
- `/tmp/keep_both.py` — keeps both sides of every conflict hunk in a file. Local only.

## Release artifacts and reports in S3

- `~/tmp/check_builds_retention.sh` — prints lifecycle, versioning, object lock, replication and tags of the `clickhouse-builds` bucket. Reads only.
- `~/tmp/praktika_public_logs.sh` — prints the public-access settings and policy of the `clickhouse-builds` and `clickhouse-test-reports` buckets. Reads only.
- `~/tmp/find_release_buckets.sh` — searches the builds bucket for the artifacts of the releases in its list (branch and SHA). Reads only.
- `~/tmp/list_release_artifacts.sh` — lists the packages under `REFs/<branch>/<sha>/` for the releases in its list. Reads only.
- `~/tmp/recheck_destinations.sh` — lists `<branch>/<arch>/` in the builds bucket for the release branches. Reads only.
- `~/tmp/verify_release_copy.sh` — checks the copy of release artifacts under `release/` in the builds bucket. Reads only.
- `~/tmp/copy_release_artifacts.sh` — copies release artifacts in S3 for the listed branches and SHAs. Dry run unless `APPLY=1`; with it, it changes.
- `~/tmp/list_reports.sh` — lists the `result_*` objects of the listed SHAs in `clickhouse-test-reports` into `~/tmp/s3_results.tsv`. Reads AWS only, writes a local file.
- `~/tmp/delete_reports.sh` — deletes the report objects listed in `~/tmp/s3_results.tsv`. Only with `--delete` it changes.
- `~/tmp/verify_release.sh` — checks one release of the internal repository: the run, the tag object, the commit and the previous public tag. Usage: `<branch> <tag> <commit> <run_id> <prev_public_tag>`. Reads only.

## AMI and Image Builder

- `~/tmp/ami-chain.sh` — lists the `ubuntu_ci_image_*` Image Builder pipelines and their recent builds. Reads only.
- `~/tmp/ami-failure.sh` — prints the SSM command result and the Image Builder log of one failed AMI build. Reads only.
- `~/tmp/ami-instance-logs.sh` — shows the newest runner instances with their AMI and the newest cloud-init log streams. Reads only.
- `~/tmp/old-ami-instances.sh` — finds runner instances that run an AMI older than the newest `ubuntu_ci_image_*`. Reads only.
- `~/tmp/start-ami-pipelines.sh` — lists the AMI pipelines. With the argument `start` it starts one build per pipeline and changes.
- `~/tmp/imagebuilder-quota.sh` — lists the Image Builder launch-template quotas. With a value as argument it requests an increase and changes.

## Runner fleet, autoscaling and quotas

- `~/tmp/autoscale_lambda.sh` — shows the trigger rules and the logs of the autoscale lambda for several runner types. Reads only.
- `~/tmp/check_autoscale_lambda.sh` — shows the last change of the autoscale lambda and the recent errors, throttling and timeouts in its log. Reads only.
- `~/tmp/cancel_lambda_logs.sh` — reads the last 24 hours of the log of the job-cancel lambda. Reads only.
- `~/tmp/webhook_vs_runners.sh` — compares the workflow-job webhook events with the runners of the last 3 hours. Reads only.
- `~/tmp/runner-failures.sh` — lists runner instances with failure phrases in the cloud-init log of the last N minutes (default 10). Reads only.
- `~/tmp/runner-health.sh` — counts runner instances by health phrase in the cloud-init log of the last N minutes (default 30). Reads only.
- `~/tmp/runner_boot_loop.sh` — counts boots per instance in the last hour with CloudWatch Insights; more than one means a reboot. Reads only.
- `~/tmp/runner_dispatch.sh` — summarises job dispatch to runners in the last 3 hours, Mac instances included. Reads only.
- `~/tmp/runner_type_outcome.sh` — outcome per runner type in the last hour; writes its results to `~/tmp/outcome`. Reads AWS only.
- `~/tmp/runner_types.sh` — instance counts per runner type in the last hour. Reads only.
- `~/tmp/failure-cause.sh` — shows the cloud-init log around a runner failure to find the cause. Reads only.
- `~/tmp/first-failure.sh` — finds the first matches of failure phrases in the cloud-init log from a fixed start time. Reads only.
- `~/tmp/recovery_series.sh` — time series of runner recovery in the last 2 hours. Reads only.
- `~/tmp/vcpu_quota.sh` — shows the EC2 vCPU quotas and the usage of the autoscaling groups. Reads only.
- `~/tmp/cw-config-get.sh` — saves the CloudWatch agent config from SSM to `~/tmp/cw-config.json` and prints it. Reads AWS only, writes a local file.

## CI orchestration and statistics (profile `CICDAdmin`)

- `~/tmp/ci_diag.sh` — lists the CI lambdas and the depth of the SQS queues. Reads only.
- `~/tmp/ci_orch_logs.sh` — reads the controller log group for "check update for" warnings of the last 3 days. Reads only.
- `~/tmp/ci_orch_logs2.sh` — counts events per hour and shows the recycle exception text in the controller log. Reads only.
- `~/tmp/ci_sql.sh` — shows the on-demand vCPU in use and queries the CI statistics database through a connection from SSM. Reads only.

## Mac hosts: read-only checks

- `~/tmp/check_m4_macs.sh` — lists dedicated Mac M4 hosts in all regions. Reads only.
- `~/tmp/macos-queue.sh` — lists Mac instances in three US regions. Reads only.
- `~/tmp/macos-sydney.sh` — lists Mac instances and hosts in `ap-southeast-2`. Reads only.
- `~/tmp/macos-logs.sh` — lists the cloud-init log streams of two Mac instances. Reads only.
- `~/tmp/macos-fail.sh` — saves the first "Error while running module [ExecuteUserData]" event of a host to `~/tmp/macos-fail.txt`. Reads AWS only.
- `~/tmp/macos-fail2.sh` — saves the cloud-init log of a host from a fixed time to `~/tmp/macos-fail2.txt`. Reads AWS only.
- `~/tmp/macos-recheck.sh` — rechecks the cloud-init log of a host for failure phrases of the last 30 minutes. Reads only.
- `~/tmp/macos-version.sh` — compares the `runner-init.py` version in S3 with the version a host logs. Reads only.
- `~/tmp/macos-test-hosts.sh` — shows the SSM state and recent logs of the two Mac test hosts. Reads only.
- `~/tmp/macos-use1-logs.sh` — saves the cloud-init logs of four `us-east-1` Mac hosts to `~/tmp`. Reads AWS only.
- `~/tmp/macos-reboots.sh` — looks up reboot, stop, start, terminate and send-command events of the last 6 hours in CloudTrail. Reads only.
- `~/tmp/macos-deploy-a.sh` — prints the remote `runner-init.py` version, downloads the macOS init script from S3 to `~/tmp/macos-v80.py` and finds the region of a host. Reads AWS only.
- `~/tmp/macos-deploy-a2.sh` — checks the state and the SSM registration of a host in four regions. Reads only.
- `~/tmp/reboots.sh` — runs `last reboot` on all running `mac2-m2pro` hosts through SSM and prints the output. Reads only.
- `~/tmp/macos-boot.sh` — shows the last reboots of a host through SSM. Reads only.
- `~/tmp/macos-hostlogs.sh` — shows uptime, the last reboots and the runner processes of a host through SSM. Reads only.
- `~/tmp/macos-check.sh` — runs diagnostic commands on one Mac host through SSM (time, boot time). Reads only.
- `~/tmp/macos-confirm.sh` — checks GitHub API rate limit, the latest runner release and the Python venv on a host through SSM. Reads only.
- `~/tmp/macos-initlog.sh` — shows the init log of Mac hosts through SSM. Reads only.
- `~/tmp/macos-module.sh` — shows the AMI and the `init.toml` module of a stable host through SSM. Reads only.
- `~/tmp/macos-runners.sh` — shows uptime and runner processes of Mac hosts through SSM. Reads only.
- `~/tmp/macos-state.sh` — shows the state of a looping and a stable Mac host through SSM. Reads only.
- `~/tmp/macos-fleet.sh` — shows uptime, runner listener and worker counts of the Mac fleet through SSM. Reads only.
- `~/tmp/macos-use1.sh` — shows boot history, runner-init processes and the init log of four `us-east-1` Mac hosts through SSM. Reads only.
- `~/tmp/macos-use1-python.sh` — shows the Python kegs, links and owners on the `us-east-1` Mac hosts through SSM. Reads only.
- `~/tmp/macos-cw-check.sh` — checks the CloudWatch agent of a Mac host and its log stream. Reads only.
- `~/tmp/macos-cw-diag.sh` — diagnoses the CloudWatch agent of a Mac host through SSM. Reads only.
- `~/tmp/macos-cw-diag2.sh` — second round of the CloudWatch agent diagnostics on a Mac host. Reads only.
- `~/tmp/macos-wrm-check.sh` — shows the state of the wireless-radio-mitigation daemon and its log on a host through SSM. Reads only.

## Mac hosts: scripts that change a host

- `~/tmp/macos-cw-marker.sh` — appends a marker line to the host init log to check that it reaches CloudWatch. Changes a host file.
- `~/tmp/macos-chown-cellar.sh` — changes the owner of the Homebrew `Cellar` files to `ec2-user` on the listed hosts. Changes hosts.
- `~/tmp/macos-fix-brew.sh` — removes a Python keg and runs `brew cleanup` on the hosts in `ap-southeast-2`, retrying for 15 minutes. Changes hosts.
- `~/tmp/macos-fix-brew-use1.sh` — the same for four `us-east-1` hosts. Changes hosts.
- `~/tmp/macos-deploy-b.sh` — deploys a new `runner-init.py` to a host and reboots it. Changes a host.
- `~/tmp/macos-deploy-c.sh` — second version of `macos-deploy-b.sh`: deploy `runner-init.py` and reboot. Changes a host.
- `~/tmp/macos-reboot-one.sh` — reboots one Mac host through SSM and waits for it. Changes a host.
- `~/tmp/macos-reboot-all.sh` — reboots the Mac hosts of a region except the busy ones. Changes hosts.
- `~/tmp/macos-reboot-test.sh` — reboots three test hosts, removes a test file and compares the state before and after. Changes hosts.
- `~/tmp/macos-wrm-deploy.sh` — installs the wireless-radio-mitigation package on a host (or on all with `--all`), checking its SHA. Changes hosts.

## GitHub and pull requests

- `~/tmp/robot5_pr_ready.sh` — marks the official-images PR 22587 ready for review with the robot-5 token. Changes the PR.
- `~/tmp/robot5_to_clipboard.sh` — copies the robot-5 token from SSM to the clipboard. Reads a secret and puts it on the clipboard; written on request, against the secret rule in `generic.md`.
- `~/tmp/watch_pr22587.sh` — waits for PR 22587 of official-images to merge or close, then plays a sound for up to an hour. Reads only.

## Python copies, not for running

- `~/tmp/prbj.py` — copy of the private `CreateReleaseBranch` job.
- `~/tmp/ri.py`, `~/tmp/runner-init.py`, `~/tmp/macos-v80.py` — local copies of versions of `runner-init.py`.
