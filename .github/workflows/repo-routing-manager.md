---
on:
  issues:
    types: [opened, edited, reopened]
  pull_request:
    types: [opened, edited, reopened, ready_for_review, synchronize]
  workflow_dispatch:

description: "Manage labels, milestones, assignees, and reviewers for issues and pull requests"
imports:
  - .github/agents/routing-manager-operator.md
engine: copilot
strict: true
run-name: "Repository Routing Manager"
runs-on: [self-hosted, linux, x64]
runs-on-slim: self-hosted
timeout-minutes: 15

concurrency:
  group: repo-routing-manager-${{ github.event.issue.number || github.event.pull_request.number || github.run_id }}
  cancel-in-progress: true

permissions:
  contents: read
  issues: read
  pull-requests: read
  actions: read
  checks: read

network:
  allowed:
    - defaults

safe-outputs:
  add-comment:
    max: 1

  add-labels:
    allowed:
      - type:bug
      - type:feature
      - type:question
      - type:docs
      - type:task
      - status:needs-info
      - status:triaged
      - status:blocked
      - priority:low
      - priority:medium
      - priority:high
      - area:github
      - area:terraform
      - area:ansible
      - area:kubernetes
      - area:packer
      - area:pxe
      - area:scripts
      - area:docs
      - area:workspace
      - area:misc
      - needs-security-review
      - needs-platform-review
    max: 6

  remove-labels:
    allowed:
      - type:bug
      - type:feature
      - type:question
      - type:docs
      - type:task
      - status:needs-info
      - status:triaged
      - status:blocked
      - priority:low
      - priority:medium
      - priority:high
      - area:github
      - area:terraform
      - area:ansible
      - area:kubernetes
      - area:packer
      - area:pxe
      - area:scripts
      - area:docs
      - area:workspace
      - area:misc
      - needs-security-review
      - needs-platform-review
    max: 6

  assign-milestone:
    allowed:
      - backlog
      - next
      - v1
      - v2
    max: 1

  assign-to-user:
    allowed:
      - sinless777
    max: 2

  unassign-from-user:
    allowed:
      - sinless777
    max: 2

  add-reviewer:
    reviewers:
      - sinless777  
      - copilot
    max: 3

---

# Repository Routing Manager

Review the triggering issue or pull request and manage labels, milestone, assignees, and reviewers conservatively.

## Goals

- keep labels accurate and minimal
- attach a milestone only when the target is clear
- assign or unassign owners only when responsibility is reasonably clear
- request reviewers only for pull requests and only when the changed area supports it
- keep routing low-noise and evidence-driven

## Repository routing guidance

High-sensitivity areas:

- `.github/**`
- `Ansible/**`
- `Kubernetes/**`
- `Packer/**`
- `PXE/**`
- `scripts/**`
- `Terraform/**`
- `.env`
- `.envrc`
- `.whitesource`
- `taskfile.yaml`

Medium-sensitivity areas:

- `.taskfiles/**`
- `.vscode/**`
- `.codex/**`
- `Docs/**`
- `Readme.md`
- `notes.md`
- `.gitattributes`
- `.gitignore`

## Labels

Manage labels conservatively.

Apply:

- exactly one `type:*` label when clear
- at most one `priority:*` label
- zero or more `area:*` labels supported by evidence
- `status:needs-info` only when important context is missing
- `status:triaged` when the item is understandable and correctly routed
- `status:blocked` only when there is a real dependency or blocker
- `needs-security-review` for secrets, permissions, trust boundaries, exposure, self-hosted runners, or sensitive workflow changes
- `needs-platform-review` for infrastructure, automation, deployment, or operational risk

Remove stale labels from the configured label set when they no longer match the item.

## Milestones

Assign a milestone only when there is a clear release or planning destination.
Do not assign a milestone just to fill the field.
If the right milestone is not obvious, leave it unset.

## Assignees

Assign users only when there is a clear ownership signal.
Use assignees for accountable ownership, not broad awareness.
If current ownership is clearly wrong and evidence supports reassignment, unassign stale owners before assigning the correct one.

## Reviewers

Only request reviewers for pull requests.

Reviewer routing guidance:

- `.github/**`, `scripts/**`, `taskfile.yaml` -> platform reviewer
- `Terraform/**`, `Ansible/**`, `Packer/**`, `PXE/**` -> infrastructure reviewer
- `Kubernetes/**` -> Kubernetes or platform reviewer
- secrets, permissions, runner, trust-boundary changes -> security reviewer
- docs-only pull requests usually do not need extra reviewers unless the repo policy says otherwise

Do not request reviewers for issues.
Do not request reviewers when the pull request is clearly draft-only exploration unless the change is high risk.

## Comment policy

Add at most one comment, and only when it adds value.

Good reasons to comment:

- explain why routing changed materially
- request the minimum missing information
- explain a milestone or ownership decision that might otherwise be unclear

Avoid comments when labels, assignees, milestone, and reviewers are enough.

## Required reasoning

Decide:

- correct type label
- correct priority label
- correct area labels
- whether the item needs more information
- whether it needs security review
- whether it needs platform review
- whether it belongs in a milestone
- whether it needs an assignee
- whether it needs reviewers

## Output rules

- be conservative
- do not invent ownership
- do not assign random reviewers
- do not assign milestones without a clear basis
- do not restate the entire issue or PR
- keep any comment concise and markdownlint-friendly
