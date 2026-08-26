---
name: add-test
description: Decide whether and how to add a test, so CI/script-like code gets real end-to-end tests instead of mocks. Use BEFORE writing any new test, fixture, or test file - triggers include "add a test", "write a test", "regression test", "test this fix", "cover this with a test", or a reviewer/bot asking for a test.
---

# add-test

Run this decision before creating any test. The goal: never add a mock that only pins current behaviour, and place every test where it runs in CI and would have caught the bug.

## Step 1 — can it be an assert instead of a test?

Prefer an `assert` where the code already runs over a new test that re-creates the setup:
- an invariant → a bare `assert <cond>, "<value that failed>"` at the point it must hold;
- a check that fits an existing **real** test (one that already drives this path with real inputs) → add the assertion there, or a one-line optional parameter to its fixture helper.

If a real assert or a real existing test covers it, do that and stop. Do **not** extend a mock-style test (see Step 2) — that just grows the mock.

## Step 2 — is the code script-like / glue / CI?

Script-like = a sequence of I/O, subprocess and API calls held together by idempotency guards; a report/log parser fed by a tool; a workflow of side effects. For this code:

**Do not write a mock.** The mock smell: the test assembles a fake payload in the shape the code consumes — a fabricated JSON/JSONL record, a canned API response, a stubbed subprocess result — then asserts the code returns it. That test constructs the very input it checks, so it passes by construction and survives any shape-preserving refactor: it catches no real regression. Negative value. If you are writing that fixture, stop.

**Write a real end-to-end test instead:**
1. Run the real tool/subprocess so the input is *produced*, not faked (e.g. run actual `pytest --report-log` rather than hand-writing the jsonl).
2. Feed it through the real code path.
3. Assert the observable outcome. Make the assertion depend on the fix — assert on a marker the fixed path must carry through, **assembled at runtime** so it cannot leak in by another route (e.g. a traceback's echo of source).
4. Place it where CI runs it: for ClickHouse, an integration-suite test under `tests/integration`, not a hand-mocked unit under `ci/tests`.

## Step 3 — the only case for a unit test

A focused unit test is warranted only for a **non-trivial pure algorithm that can regress independently of I/O**: a parser, a version-ordering comparator, a rebase/resync loop, a state machine. Not for glue. Even then, prefer feeding it real captured input over a hand-built fixture.

## Step 4 — prove it (mandatory)

A test that never fails is worthless. Confirm the new test **fails before the fix and passes after**: revert the fix (or disable the changed behaviour), run the test, watch it go red, restore the fix, watch it go green. If it stays green with the fix reverted, it is testing the wrong thing — rewrite it.

## Anti-patterns

- Hand-built `.jsonl`/JSON fixtures fed to a parser to assert the parser returns them.
- Asserting the order of mocked calls (`mock.assert_called_with(...)`) for a workflow — tests the mocks, not behaviour; breaks on harmless reordering.
- A new test file that re-constructs inputs an existing real test already assembles.
- A test committed but not wired into any CI job.
