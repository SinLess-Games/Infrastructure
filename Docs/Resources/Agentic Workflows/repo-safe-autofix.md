# Repo Safe Autofix

## What this workflow does

`repo-safe-autofix` is a conservative follow-up workflow that proposes **small, low-risk documentation fixes** as a draft pull request.

It is intentionally narrow in scope.
It does not try to rewrite code, change infrastructure, or silently edit important repository settings.
Instead, it looks for documentation problems that are obvious, safe, and directly supported by repository evidence, then opens a **draft** pull request for human review when the fix is worth making.

In the current design, the workflow is limited to documentation-style files such as:

- `Docs/**`
- `Readme.md`
- `notes.md`

That restriction matters because gh-aw’s `create-pull-request` safe output supports an explicit `allowed-files` allowlist, and protected-file enforcement is on by default for pull-request-writing outputs. That means the workflow can be tightly contained to docs-only changes instead of drifting into broader automation or code mutation. :contentReference[oaicite:0]{index=0}

## Why this workflow exists

Many repositories have small documentation problems that are not serious enough to justify a dedicated manual fix, but are still worth correcting.

Examples include:

- outdated file paths
- stale commands
- markdown formatting issues
- broken documentation links
- obvious heading structure problems
- wording that became inaccurate after a related repository change

Individually, these issues are small.
Collectively, they create confusion, reduce trust in the docs, and make the repository harder to use.

This workflow exists to handle that kind of low-risk maintenance safely.

## Primary purpose

The main purpose of `repo-safe-autofix` is to reduce small documentation debt without creating hidden or risky automation.

It helps by:

- identifying documentation-only fixes that are clearly justified
- keeping those fixes tightly scoped
- opening them as **draft** pull requests instead of silently applying them
- avoiding broad or speculative edits
- giving maintainers a controlled way to say, “This looks like a safe candidate for automation”

## Why it is label-driven

This workflow is designed to run when a pull request is explicitly marked for safe autofix, rather than running automatically on every PR.

That is important because it keeps the workflow opt-in and maintainable.
Instead of assuming every pull request should receive an automated patch, the team can use it only when there is a good reason to believe a small, safe, documentation-only fix is possible.

That makes the workflow easier to trust and reduces noise.

## Why it only creates draft pull requests

This workflow is intentionally designed to create **draft** pull requests rather than normal ready-to-merge PRs.

That matters because even a low-risk documentation change should still be reviewed by a human before merging.
A draft PR makes the proposed change visible without implying that the workflow should have the final word.

It also keeps the workflow aligned with gh-aw’s security model, where the agent analyzes and proposes changes, and the actual write operation is handled by a controlled safe output instead of broad write access inside the agent itself. :contentReference[oaicite:1]{index=1}

## What kinds of fixes it should make

This workflow is best for narrow, obvious changes such as:

- markdownlint-style formatting cleanup
- heading hierarchy fixes
- documentation path updates that clearly match the repository
- obvious command updates supported by changed files
- small documentation clarifications that reduce confusion
- broken local docs links
- simple typo fixes with clear intent
- table cleanup in docs

These are good autofix targets because they are:

- low blast radius
- easy to review
- easy to explain
- unlikely to change repository behavior
- valuable enough to reduce maintenance friction

## What it should not do

This workflow should not act like a broad autonomous editor.

It should not:

- modify code
- change workflows
- edit infrastructure definitions
- touch task automation
- alter security-sensitive files
- rewrite large parts of the docs without strong evidence
- propose speculative improvements that are not directly tied to visible repository evidence

The point of the workflow is not to “fix everything.”
The point is to make a very small class of safe fixes easy to propose.

## Why safe outputs are important here

This workflow is a strong example of why gh-aw safe outputs matter.

gh-aw safe outputs allow a workflow to create GitHub resources such as pull requests without giving the agentic part of the workflow broad write permissions. The `create-pull-request` safe output is specifically meant for this kind of controlled code- or doc-writing flow. It also supports restrictions like `allowed-files`, and protected file protection is enforced by default for PR-writing outputs. :contentReference[oaicite:2]{index=2}

That means `repo-safe-autofix` can be useful without being overly powerful.

## Why this is useful in this repository

This repository includes infrastructure, automation, workflows, provisioning, documentation, and operational tooling.

In a repo like this, even small documentation drift matters because it affects how humans interact with the system.
At the same time, it would be inappropriate to let an automated workflow casually modify infrastructure or workflow logic.

`repo-safe-autofix` exists to operate in the space between those two realities:

- useful enough to reduce doc maintenance overhead
- constrained enough to avoid risky automation

## What this workflow is not

`repo-safe-autofix` is not:

- an autonomous code repair system
- a workflow that should update repository logic
- a replacement for full docs review
- a substitute for human editorial judgment on broad changes
- a permission to let automation change anything it thinks looks outdated

It is a tightly scoped docs-only proposal workflow.

## Summary

`repo-safe-autofix` exists to safely propose small documentation improvements as draft pull requests.

Its purpose is to reduce low-risk documentation debt while keeping strict boundaries around what the workflow is allowed to change. It is useful because it helps maintainers clean up obvious, reviewable docs problems without turning repository automation into a broad write-capable system.
