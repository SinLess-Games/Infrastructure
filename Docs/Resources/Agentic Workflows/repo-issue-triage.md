# Repo Issue Triage

## What this workflow does

`repo-issue-triage` performs first-pass triage for repository issues.

Its job is to look at newly opened, reopened, or updated issues and decide what kind of issue they are, how urgent they appear to be, which part of the repository they most likely affect, and whether the issue needs more information before maintainers can act on it.

In practical terms, this workflow is meant to help organize the issue queue by doing the repetitive classification work that humans usually end up doing manually.

That includes tasks like:

- determining whether an issue is a bug, feature request, question, docs issue, or task
- identifying likely priority
- mapping the issue to an area of the repository
- detecting when more information is needed
- flagging issues that likely need platform review or security review
- optionally leaving one short helpful comment when that comment adds real value

## Why this workflow exists

Issue queues get messy quickly.

A repository can have well-intentioned issues, but if they arrive without consistent labeling, prioritization, or routing, maintainers end up spending time figuring out basic context instead of working on the problem itself.

That creates friction in several ways:

- real bugs and urgent problems are harder to spot
- feature requests and questions get mixed together
- maintainers spend time re-reading issues just to decide where they belong
- incomplete issues sit in the queue without anyone clearly asking for the missing details
- security-sensitive or infrastructure-sensitive issues can be missed in the noise

This workflow exists to reduce that friction.

It provides a first-pass triage layer so issues enter the repository in a more organized state.

## Primary purpose

The main purpose of `repo-issue-triage` is to improve **issue hygiene**, **routing quality**, and **maintainer efficiency**.

It helps by:

- making issue classification more consistent
- reducing manual label cleanup
- identifying the most likely area of ownership
- surfacing missing information early
- helping maintainers spend less time sorting and more time acting

## What it tries to decide

This workflow is designed to answer a small set of high-value questions about each issue:

- What kind of issue is this?
- How urgent does it look?
- What area of the repository does it likely affect?
- Does it need more information before work can start?
- Does it look security-sensitive?
- Does it look like platform or infrastructure work?

Those answers are usually enough to make the issue queue more manageable without over-automating it.

## Why labels matter here

Labels are one of the main tools this workflow uses.

They are useful because they turn vague issue text into structured repository metadata.

A good first-pass triage flow makes it easier to see:

- what type of work is entering the queue
- what needs information
- what is high priority
- what area of the repo is affected
- what needs special review attention

This workflow is meant to keep labels useful and minimal rather than piling on too many.

## Why priority matters

Not every issue deserves the same level of urgency.

Some issues are:

- high-impact bugs
- security-sensitive concerns
- platform or deployment problems
- low-priority cleanup
- questions that just need clarification

This workflow exists partly to make those differences visible early.

The point is not to assign perfect priority automatically.
The point is to prevent obviously urgent work from looking the same as minor or optional work.

## Why area mapping matters

This repository spans several distinct operational domains, including GitHub workflows, Terraform, Ansible, Kubernetes, PXE, Packer, scripts, documentation, and workspace tooling.

That means maintainers often need to know not just what the issue is, but **where it belongs**.

This workflow helps by mapping issues to likely areas such as:

- GitHub
- Terraform
- Ansible
- Kubernetes
- Packer
- PXE
- Scripts
- Docs
- Workspace
- Miscellaneous

That kind of routing matters because it makes the queue easier to reason about and makes later ownership decisions more consistent.

## Why it sometimes asks for more information

Some issues are actionable immediately.
Others are too incomplete to triage properly.

This workflow is meant to recognize when a small amount of missing information is blocking useful triage.

That might include things like:

- expected versus actual behavior
- reproduction steps
- relevant file or path
- logs or error output
- environment or runner details

The goal is not to interrogate the reporter or ask for everything.
The goal is to request only the minimum information that would make the issue easier to understand and route correctly.

## Why security and platform escalation matter

Some issues may look ordinary at first but actually involve higher-risk areas such as:

- secrets
- permissions
- self-hosted runners
- workflow trust boundaries
- authentication or authorization
- deployment or infrastructure behavior

This workflow exists to surface those issues earlier by adding escalation signals such as:

- needs security review
- needs platform review

That helps keep important issues from being treated like ordinary queue noise.

## Why it filters out Renovate dashboard noise

Not every issue in a repository is a real work item for humans.

Automation-generated dashboard issues, especially Renovate dashboards, can be useful in their own context, but they are usually not the kind of issue this workflow is meant to triage as a human work item.

Ignoring those issues helps keep the triage process focused on actionable issues rather than bot-generated tracking noise.

## Why it comments conservatively

This workflow is not meant to respond to every issue with a long automated message.

That would create noise and reduce trust.

Instead, it should comment only when a comment actually improves the issue, such as when it:

- requests key missing information
- explains a non-obvious triage outcome
- points to the likely next maintainer step
- notes that the issue appears security-sensitive or platform-sensitive

If labels are enough, it should stay quiet.

## Why this is useful in this repository

This repository contains infrastructure, provisioning, automation, workflows, scripts, documentation, and operational tooling.

That means issues are often not simple feature requests.
They may involve:

- broken automation
- environment-specific failures
- security-sensitive behavior
- infrastructure drift
- documentation gaps
- complex interactions between tooling layers

A workflow like `repo-issue-triage` helps make that complexity manageable by giving each issue a consistent first-pass classification and routing decision.

## What this workflow is not

`repo-issue-triage` is not:

- a final decision-maker for issue ownership
- a replacement for human judgment
- a full project management system
- an auto-closer for low-quality issues
- a guarantee that every issue gets perfect classification

It is a first-pass queue management workflow.

Its purpose is to make issues easier to understand and easier to route, not to replace maintainers.

## Summary

`repo-issue-triage` exists to make the issue queue cleaner, more structured, and easier to manage.

It helps by classifying issues, estimating priority, identifying affected areas, requesting missing information only when needed, and surfacing issues that likely need platform or security attention.

Its value is simple: it reduces issue-management overhead and helps maintainers get to the real work faster.
