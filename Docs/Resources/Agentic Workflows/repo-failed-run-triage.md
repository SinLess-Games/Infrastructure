# Repo Failed Run Triage

## What this workflow does

`repo-failed-run-triage` watches for failed GitHub Actions runs and turns those failures into a structured, actionable triage report.

Its job is to inspect failed workflow executions, determine what likely went wrong, estimate how serious the failure is, and decide whether the failure is worth tracking as a repository issue.

Instead of leaving a failure buried in Actions history, this workflow is meant to surface it in a way maintainers can actually work from.

A typical triage report is designed to answer questions like:

- which workflow failed
- which job or step appears to have failed
- whether the failure looks like a repository problem, a workflow problem, a runner problem, or a transient external issue
- how urgent the failure is
- what the next actions should be

If the failure looks meaningful and actionable, the workflow creates a structured issue so the team has a durable record of the problem and a place to track follow-up.

## Why this workflow exists

Failed workflow runs are easy to miss, especially in repositories with a lot of automation.

A run can fail for many different reasons:

- a bad repository change
- an invalid workflow update
- a missing dependency or toolchain problem
- a self-hosted runner issue
- a secret or permission problem
- a network or external service outage
- a flaky, hard-to-reproduce transient failure

Without a dedicated triage flow, maintainers often have to open the Actions UI, inspect logs manually, guess at severity, and decide on their own whether the failure matters enough to track.

This workflow exists to reduce that manual effort.

It turns workflow failure noise into a more useful signal.

## Primary purpose

The main purpose of `repo-failed-run-triage` is to improve **operational awareness** and **failure follow-up discipline**.

It helps by:

- detecting meaningful failed runs
- classifying the likely cause
- separating actionable failures from harmless noise
- opening a structured issue when human follow-up is needed
- reducing the chance that important CI or automation failures are forgotten

## What it looks at

This workflow is intended to inspect failed workflow runs, especially failures related to important operational parts of the repository.

That includes failures involving areas such as:

- `.github/`
- `Terraform/`
- `Ansible/`
- `Kubernetes/`
- `Packer/`
- `PXE/`
- `scripts/`
- self-hosted runners
- workflow permissions
- secrets handling
- deployment or release behavior

It is especially valuable when the failure touches infrastructure, automation, or anything that could reduce trust in the repository’s CI/CD and operational tooling.

## What kinds of failures it helps distinguish

One of the most useful things this workflow does is separate **types of failure**.

It is meant to help identify whether a failure most likely came from:

- a repository change
- a workflow configuration problem
- a self-hosted runner problem
- a dependency or toolchain problem
- an external service
- a flaky or transient condition
- an unknown cause when the evidence is weak

That distinction matters because not every failure should be treated the same way.

A broken workflow step caused by a bad repository change needs a different response than a one-off network timeout on a self-hosted runner.

## Why it creates issues instead of only commenting

A failed run is often more than a momentary inconvenience.
Sometimes it represents:

- broken CI
- blocked merges
- deployment risk
- loss of trust in automation
- recurring operational instability

When that happens, the problem should not live only in the Actions tab.
It should have a durable place where maintainers can track investigation and resolution.

That is why this workflow creates issues for failures that look actionable or important.

The issue becomes the repository’s follow-up record for the failure.

## Why it does not create an issue for every failure

Not every failed run deserves a tracking issue.

Some failures are clearly noise, stale context, or one-off transient problems that resolved themselves on rerun.
Creating issues for all of them would turn triage into spam.

This workflow exists partly to prevent that.

It is supposed to be selective and conservative.
If the evidence suggests the failure is not meaningful enough to track, the workflow should avoid creating unnecessary noise.

## Why structured failure details matter

The triage report is designed to be structured because failed-run investigation is much easier when the key facts are easy to scan.

A useful report includes things like:

- workflow name
- run ID
- branch
- SHA
- conclusion
- job or step scope
- likely cause type
- confidence level
- recommended next actions

That structure helps maintainers quickly understand whether the failure is:

- blocking
- recurring
- severe
- likely to happen again
- worth rerunning immediately
- worth opening for broader investigation

## Why this workflow is especially useful with self-hosted runners

This repository uses self-hosted runners for some agentic workflows and automation, which makes failure triage more important.

Self-hosted runners add useful flexibility, but they also introduce a class of failures that do not exist in the same way on GitHub-hosted runners, such as:

- missing tools
- stale environments
- broken Docker availability
- path and permission issues
- disk or workspace problems
- network reachability issues
- environment drift between runners

This workflow helps distinguish those failures from actual repository or workflow logic problems.

That makes it easier to avoid blaming the wrong part of the system.

## Why this is useful in this repository

This repository is heavily focused on infrastructure, automation, provisioning, workflows, and operations.
That means GitHub Actions failures are often not just build failures.
They can represent real operational problems.

In a repo like this, failed runs can point to:

- broken automation
- misconfigured CI/CD
- unsafe workflow changes
- drift in toolchains or runners
- deployment risk
- reduced confidence in repository health

A workflow dedicated to triaging failures helps keep those signals from getting lost.

## What this workflow is not

`repo-failed-run-triage` is not:

- a replacement for fixing workflows directly
- a replacement for CI
- a full incident response platform
- a promise that every failure gets a perfect root cause
- a system that should create issues for every small problem

It is a structured failure-analysis workflow meant to improve visibility and follow-up.

## Summary

`repo-failed-run-triage` exists to turn failed workflow runs into useful operational information.

It watches for meaningful failures, investigates what likely happened, estimates severity, and opens a structured issue when the problem deserves human attention.

Its value is not just that it notices failure.

Its value is that it helps the team understand which failures matter, why they probably happened, and what should happen next.
