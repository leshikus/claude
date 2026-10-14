#!/bin/bash
# Usage: watch_deploy.sh <pr> [--merge]
# Prints one line per event; exits 0 on a finished deploy that contains the PR, 1 on a failure.
set -u
R=ClickHouse/clickhouse-private; P=$1; MERGE=${2:-}
while true; do
    s=$(gh pr view "$P" --repo $R --json state,isDraft,statusCheckRollup 2>/dev/null) || { sleep 60; continue; }
    [ "$(jq -r .state <<<"$s")" = MERGED ] && break
    [ "$(jq -r .state <<<"$s")" = CLOSED ] && { echo "PR closed without merge"; exit 1; }
    if [ "$MERGE" != --merge ]; then sleep 60; continue; fi
    bad=$(jq -r '[.statusCheckRollup[]|select((.conclusion//.state) as $c|["FAILURE","ERROR","CANCELLED","TIMED_OUT","ACTION_REQUIRED"]|index($c))|(.name//.context)]|join(", ")' <<<"$s")
    [ -n "$bad" ] && { echo "CI FAILED, not merging: $bad"; exit 1; }
    pend=$(jq '[.statusCheckRollup[]|(.conclusion//.state//"")|select(.=="" or .=="PENDING" or .=="IN_PROGRESS" or .=="QUEUED" or .=="EXPECTED")]|length' <<<"$s")
    if [ "$pend" = 0 ] && [ "$(jq -r .isDraft <<<"$s")" = false ]; then
        out=$(gh pr merge "$P" --repo $R --merge 2>&1) || { echo "MERGE FAILED: $out"; exit 1; }
        echo "merged https://github.com/$R/pull/$P"; break
    fi
    sleep 60
done
sha=$(gh pr view "$P" --repo $R --json mergeCommit --jq .mergeCommit.oid)
echo "merge commit ${sha:0:10}"
seen=""
while true; do
    # A newer push cancels a pending deploy, so any later run whose head contains the merge commit counts.
    rows=$(gh run list --repo $R --workflow AWSDeployPush --limit 15 --json databaseId,status,conclusion,headSha \
        --jq '.[]|"\(.databaseId)|\(.status)|\(.conclusion)|\(.headSha)"' 2>/dev/null) || { sleep 60; continue; }
    while IFS='|' read -r id st co h; do
        [ -z "$id" ] && continue
        c=$(gh api "repos/$R/compare/$sha...$h" --jq .status 2>/dev/null)
        [ "$c" = ahead ] || [ "$c" = identical ] || continue
        key="$id|$st|$co"; grep -qxF "$key" <<<"$seen" && continue
        seen="$seen"$'\n'"$key"
        echo "https://github.com/$R/actions/runs/$id ${h:0:10} $st $co"
        if [ "$st" = completed ] && [ "$co" != cancelled ]; then
            echo "DONE: deploy conclusion=$co"; [ "$co" = success ]; exit $?
        fi
    done <<<"$rows"
    sleep 60
done
