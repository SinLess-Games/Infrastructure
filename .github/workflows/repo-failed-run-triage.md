---
on:
  workflow_run:
    workflows:
      - CI
      - Code Scanning
      - repo-pr-risk-review
      - daily-repo-announcement
    types: [completed]
    branches:
      - main
  workflow_dispatch:

if: >-
  github.event_name == 'workflow_dispatch' ||
  github.event.workflow_run.conclusion == 'failure' ||
  github.event.workflow_run.conclusion == 'cancelled' ||
  github.event.workflow_run.conclusion == 'timed_out' ||
  github.event.workflow_run.conclusion == 'action_required'

description: "Investigate failed workflow runs and create a structured triage issue"
imports:
  - .github/agents/failed-run-triager.md
engine: copilot
strict: true
run-name: "Failed run triage"
runs-on: [self-hosted, linux, x64]
runs-on-slim: self-hosted
timeout-minutes: 15

concurrency:
  group: repo-failed-run-triage-${{ github.event.workflow_run.id || github.run_id }}
  cancel-in-progress: true

permissions:
  contents: read
  actions: read
  checks: read
  issues: read
  pull-requests: read
  security-events: read

network:
  allowed:
    - defaults

safe-outputs:
  concurrency-group: safe-outputs-failed-run-triage-${{ github.repository }}

  create-issue:
    title-prefix: "[failed-run] "
    max: 1
    group: true

  group-reports: true

---

# Repository Failed Run Triage

Investigate the failed workflow run and create at most one structured issue for maintainers.

## Trigger behavior

If triggered by `workflow_run`:

- analyze the triggering workflow run from `github.event.workflow_run`
- focus on the failed, cancelled, timed out, or action required run that caused this workflow to start

If triggered manually with `workflow_dispatch`:

- analyze the most recent failed or cancelled workflow run in this repository that appears meaningful to triage
- if there is no meaningful failed run to investigate, do not create an issue

## Goals

Produce a high-signal triage report that helps maintainers answer:

- what failed
- where it failed
- how severe it is
- what the most likely cause is
- what should be done next
- whether this looks flaky, environmental, or code-related

## Scope and prioritization

Prioritize failures involving:

- `.github/**`
- `Terraform/**`
- `Ansible/**`
- `Kubernetes/**`
- `Packer/**`
- `PXE/**`
- `scripts/**`
- self-hosted runners
- secret handling
- workflow permissions
- deployment or release logic

Lower priority:

- clearly transient external outages
- cosmetic or docs-only failures with no operational impact
- runs that already succeeded on rerun and appear non-actionable

## Output policy

Create an issue only when the failure is actionable or worth tracking.
If the failure is obviously non-actionable noise, no longer relevant, or already self-healed with strong evidence, do not create an issue.

If you create an issue:

- create exactly one issue
- keep it moderately detailed
- keep it markdownlint-friendly
- avoid speculation beyond what the evidence supports
- do not claim root cause certainty unless evidence is strong

## Required issue structure

The issue title should be short and specific.
Include the failed workflow name or run context in the title when helpful.

The issue body must use these sections in this order:

## Summary

Provide:

- 2 to 4 short bullets
- workflow name
- conclusion
- branch
- commit or SHA if available
- run URL if available

## Failure details

Include this markdown table:

| Field | Value |
| --- | --- |
| Workflow | |
| Run ID | |
| Attempt | |
| Event | |
| Branch | |
| SHA | |
| Conclusion | |
| Triggered by | |

Use `unknown` when a value is not available.

## What failed

Include this markdown table:

| Job or step | Signal | Evidence | Severity |
| --- | --- | --- | --- |

Severity must be one of:

- `high`
- `medium`
- `low`

If exact job or step names are unavailable, use the best concrete scope you can identify.

## Likely cause

Write a short paragraph describing the most likely explanation.
Be explicit about uncertainty.

Then include this markdown table:

| Cause type | Confidence | Why |
| --- | --- | --- |

Cause type should be one of:

- `repository change`
- `workflow configuration`
- `self-hosted runner`
- `dependency or toolchain`
- `external service`
- `flaky or transient`
- `unknown`

Confidence should be one of:

- `high`
- `medium`
- `low`

## Recommended next actions

Provide 3 to 5 short, concrete actions in priority order.

## Maintainer notes

Add one short paragraph covering:

- whether this looks recurring
- whether it is likely blocking
- whether a rerun seems reasonable

## Issue creation rules

Call `create_issue` at most once.

Create an issue when:

- the failure appears actionable
- the failure impacts CI, deployment, infrastructure, or security confidence
- the failure is likely to recur
- the failure needs human follow-up

Do not create an issue when:

- there is no meaningful failure to inspect
- the failure is clearly stale or already superseded
- evidence strongly suggests trivial transient noise with no follow-up value

## Formatting rules

- keep tables valid GitHub markdown tables
- keep list nesting shallow
- keep prose concise and readable
- keep the report moderately detailed
- prefer concrete evidence over broad summaries
- do not invent missing logs, jobs, or steps
- do not claim tests passed unless the evidence shows that
