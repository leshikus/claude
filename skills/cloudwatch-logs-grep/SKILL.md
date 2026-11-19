---
name: cloudwatch-logs-grep
description: Search one CloudWatch log group for a filter pattern in the last N minutes, in one or more regions, and print stream, time and message of the matches. Use to check whether a log line reached CloudWatch, for example after a deploy to CI hosts. Read-only. Prepare it through the aws-elevated rules - the user runs it.
---

# cloudwatch-logs-grep

`scripts/cw_grep.sh LOG_GROUP FILTER_PATTERN MINUTES REGION [REGION ...]` runs `filter-log-events` on the log group in each region and prints at most 50 matches per region as `stream time message`. It only reads.

## Rules

1. Follow the `aws-elevated` rules: show the script with `cat`, say that it only reads, and give the command as `! bash <path>`. Never run it yourself.
2. The log group, the pattern, the window and the regions have no default value. Give them as arguments.
3. Quote a phrase pattern so that it has double quotes inside single quotes: `'"Local SSD"'`.
4. A stream is often named after the instance ID, so the stream column identifies the host.

## Example

```bash
bash ~/.claude/skills/cloudwatch-logs-grep/scripts/cw_grep.sh <log-group> '"<phrase>"' 240 <region-1> <region-2>
```
