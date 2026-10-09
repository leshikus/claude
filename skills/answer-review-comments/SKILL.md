---
name: answer-review-comments
description: Process review comments on my pull requests, from humans and bots - triage each (won't fix, separate PR, implement), prepare one patch per comment, then walk them with me one at a time and act only on the exact decision words. Use when asked to process, triage, answer, resolve or reply to review comments, or to "do the comments" on a PR.
---

# answer-review-comments

Process review comments in two phases; do not collapse them.

**Phase 1 — planning (no side effects).** Triage every open comment, verifying each against the actual code. Produce a per-comment plan: the comment text and the proposed action, and prepare each fix as a separate patch — one standalone diff per comment, saved under the working directory's `tmp`, not applied. Touch nothing else: no code edits, no commits, no PR/issue/label/body changes, no posted replies. This phase is read-and-prepare only, and it ends with the plan shown to me.

**Phase 2 — human review and action.** Walk the comments with me one at a time, in dialogue. For each, show the comment and its proposed solution (with the prepared patch), then wait for my decision before acting. Only once I agree on that comment do you apply its patch, commit, post the sanctioned reply, or open the follow-up. Do not batch-apply, and do not move to the next comment until the current one is resolved with me.

Decisions in Phase 2 use exact words, and nothing else is a decision. `apply <n>` does the action of item `<n>` — applies and pushes its patch, opens its follow-up PR, or nothing for a P1 — and then posts its reply: an automatic form follows by itself, and a `Won't fix` or other text shown with the item is approved by the same word. `post <n>` posts only the reply shown for item `<n>`. `again <n>` shows item `<n>` once more — comment text, plain explanation, resolution options and the exact action `apply <n>` would take — and writes nothing. Every other word — "continue", "next", "ok", "yes", "approve", "go on" — is discussion: move to the next comment or answer the question, and write nothing. End each item shown with the exact action `apply <n>` would take.

The triage and reply mechanics below apply within these phases — triage in Phase 1, apply/reply in Phase 2.

When responding to a review comment (from a human or a bot), first triage it into one of three options and prefer the earliest that applies, rather than reflexively implementing:
1. **Do not implement (P1)** — the comment rests on a flawed premise, the concern does not actually apply to the code, or the change adds no real value. Verify against the actual code, then reply explaining why and resolve the thread.
2. **Defer to a separate PR (P2)** — the change is valid but out of scope for the current PR, or is better decoupled. Create a separate pull request for it against `master` (never stacked on the current PR's branch), then reply to the review comment linking that follow-up PR.
3. **Implement (P3)** — only when neither P1 nor P2 applies.

Do not fix a review comment in the current pull request if it can be fixed in a separate one. P2 is the default whenever the fix can stand on its own, and the clearest sign of that is a problem that existed before this pull request — a pre-existing bug, a stale runbook, a fail-open path in code the change merely touches. Such a fix does not belong here no matter how small it is: a one-line fix that is unrelated to the change still widens the diff, re-runs CI, and dismisses existing approvals. Reserve P3 for what the pull request itself introduced, or made reachable or consequential.

When a bot comment asks for a test, post the "Standard reply" from the umbrella issue
https://github.com/ClickHouse/ClickHouse/issues/116461 on that thread. The issue is the
source of truth for when a fixture test is appropriate and when a dry-run / e2e test is
wanted instead; read it rather than reconstructing the reply. Before posting it, decide from the issue's "When no test is needed" section whether the change needs a test at all; when it does not, reply with a P1 explanation instead, which needs my approval like any other comment.

Do not implement a suggestion just because a reviewer raised it; a bot's confidence is not evidence.

For the P1 case where the reply refutes a "this is a bug" premise, use the standard form `Won't fix: the expected behaviour is <X>, and the implementation matches it.` — reclassify the report from bug to by-design and confirm the code conforms, in one sentence, rather than defending the mechanism or merely describing the outcome. Unlike the URL templates below, its `<X>` clause is a claim that can be wrong, so it is not autonomous: agree the expected-behaviour clause with me and post only after approval.

When you fix a reviewer's comment, reply to that review comment with exactly three words: `Fixed in <sha_url>`, where `<sha_url>` is the full GitHub URL of the commit that fixes it (e.g. `https://github.com/ClickHouse/ClickHouse/pull/<pr>/commits/<sha>`). The reply body must be nothing but `Fixed in <sha_url>` — no leading/trailing prose, no explanation, no bullet points. Post the reply as a comment on the review thread, not just in the commit message, so the reviewer gets a notification and can follow the link to the exact fix. All explanation goes in the commit message, not the reply: the commit message itself must fully answer the review comment — explain what the reviewer raised and how the change addresses it, so the linked commit stands on its own without the reviewer needing to reconstruct the discussion.

When a comment is addressed by a follow-up pull request (the P2 case) rather than a commit in the current one, reply on that same review thread with the simple message `Will be fixed in <pr_url>`, where `<pr_url>` is the full GitHub URL of the follow-up pull request. The future tense is deliberate: the follow-up has not merged yet. As with `Fixed in <sha_url>`, the reply body must be nothing but that line, and it must be posted on the review thread (including a bot's thread) so the reviewer or bot is notified.

When a comment is addressed by moving the code it concerns into another pull request — rather than fixing it in place — reply with `Moved to <pr_url>`, the full GitHub URL of the pull request the code moved to. Same constraints: the body is nothing but that line, posted on the review thread. Use it in place of `Will be fixed in <pr_url>` whenever the change is relocated to another PR rather than merely promised there.

When a human reviewer questions a change that a bot asked for, reply with `Requested by bot in <comment_url>`, the full GitHub URL of the bot review comment that requested it — point the reviewer to the origin rather than re-arguing it. Review the cited bot comment first to confirm it actually requested the change. Same constraints: the body is nothing but that line, posted on the review thread.

`Fixed in <sha_url>`, `Will be fixed in <pr_url>`, `Moved to <pr_url>`, `Requested by bot in <comment_url>` and the test-delegation reply (the Standard reply from issue 116461) are the only comments you may post to a pull request or review thread autonomously. Any other comment — an explanation, a correction, a discussion reply, a status update, a follow-up note — must be reviewed with me before posting; show me the exact text and wait for approval. Never post it directly. This applies to review-thread replies and issue-level pull request comments alike, and to human and bot threads alike. Do not chain corrections onto GitHub either: if a comment you would have posted turns out wrong, fix it locally and re-review with me rather than posting successive amendments to the thread.

When a reviewer asks for a filter that would silently drop unexpected input, prefer asserting that the input is what we expect — shorter, and it surfaces the operator error instead of hiding it. This is the "avoid fallback paths" rule applied to review feedback: a filter is a fallback.
