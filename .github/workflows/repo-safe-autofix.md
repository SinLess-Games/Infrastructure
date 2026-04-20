---
on:
  pull_request:
    types: [labeled]
    names: [safe-autofix]

  reaction: rocket
  status-comment: true

description: "Create safe, docs-only follow-up PRs for low-risk repository fixes"
imports:
  - .github/agents/safe-autofixer.md
engine: copilot
strict: true
run-name: "Repository Safe Autofix"
runs-on: [self-hosted, linux, x64]
runs-on-slim: self-hosted
timeout-minutes: 15

concurrency:
  group: repo-safe-autofix-${{ github.event.pull_request.number || github.run_id }}
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
  report-failure-as-issue: false

  add-comment:
    max: 1
    issues: false
    discussions: false
    pull-requests: true

  remove-labels:
    allowed:
      - safe-autofix
    max: 1

  create-pull-request:
    max: 1
    title-prefix: "[autofix] "
    draft: true
    fallback-as-issue: false
    if-no-changes: ignore
    protected-files: blocked
    allowed-files:
      - Docs/**
      - Readme.md
      - notes.md

---

# Repository Safe Autofix

Review the triggering pull request and determine whether there is a narrow, safe, documentation-only fix that can be proposed automatically.

This workflow is intentionally conservative.

## Goals

- only create a follow-up PR when the fix is low-risk, obvious, and fully supported by repository evidence
- limit all file changes to allowed documentation files
- avoid noisy or speculative autofixes
- leave one concise PR comment explaining what happened
- remove the `safe-autofix` label when done so it can be re-applied later if needed

## Scope

You may propose fixes only in:

- `Docs/**`
- `Readme.md`
- `notes.md`

You must not attempt to modify:

- code
- workflows
- infrastructure configuration
- scripts
- task files
- agent files
- secrets or environment files

## Good autofix candidates

Good candidates include:

- markdownlint-style formatting corrections
- heading structure cleanup
- broken or stale docs links that can be corrected from repository evidence
- obvious command or path updates that directly match the current PR changes
- small documentation clarifications that reduce operator confusion
- table formatting cleanup
- code fence language annotation fixes when clearly appropriate
- typo fixes only when the intent is obvious

## Do not autofix

Do not create a PR for:

- speculative rewrites
- large documentation refactors
- behavior changes not directly supported by evidence
- anything requiring edits outside the allowed files
- changes that depend on hidden context or unclear intent
- style-only churn with little practical value
- changes to security-sensitive, build, dependency, or workflow files

## Decision rules

If there is no safe and useful autofix:

- do not create a PR
- add one short PR comment explaining why no autofix was proposed
- remove the `safe-autofix` label

If there is a safe and useful autofix:

- create exactly one draft PR
- keep the patch small and focused
- add one short PR comment summarizing what was proposed
- remove the `safe-autofix` label

## Required PR comment structure

When you comment, use this structure:

## Safe autofix result

Write 1 short paragraph stating one of:

- a draft autofix PR was created
- no safe autofix was proposed

## Reason

Include this markdown table:

| Field | Value |
| --- | --- |
| Outcome | |
| Scope | |
| Evidence | |
| Risk | |

Use concise values.

## Next step

Provide 1 to 3 short bullets.

## PR creation rules

If you create a PR:

- keep it draft
- keep it narrowly scoped
- keep it documentation-only
- explain exactly what was fixed and why
- avoid unrelated cleanup

## Comment rules

- add exactly one PR comment
- keep it concise
- keep it markdownlint-friendly
- do not overstate confidence
- do not claim validation passed unless visible evidence supports it
- do not make compliance, audit, or certification claims