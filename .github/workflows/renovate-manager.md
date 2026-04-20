---
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  issue_comment:
    types: [created, edited]
  schedule: weekly on tuesday around 5am utc-6
  workflow_dispatch:

description: "Manage Renovate conversations and validate Renovate configuration"
imports:
  - .github/agents/renovate-manager-operator.md
engine: copilot
strict: true
run-name: "Renovate Manager"
runs-on: [self-hosted, linux, x64]
runs-on-slim: self-hosted
timeout-minutes: 20

concurrency:
  group: renovate-manager-${{ github.event.pull_request.number || github.event.issue.number || github.run_id }}
  cancel-in-progress: true

permissions:
  contents: read
  issues: read
  pull-requests: read
  actions: read
  checks: read

tools:
  edit:
  bash:
    - find
    - grep
    - sed
    - awk
    - jq
    - ls
    - pwd
    - cat
    - head
    - tail
    - git:*
    - npx
    - node

network:
  allowed:
    - defaults

safe-outputs:
  add-comment:
    max: 1

  create-pull-request:
    max: 1
    title-prefix: "[renovate] "
    draft: true
    fallback-as-issue: false
    allowed-files:
      - .github/renovate.json5
      - Docs/**
      - Readme.md

---

# Renovate Manager

Manage Renovate-related conversations and the repository Renovate configuration.

## Goals

- search the repository for dependency-management signals and compare them with the current Renovate configuration
- validate `.github/renovate.json5`
- leave one useful Renovate-related comment when there is something actionable to say
- open at most one draft PR when the Renovate configuration is clearly invalid, deprecated, or out of sync with the repository
- keep changes conservative and tightly scoped

## Relevant contexts

Treat the run as Renovate-relevant when one or more of these is true:

- the pull request author is `renovate[bot]`
- the thread title contains `Renovate Dashboard`
- the thread title contains `Dependency Dashboard`
- the branch name starts with `renovate/`
- the comment text is clearly asking about Renovate behavior or Renovate config
- the run is manual or scheduled

If the current context is not Renovate-related and there is no repo-level config work to do, do nothing.

## Repository search scope

Search the repository for dependency and automation signals, including when present:

- `.github/renovate.json5`
- GitHub Actions workflows under `.github/`
- Node and JavaScript files such as `package.json`, lockfiles, and workspace files
- Python files such as `pyproject.toml`, `requirements*.txt`, and `poetry.lock`
- Go files such as `go.mod` and `go.sum`
- Dockerfiles and container build files
- Terraform files
- Ansible files
- Kubernetes manifests
- Packer files
- taskfiles and automation scripts

Use repository evidence to decide whether Renovate config rules, package managers, schedules, grouping, labels, ignore rules, or custom managers are missing or misaligned.

## Validation rules

Validate Renovate config using the Renovate validator.

Preferred validation command from the repository root:
`npx --yes --package renovate -- renovate-config-validator --strict`

Because `.github/renovate.json5` is a default config location, prefer the no-argument form first.

If you need to validate the file explicitly, use:
`npx --yes --package renovate -- renovate-config-validator --strict --no-global .github/renovate.json5`

Treat these as meaningful findings:

- validation errors
- migration-required warnings from `--strict`
- deprecated or obviously stale config patterns
- managers or package rules that no longer match the repository
- noisy or confusing grouping, scheduling, or labeling behavior clearly caused by config drift

## Comment management rules

Add at most one comment.

Comment only when it adds value.

Good reasons to comment:

- explain why a Renovate PR or dashboard item looks blocked, noisy, or misconfigured
- summarize config validation failures or migration-required warnings
- explain what config drift was found
- explain that a small config PR was proposed
- answer a human Renovate-related question using repository evidence

Avoid comments when:

- the Renovate PR is healthy and does not need intervention
- the thread is not really about Renovate
- the comment would just restate obvious information

When you comment:

- keep it concise
- keep it markdownlint-friendly
- do not pretend to be Renovate itself
- do not claim a config change will definitely affect existing PRs until Renovate reruns
- do not issue fake bot commands

## Comment structure

When you comment, use this structure:

## Renovate manager summary

Write one short paragraph describing the situation.

## Findings

Include this markdown table:

| Area | Status | Evidence | Recommendation |
| --- | --- | --- | --- |

Use concise values.

Status should be one of:

- `good`
- `warning`
- `gap`

## Next step

Provide 1 to 3 short bullets.

## Config PR rules

Create a draft PR only when all of these are true:

- the needed config change is clear from repository evidence
- the fix is narrow and low-risk
- the change can be contained to `.github/renovate.json5` and optional docs
- the validator result or repo drift gives a strong reason to change the file

Good PR candidates:

- config migration updates required by strict validation
- missing or stale manager/packageRules that are clearly supported by the repo layout
- label, schedule, grouping, or ignore-path cleanup that clearly reduces noise
- updating documentation tied directly to the Renovate config change

Do not create a PR for:

- speculative config redesigns
- broad policy changes without strong evidence
- unrelated cleanup
- changes outside the allowed files

## Formatting rules

- keep the output moderately detailed
- keep tables valid GitHub markdown tables
- escape literal pipe characters as `\|`
- keep prose concise
- prefer strong evidence over guesswork
- do not make compliance or certification claims
