# Repo PR Risk Review

## What this workflow does

`repo-pr-risk-review` reviews pull requests for operational, infrastructure, automation, and security risk.

Its job is to inspect the changes in a pull request and answer a practical set of questions that maintainers usually need during review:

- what changed
- how risky the change looks
- which repository areas are affected
- what the likely blast radius is
- what validation should happen before merge
- which reviewer types should be involved

This workflow is not meant to replace CI or human review.
It is meant to make pull request review more informed and more consistent.

In this repository, that matters because many pull requests do not just change application code.
They often affect infrastructure, automation, workflows, runner behavior, provisioning, scripts, and operational processes.

## Why this workflow exists

Pull requests can look small while still carrying a lot of operational risk.

A few changed lines in the wrong place can affect:

- deployment behavior
- security posture
- self-hosted runner trust boundaries
- permissions
- secrets handling
- infrastructure safety
- operator expectations
- rollback difficulty

Without a dedicated risk review workflow, maintainers often have to infer those concerns manually while also reviewing the implementation itself.

This workflow exists to reduce that burden.

It provides a structured, repository-aware first pass over the pull request so reviewers can focus their attention where it matters most.

## Primary purpose

The main purpose of `repo-pr-risk-review` is to improve **review quality**, **risk visibility**, and **reviewer routing**.

It helps by:

- identifying high-risk changes earlier
- turning broad diffs into a clearer risk picture
- surfacing likely security and operational concerns
- suggesting validation steps before merge
- recommending the right reviewer types for the changed areas
- reducing the chance that risky changes are treated like ordinary PRs

## Why it runs on pull requests

This workflow is triggered by pull request activity because that is the best time to reason about risk.

When a gh-aw workflow runs on a pull request, it can inspect both the PR branch and the default branch. That makes it well suited for comparing what changed against the current repository baseline. It also allows the workflow to comment in the same PR context where the review decisions are already happening. 

That makes PR time the right place to surface:

- blast radius
- security concerns
- rollback difficulty
- missing validation
- reviewer needs
- docs or operational drift introduced by the change

## What kinds of changes it cares about most

This workflow is especially valuable in repositories where operationally sensitive paths matter.

In this repository, higher-sensitivity changes include areas such as:

- `.github/`
- `Ansible/`
- `Kubernetes/`
- `Packer/`
- `PXE/`
- `scripts/`
- `Terraform/`
- `.env`
- `.envrc`
- `.whitesource`
- `taskfile.yaml`

These paths matter because they often affect infrastructure behavior, automation trust boundaries, deployment logic, security posture, or operator workflow.

The workflow should still consider the full PR, but it is designed to pay extra attention when those areas change.

## What it tries to determine

The workflow is designed to answer a few high-value review questions.

### What changed

It should summarize the changed areas in a way that is easier to understand than a raw diff.

### How risky is it

It should estimate overall risk using a simple scale such as low, medium, high, or critical.

### Why that risk matters

It should explain the operational or security consequences of the change instead of only describing files.

### What should be validated

It should suggest repository-specific checks that make sense before merge.

### Who should review it

It should recommend the right reviewer type based on the affected areas.

## Why risk review matters in this repository

This repository includes infrastructure, workflows, automation, provisioning, and operational tooling.
That means a pull request can change the behavior of the platform even if it does not look large.

For example, a PR in this repo may affect:

- GitHub Actions permissions
- self-hosted runner assumptions
- Terraform behavior
- Ansible idempotence
- Kubernetes deployment safety
- PXE and Packer automation
- scripts that operators rely on
- documentation that defines expected operational behavior

A workflow like `repo-pr-risk-review` helps make those risks visible before the change lands.

## Why it comments instead of blocking by default

The workflow is designed as a **non-blocking reviewer**.

That matters because risk analysis is most useful when it helps humans focus their review, not when it becomes a brittle policy engine.

By leaving a structured review comment, the workflow can:

- summarize the risk
- call out concrete concerns
- recommend validation
- suggest reviewer types

without pretending to be the final authority on merge decisions.

This makes it easier to trust and easier to evolve over time.

## Why inline review comments are used carefully

The workflow may use line-specific PR review comments when a risk is concrete and tied to a specific line or file.

That is useful because some problems are much easier to explain inline than in a general summary.

Examples include:

- risky permission settings in a workflow file
- dangerous shell usage
- an unsafe secret-handling pattern
- a line-specific automation mistake
- a file-level rollback or blast-radius concern

However, the workflow should use inline comments sparingly.
If it comments on too many lines or comments on weak concerns, it becomes noise instead of help.

## Why reviewer recommendations matter

Not every PR needs the same kind of reviewer.

A good risk review workflow should help route the PR toward the people most likely to catch the important problems.

That might mean recommending:

- a platform automation reviewer
- an infrastructure reviewer
- a Kubernetes reviewer
- a security reviewer
- a docs reviewer

This is especially useful in a repository where different parts of the tree represent very different kinds of operational responsibility.

## Why validation guidance matters

One of the most useful outputs of this workflow is the validation checklist.

A pull request should not only be reviewed for correctness.
It should also be reviewed for how it should be tested before merge.

That may include things like:

- Terraform validation or planning
- Ansible linting or dry-run checks
- Kubernetes manifest validation
- workflow validation
- smoke tests
- secret and permission review
- rollback readiness checks

By suggesting the right validation steps, the workflow helps reduce the chance that risky changes are merged with too little verification.

## Why this workflow is not a replacement for CI

CI tells you whether certain checks passed.
This workflow tells you what the pull request appears to mean.

Those are different jobs.

CI might tell you that a linter passed.
This workflow is supposed to tell you that a workflow permission changed, a trust boundary shifted, a deployment path was modified, or a self-hosted runner assumption was introduced.

That is why the workflow complements CI rather than replaces it.

## What this workflow is not

`repo-pr-risk-review` is not:

- a merge gate by itself
- a replacement for human code review
- a replacement for CI
- a general-purpose style bot
- a workflow that should automatically request changes for everything it notices

It is a structured risk-analysis workflow designed to help reviewers understand the pull request faster and more consistently.

## Summary

`repo-pr-risk-review` exists to make pull request review more operationally aware.

It looks at the changed areas, estimates risk, explains why that risk matters, suggests validation steps, and points the pull request toward the right reviewer types.

Its value is not just that it reviews code.

Its value is that it helps the team understand what a pull request could do to the repository, the automation, and the platform before that change is merged.
