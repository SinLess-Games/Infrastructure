# Repo Routing Manager

## What this workflow does

`repo-routing-manager` manages the operational routing metadata for issues and pull requests.

Its job is to look at a newly created or updated issue or pull request and decide how it should be organized inside the repository. That includes:

- labels
- milestones
- assignees
- reviewers for pull requests

This workflow is meant to keep routing information accurate, minimal, and useful instead of leaving maintainers to sort and re-sort the same metadata by hand. gh-aw supports this kind of workflow well because it has built-in safe outputs for adding and removing labels, assigning milestones, assigning users, and requesting reviewers, while keeping the agentic portion of the workflow read-only. :contentReference[oaicite:0]{index=0}

## Why this workflow exists

As a repository grows, it becomes harder to keep work organized consistently.

Issues and pull requests tend to arrive in different shapes:

- some are clearly bugs
- some are questions
- some are infrastructure work
- some are docs work
- some are urgent
- some are blocked
- some need a specific reviewer or owner
- some belong in a milestone and some do not

Without a routing workflow, that information often gets filled in inconsistently or not at all. That creates friction for maintainers because they have to spend time figuring out where something belongs before they can start acting on it.

This workflow exists to reduce that friction.

## Primary purpose

The main purpose of `repo-routing-manager` is to improve **repository organization**, **queue clarity**, and **ownership routing**.

It helps by:

- applying a small, consistent label set
- attaching milestones only when they are justified
- assigning ownership when responsibility is clear
- requesting the right reviewers on pull requests
- keeping stale routing metadata from lingering after the context changes

## Why labels are part of this workflow

Labels are one of the simplest and most useful ways to structure repository work. GitHub uses labels to categorize issues, pull requests, and discussions, and the same repository labels can be reused across those items. :contentReference[oaicite:1]{index=1}

This workflow uses labels as the first layer of routing because labels make it easier to answer questions like:

- what kind of work is this
- what area of the repository does it affect
- how urgent is it
- does it need platform review or security review
- does it need more information before work can start

## Why milestones are part of this workflow

Milestones help group issues and pull requests around a shared release target, delivery window, or planning bucket. GitHub explicitly supports associating both issues and pull requests with milestones so their progress can be tracked together. :contentReference[oaicite:2]{index=2}

That makes milestones useful when there is a clear planning reason to assign one.

This workflow includes milestone management because repository routing is not just about classification. It is also about deciding whether a work item belongs in a planned bucket at all.

## Why assignees are part of this workflow

Labels tell you what something is. Assignees tell you who is currently expected to own it.

GitHub allows issues and pull requests to be assigned to users, and that is useful when the workflow can infer a clear ownership signal from the content or the changed area. :contentReference[oaicite:3]{index=3}

This workflow includes assignee management because ownership is one of the most important routing signals in a busy repository. If ownership is missing or stale, work tends to drift.

## Why reviewers are handled separately

Reviewers are different from assignees.

Issues can have assignees and milestones, but review requests are specifically part of pull request review flow. GitHub documents reviewer requests as a pull-request-specific action, and requested reviewers can be either users or teams with the right repository access. :contentReference[oaicite:4]{index=4}

That matters because a good routing workflow should not treat issues and pull requests as identical. Issues need classification and ownership. Pull requests need classification, ownership context, and review routing.

## Why this workflow is useful for pull requests too

On GitHub, pull requests are a type of issue for shared metadata such as labels, assignees, and milestones. GitHub’s docs explicitly note that actions shared by issues and pull requests, such as managing assignees, labels, and milestones, are handled through the issues model, while review requests are handled through pull request review APIs. :contentReference[oaicite:5]{index=5}

This is exactly why `repo-routing-manager` makes sense as one workflow instead of several tiny ones. It can handle the shared routing metadata for both issues and pull requests, then apply reviewer logic only when the item is a PR.

## What kinds of routing decisions it should make

This workflow is meant to make conservative, explainable routing decisions.

Typical routing decisions include:

- adding a `type:*` label such as bug, feature, docs, question, or task
- adding an `area:*` label such as GitHub, Terraform, Ansible, Kubernetes, Scripts, Docs, or Workspace
- adding one priority label when urgency is reasonably clear
- marking something as `needs-info`, `triaged`, or `blocked` when supported by evidence
- assigning a milestone when there is a clear planning target
- assigning ownership when the likely owner is clear
- requesting review from the right reviewer type on a PR

The key is not to automate everything.
The key is to make the obvious routing decisions consistently.

## Why conservative routing matters

This workflow is most useful when it avoids low-confidence guesses.

Bad routing is often worse than no routing because it creates false confidence.

Examples of bad routing would be:

- assigning a milestone just to fill the field
- assigning a user with no real ownership signal
- requesting reviewers randomly
- adding too many labels
- leaving stale labels in place after the item changed
- treating every issue as equally urgent

That is why this workflow should prefer fewer, higher-quality routing actions over noisy over-automation.

## Why this is useful in this repository

This repository spans multiple operational domains, including infrastructure, automation, CI/CD, provisioning, documentation, and workflow management.

That means repository work is not all handled by the same kind of reviewer or owner.

A routing manager is useful here because it can help distinguish between work that belongs to:

- platform automation review
- infrastructure review
- Kubernetes review
- security review
- documentation review

It can also help keep milestones, ownership, and labels aligned with the real kind of work being discussed.

## What this workflow is not

`repo-routing-manager` is not:

- a full project management system
- a replacement for human prioritization
- a replacement for kanban or project-board management
- a guarantee that every item gets perfect ownership automatically
- a workflow that should assign everyone and everything all the time

It is a routing workflow.

Its job is to make repository metadata more useful, not to replace human judgment.

## Summary

`repo-routing-manager` exists to keep issues and pull requests organized in a consistent, low-noise way.

It manages labels, milestones, assignees, and reviewers so maintainers can spend less time on manual routing and more time on actual work. It is especially valuable because GitHub supports shared metadata across issues and pull requests, while reviewer requests remain PR-specific, which makes a combined routing workflow both practical and efficient.
