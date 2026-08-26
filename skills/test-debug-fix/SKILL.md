---
name: test-debug-fix
description: Reproduce failing tests on a target platform/configuration, fix each reproducible failure in an isolated branch, and submit a validated pull request. Use this skill when the user wants to debug and fix CI test failures, reproduce test failures on a specific platform (e.g. Darwin ARM, Linux ASAN), investigate skipped tests, or systematically triage a list of failing tests. Trigger on phrases like "fix failing tests", "reproduce and fix", "triage test failures", or "fix tests on <platform>".
---

# Test Debug & Fix

Systematically reproduce failing tests, fix each one in isolation, and ship a PR per fix.

## Parameters

When the skill is invoked, identify these from the user's request (ask if missing):

- **platform** — target build/test configuration (e.g. `arm_darwin`, `amd64_linux_asan`)
- **repo_dir** — local checkout of ClickHouse (default: `~/ClickHouse`)
- **skip_file** — file listing tests to attempt (default: `ci/defs/<platform>.skip` in the repo root; may also be `ci/defs/darwin.skip` for macOS platforms)
- **repr_file** — file to record reproducible failures (default: `<platform>.repr` in the repo root)

## Step 1 — Build

Run the build for the target platform from `repo_dir`:

```bash
cd <repo_dir>
python3 -m ci.praktika run "Build (<platform>)"
```

If the build fails, stop and report the error. Do not proceed to test reproduction.

## Step 2 — Reproduce Failures

For each test name listed in `skip_file`:

1. Run the test:
   ```bash
   cd <repo_dir>
   python3 -m ci.praktika run "Fast test (<platform>)" --test <test_name>
   ```
2. If the failure reproduces consistently: append the test name to `repr_file`.
3. If the test passes or is flaky (fails only sometimes): skip it and note it as non-reproducible.

Work through the list sequentially. Report a summary when done: how many tests reproduced vs. were skipped.

## Step 3 — Fix Each Reproducible Test

For each test in `repr_file`, run a fix cycle in a **separate agent** (one agent per test, so fixes stay isolated):

### 3.1 Create a branch

```bash
cd <repo_dir>
git checkout -b fix/<test_name_slug>
```

### 3.2 Investigate and fix

- Read the test source and any related code.
- Identify the root cause of the failure on this platform.
- Implement a minimal, targeted fix — avoid unrelated changes.

### 3.3 Validate

Re-run the test to confirm it passes:

```bash
cd <repo_dir>
python3 -m ci.praktika run "Fast test (<platform>)" --test <test_name>
```

If it still fails, iterate on the fix before proceeding.

### 3.4 Self-review

Before submitting, verify:
- The fix is correct and minimal.
- No unintended side effects on closely related code.
- Code follows project conventions (style, naming).

## Step 4 — Submit PR

For each validated fix:

1. Push the branch.
2. Create a draft PR targeting `ClickHouse/ClickHouse` (follow the fork/upstream rules in CLAUDE.md).
3. PR description must include:
   - **Test name** that was failing
   - **Platform** where it failed
   - **Root cause** — what was wrong
   - **Fix** — what was changed and why
   - **Validation** — command used to confirm the fix

## Notes

- One branch and one PR per test. Never bundle multiple test fixes.
- Skip flaky tests (those that do not reproduce deterministically).
- If a fix attempt fails after 2 iterations, abandon that test and note it in the summary.
- The `~/ClickHouse` directory is the main ClickHouse fork checkout.
