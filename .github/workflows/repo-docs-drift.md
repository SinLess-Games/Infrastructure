---
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:

description: "Detect documentation drift and propose safe docs-only fixes"
imports:
  - .github/agents/docs-drift-reviewer.md
engine: copilot
strict: true
run-name: "Repository Docs Drift Review"
runs-on: [self-hosted, linux, x64]
runs-on-slim: self-hosted
timeout-minutes: 15

concurrency:
  group: repo-docs-drift-${{ github.event.pull_request.number || github.run_id }}
  cancel-in-progress: true

permissions:
  contents: read
  pull-requests: read
  issues: read
  actions: read
  checks: read

network:
  allowed:
    - defaults

safe-outputs:
  add-comment:
    max: 1
    issues: false
    discussions: false
    pull-requests: true

  create-pull-request:
    max: 1
    title-prefix: "[docs] "
    labels: [documentation]
    reviewers: [copilot]
    fallback-as-issue: false
    allowed-files:
      - Docs/**
      - Readme.md
      - notes.md

---

# Repository Docs Drift Review

Review the triggering pull request for documentation drift.

Your job is to compare the code, automation, configuration, and operational changes in the PR against the current repository documentation and operator guidance.

## Goals

- identify meaningful documentation drift
- avoid noisy comments when nothing important is missing
- create a docs-only follow-up PR only when the fix is narrow, straightforward, and safely limited to documentation files
- keep output concise, practical, and markdownlint-friendly

## Repository context

Pay special attention to drift involving:

- `.github/**`
- `Ansible/**`
- `Docs/**`
- `Kubernetes/**`
- `Packer/**`
- `PXE/**`
- `scripts/**`
- `Terraform/**`
- `Readme.md`
- `notes.md`
- `taskfile.yaml`
- `.taskfiles/**`

High-value drift examples:

- setup steps changed but docs still show the old flow
- workflow names, paths, commands, or required files changed
- directory names or capitalization changed but docs still reference the old paths
- validation, deployment, bootstrap, or recovery steps changed without docs updates
- security-sensitive behavior changed without operator notes
- new workflows, labels, commands, or automation expectations exist but are undocumented

Low-value findings to avoid:

- cosmetic wording preferences
- style-only suggestions with no operational impact
- obvious future-docs ideas not required by the PR
- repeating information already clearly documented elsewhere in the repository

## Decision rules

If there is no meaningful docs drift:

- do not create a PR
- do not add a comment unless a very short positive signal is genuinely useful

If there is meaningful docs drift but the fix is broad, uncertain, or would require touching non-doc files:

- add one concise PR comment
- do not create a docs PR

If there is meaningful docs drift and the fix is narrow and safe:

- add one concise PR comment summarizing the drift
- create at most one docs-only PR
- limit changes to:
  - `Docs/**`
  - `Readme.md`
  - `notes.md`

## Required review structure

When you comment, use this structure:

## Docs drift summary

Write 1 short paragraph summarizing whether drift exists and why it matters.

## Findings

Include this markdown table:

| Severity | Area | Drift | Evidence | Recommended fix |
| --- | --- | --- | --- | --- |

Severity must be one of:

- `high`
- `medium`
- `low`
- `good signal`

If there is no material drift but you still comment, include one `good signal` row.

## Suggested next step

Provide 1 to 3 short bullets.

## Docs PR creation rules

Create a docs-only PR only when all of these are true:

- the needed fix is clear from repository evidence
- the scope is small and documentation-only
- the changes fit entirely within the allowed documentation files
- the proposed update will materially reduce confusion or operator error

If you create a PR:

- keep it small
- keep it focused on the drift caused by the triggering PR
- do not mix unrelated cleanup
- write a clear title and body
- explain what changed and why

## Comment rules

Add at most one PR comment.
Comment only when it adds value.
Do not restate the entire PR.

## Formatting rules

- keep prose concise
- keep headings shallow
- keep tables valid GitHub markdown tables
- escape literal pipe characters as `\|`
- keep the response moderately detailed
- do not invent undocumented behavior
- do not claim validation passed unless visible evidence supports that
- do not make compliance, audit, or certification claims
