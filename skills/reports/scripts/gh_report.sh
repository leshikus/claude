#!/usr/bin/env bash
# Data collection for the morning / daily / weekly reports. See ../SKILL.md.
#
#   gh_report.sh window <daily|weekly>
#   gh_report.sh morning
#   gh_report.sh daily
#   gh_report.sh weekly
#
# Every mode writes TSV to stdout, one section per `# SECTION` header line.
set -euo pipefail

LOGIN=${REPORT_LOGIN:-leshikus}
ORG=${REPORT_ORG:-ClickHouse}

# 13:00 Munich on the day the given `date -v` adjustments land on, as a UTC ISO timestamp.
munich_13() {
    local stamp
    stamp=$(TZ=Europe/Berlin date "$@" -v13H -v0M -v0S +%Y-%m-%dT%H:%M:%S%z)
    TZ=UTC date -jf %Y-%m-%dT%H:%M:%S%z "$stamp" +%Y-%m-%dT%H:%M:%SZ
}

window() {
    case "$1" in
    daily)
        if [ "$(date +%u)" = 1 ]; then START=$(munich_13 -v-3d); else START=$(munich_13 -v-1d); fi
        END=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)
        ;;
    weekly)
        START=$(munich_13 -v-mon -v-7d)
        END=$(munich_13 -v-mon)
        ;;
    *) echo "no window for [$1]" >&2; exit 1 ;;
    esac
}

PR_FIELDS='
  number url title isDraft mergeable updatedAt createdAt mergedAt state
  author { login }
  repository { nameWithOwner }
  reviews(last: 30) { nodes { state submittedAt author { login } } }
  reviewThreads(last: 50) { nodes { isResolved comments(last: 20) { nodes { createdAt author { login } } } } }
  comments(last: 20) { nodes { createdAt author { login } body } }
  commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
'

ISSUE_FIELDS='
  number url title state updatedAt
  author { login }
  repository { nameWithOwner }
  assignees(first: 10) { nodes { login } }
  comments(last: 1) { nodes { createdAt author { login } } }
'

# search_pr <github-search-query>
search_pr() {
    gh api graphql -f q="$1" \
        -f query="query(\$q: String!) { search(query: \$q, type: ISSUE, first: 100) { nodes { ... on PullRequest { $PR_FIELDS } } } }"
}

search_issue() {
    gh api graphql -f q="$1" \
        -f query="query(\$q: String!) { search(query: \$q, type: ISSUE, first: 100) { nodes { ... on Issue { $ISSUE_FIELDS } } } }"
}

# Who spoke last on a PR node. Bots never count as somebody else — they cannot be waiting for an answer.
# $other is ambient traffic from anyone; only $reply_threads and $mention_replies mean the login is asked.
JQ_ACTIVITY='
  def bot: test("\\[bot\\]$|^robot-|^clickhouse-gh$|^CLAassistant$");
  def acts: [.comments.nodes[], .reviewThreads.nodes[].comments.nodes[], .reviews.nodes[] | {createdAt: (.createdAt // .submittedAt), login: .author.login}];
  (.author.login) as $pr_author |
  (acts | map(select(.login == $login) | .createdAt) | max // "") as $mine |
  (acts | map(select(.login != $login and ((.login | bot) | not))) | max_by(.createdAt) // {}) as $other |
  ([ .reviewThreads.nodes[]
     | select(any(.comments.nodes[]; .author.login == $login))
     | (.comments.nodes | last)
     | select(.author.login != $login and ((.author.login | bot) | not)) ] | length) as $reply_threads |
  ([ .comments.nodes[]
     | select(.author.login != $login and ((.author.login | bot) | not))
     | select(.body | test("@" + $login)) ] | length) as $mention_replies
'

pr_header() {
    printf '# %s\turl\trepo\ttitle\tauthor\tstate\tdraft\tmergeable\tchecks\tapprovals\tchanges_requested\thuman_reviews\tunresolved\treply_threads\tmentions\tlast_own_comment\tlast_other_comment\tlast_other_login\tmerged\tupdated\n' "$1"
}

pr_row() {
    jq -r --arg login "$LOGIN" "
      .data.search.nodes[] | select(.url) | $JQ_ACTIVITY |
      [ .url, .repository.nameWithOwner, .title, .author.login, .state,
        (if .isDraft then \"draft\" else \"ready\" end),
        .mergeable,
        (.commits.nodes[0].commit.statusCheckRollup.state // \"NONE\"),
        ([.reviews.nodes[] | select(.state == \"APPROVED\") | .author.login] | unique | join(\",\")),
        ([.reviews.nodes[] | select(.state == \"CHANGES_REQUESTED\") | .author.login] | unique | join(\",\")),
        ([.reviews.nodes[] | select(.state != \"PENDING\") | .author.login | select(. != \$login and . != \$pr_author and ((. | bot) | not))] | unique | join(\",\")),
        ([.reviewThreads.nodes[] | select(.isResolved | not) | select((.comments.nodes[0].author.login | bot) | not)] | length | tostring),
        (\$reply_threads | tostring), (\$mention_replies | tostring),
        \$mine, (\$other.createdAt // \"\"), (\$other.login // \"\"),
        (.mergedAt // \"\"),
        .updatedAt
      ] | @tsv"
}

issue_header() {
    printf '# %s\turl\trepo\ttitle\tauthor\tassignees\tlast_comment_by\tupdated\n' "$1"
}

issue_row() {
    jq -r '
      .data.search.nodes[] | select(.url) |
      [ .url, .repository.nameWithOwner, .title, .author.login,
        ([.assignees.nodes[].login] | join(",")),
        (.comments.nodes[0].author.login // ""),
        .updatedAt
      ] | @tsv'
}

morning() {
    pr_header OWN
    search_pr "is:pr is:open author:$LOGIN org:$ORG" | pr_row

    pr_header REVIEW_REQUESTED
    search_pr "is:pr is:open review-requested:$LOGIN" | pr_row

    pr_header ENGAGED
    search_pr "is:pr is:open commenter:$LOGIN -author:$LOGIN org:$ORG" | pr_row

    issue_header ISSUES
    search_issue "is:issue is:open involves:$LOGIN org:$ORG" | issue_row
}

daily() {
    window daily
    printf '# WINDOW\t%s\t%s\n' "$START" "$END"
    pr_header OWN
    search_pr "is:pr author:$LOGIN org:$ORG updated:>=${START%T*}" | pr_row
    pr_header REVIEWED
    search_pr "is:pr -author:$LOGIN org:$ORG commenter:$LOGIN updated:>=${START%T*}" | pr_row
    search_pr "is:pr -author:$LOGIN org:$ORG reviewed-by:$LOGIN updated:>=${START%T*}" | pr_row
    issue_header ISSUES
    search_issue "is:issue involves:$LOGIN org:$ORG updated:>=${START%T*}" | issue_row
}

weekly() {
    window weekly
    printf '# WINDOW\t%s\t%s\n' "$START" "$END"
    pr_header OWN
    search_pr "is:pr author:$LOGIN org:$ORG updated:>=${START%T*}" | pr_row
    pr_header REVIEWED
    search_pr "is:pr -author:$LOGIN org:$ORG commenter:$LOGIN updated:${START%T*}..${END%T*}" | pr_row
    search_pr "is:pr -author:$LOGIN org:$ORG reviewed-by:$LOGIN updated:${START%T*}..${END%T*}" | pr_row
}

case "${1:-}" in
window) window "${2:?window kind required}"; echo "START=$START END=$END" ;;
morning) morning ;;
daily) daily ;;
weekly) weekly ;;
*) sed -n '2,9p' "$0" >&2; exit 1 ;;
esac
