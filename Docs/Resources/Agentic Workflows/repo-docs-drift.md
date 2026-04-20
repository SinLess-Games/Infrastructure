# Repo Docs Drift

## What this workflow does

`repo-docs-drift` reviews pull requests for documentation drift and decides whether the repository docs still match the actual behavior, structure, and operational expectations of the repo.

It is designed to look at the pull request changes and compare them against the current documentation, especially in places where maintainers or operators are likely to rely on written guidance. In gh-aw, a `pull_request`-triggered workflow can access both the PR branch and the default branch, which makes it well suited for comparing changed implementation against existing docs. :contentReference[oaicite:0]{index=0}

The workflow is intended to focus on areas like:

- `.github/`
- `Ansible/`
- `Docs/`
- `Kubernetes/`
- `Packer/`
- `PXE/`
- `scripts/`
- `Terraform/`
- `Readme.md`
- `notes.md`
- `taskfile.yaml`

When it finds meaningful drift, it can leave a concise pull request comment and, if the fix is narrow and safe, open a docs-only pull request. gh-aw supports that model through the `create-pull-request` safe output, which lets the workflow propose changes for human review without giving the agentic portion of the workflow broad write permissions. :contentReference[oaicite:1]{index=1}

## Why this workflow exists

Documentation drift is one of the easiest forms of repository debt to accumulate.

A repository can be operationally correct while still being difficult to use because the docs describe an older structure, outdated commands, stale workflow names, or assumptions that are no longer true. That kind of mismatch is especially costly in infrastructure-heavy repositories, because incorrect docs do more than confuse people. They can cause:

- broken setup steps
- wrong deployment assumptions
- incorrect recovery actions
- confusion about workflow names or file paths
- operator errors during maintenance or onboarding

This workflow exists to catch that drift close to the point where it is introduced: the pull request.

## Primary purpose

The main purpose of `repo-docs-drift` is to keep documentation aligned with the real repository.

It helps by:

- detecting when code or automation changed but docs did not
- reducing the chance that maintainers follow stale instructions
- encouraging small docs fixes close to the change that caused them
- making documentation maintenance part of normal workflow hygiene instead of a cleanup task months later

## What kinds of drift it looks for

This workflow is meant to detect practical, operationally meaningful drift.

Good examples include:

- commands changed, but docs still show the old commands
- file paths or directory names changed, but docs still reference the old locations
- setup, validation, bootstrap, deployment, or recovery steps changed without doc updates
- workflow names or behavior changed without explanation in docs
- new operator expectations exist, but documentation does not mention them
- security-sensitive behavior changed without corresponding guidance

The point is not to nitpick writing style.

The point is to answer this question:

**Does the documentation still tell the truth about how this repository works?**

## Why it runs on pull requests

This workflow is most useful during pull request review because that is the point where documentation drift is easiest to fix.

gh-aw documents that when a workflow is triggered by a `pull_request` event, the agent has access to both the PR branch and the default branch. That means the workflow can compare what changed in the PR to what the repo currently documents, instead of trying to infer drift from only one side of the change. :contentReference[oaicite:2]{index=2}

That makes PR time the right place to catch:

- stale docs introduced by a change
- missing docs for a new workflow or command
- path mismatches after repository refactors
- missing operator notes for behavior changes

## Why it comments instead of editing everything automatically

The workflow is intentionally conservative.

Not every docs mismatch should trigger an automated change. Some fixes are broad, ambiguous, or require human judgment about wording and scope. For those cases, the right behavior is usually to leave one clear PR comment explaining the drift and suggesting the next action.

Only when the change is narrow, obvious, and safe should the workflow open a documentation follow-up PR. gh-aw’s safe outputs are specifically designed for this kind of guarded write behavior, including PR creation with file restrictions. :contentReference[oaicite:3]{index=3}

## Why docs-only pull requests matter

When the workflow can confidently fix a small documentation problem, opening a docs-only PR is better than silently editing files or mixing docs edits into unrelated code changes.

That matters because:

- the documentation fix stays reviewable
- the scope stays small
- the intent stays clear
- maintainers can decide whether to merge it independently
- the workflow remains easy to trust

This is also why the workflow is best limited to documentation files such as `Docs/**`, `Readme.md`, and similar doc paths.

## Why safe outputs are important here

This workflow is a good example of why gh-aw separates analysis from mutation.

The agentic part of the workflow reads the repo, reasons about the changes, and decides whether drift exists. The actual write behavior happens through safe outputs like `create-pull-request`, which are validated and constrained. That allows the workflow to propose useful fixes without turning the analysis step into a broad write-capable automation surface. :contentReference[oaicite:4]{index=4}

## Why this is useful in this repository

This repository contains infrastructure, automation, provisioning, and operational tooling. In that kind of repo, documentation is not just background context. It is often part of the operational interface for humans.

That means drift in docs can have real consequences:

- someone runs the wrong command
- someone edits the wrong path
- someone misunderstands a workflow or bootstrap process
- someone follows an outdated recovery or validation step
- new contributors get the wrong mental model of the repo

A workflow like `repo-docs-drift` helps prevent that by treating documentation accuracy as part of repository health.

## What this workflow is not

`repo-docs-drift` is not:

- a general writing assistant for every docs file
- a style-only grammar bot
- a replacement for maintainers deciding what should be documented
- a broad autonomous editor for repository content

It is a focused workflow for detecting and correcting meaningful drift between repository reality and repository documentation.

## Summary

`repo-docs-drift` exists to keep the documentation aligned with the actual repository.

It reviews pull requests for mismatches between changed behavior and written guidance, comments when maintainers need to know about the drift, and can propose a small docs-only pull request when the fix is obvious and safe.

Its value is simple: it helps keep the repository easier to understand, safer to operate, and less likely to mislead the people working in it.
