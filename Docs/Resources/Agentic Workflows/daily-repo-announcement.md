# Daily Repo Announcement

## What this workflow does

`daily-repo-announcement` generates a polished daily status post for the repository and publishes it to the GitHub Discussions **Announcements** category.

The workflow is designed to act like a daily operational summary for the repository rather than a generic bot report. It reviews recent repository activity, analyzes key signals, and turns that into a discussion post that humans can actually read and respond to.

The post is intended to include:

- a short TL;DR
- a summary of what changed recently
- a security section
- a pull request table
- an issues table
- a readiness scorecard for selected security and compliance frameworks
- recommended next actions
- a short discussion prompt to encourage engagement

It is written to be clean, moderately detailed, emoji-friendly, and compatible with markdown linting expectations.

## Why this workflow exists

Most repositories have activity spread across pull requests, issues, workflow runs, commits, and security tooling, but that information is fragmented. You usually have to manually open several pages to figure out what happened, what matters, and what needs attention.

This workflow exists to solve that problem.

Instead of forcing maintainers to gather status by hand, it produces a single daily summary that answers the most important questions:

- What changed?
- What looks risky?
- Which pull requests need attention?
- Which issues matter right now?
- Are there obvious security concerns?
- What should the team do next?

It turns scattered repository signals into one readable operational snapshot.

## Primary purpose

The main purpose of this workflow is to improve **visibility**, **consistency**, and **maintainer awareness**.

It helps by:

- creating a predictable daily reporting rhythm
- reducing the need for manual status gathering
- making important security and workflow signals easier to spot
- encouraging team engagement through a discussion post instead of burying information in logs
- giving the repository a lightweight operational heartbeat

## What it reviews

The workflow is meant to inspect recent repository activity and produce a useful summary of the current state.

That includes things like:

- recent repository changes
- notable pull requests
- blocked, stale, or risky PRs
- open issues that need attention
- failed or flaky GitHub Actions runs
- changes in operationally sensitive paths such as:
  - `.github/`
  - `Terraform/`
  - `Ansible/`
  - `Kubernetes/`
  - `Packer/`
  - `PXE/`
  - `scripts/`
  - `Docs/`
- repository-visible security findings
- obvious security weaknesses in workflows, permissions, secret handling, and automation behavior

## Output format

The workflow is intentionally structured so the output is easy to skim.

A typical announcement includes the following sections:

## ✨ TL;DR

A short summary of the most important updates.

## 🚀 What changed

A concise overview of meaningful repository changes with concrete references where possible.

## 🔐 Security problems

A table of security problems or positive signals, including severity, affected area, evidence, and recommended actions.

## 🔀 Pull requests

A table of important open pull requests, usually focusing on status, risk, age, and next step.

## 🐛 Issues

A table of relevant open issues, excluding Renovate dashboard noise, so maintainers see real work instead of automation clutter.

## 📊 Readiness scorecard

A conservative repository-readiness view for selected frameworks and standards.

## 🛠 Recommended next actions

A short prioritized action list.

## 💬 Discussion prompt

A small closing question to encourage team participation.

## Why it posts to Discussions

The workflow posts to GitHub Discussions instead of just logging output in Actions because Discussions are better for human collaboration.

That matters because:

- people can react and reply
- updates are easier to find later
- the report becomes part of the repository’s operational memory
- maintainers can discuss priorities directly under the daily summary

Using the **Announcements** category also makes the output feel intentional and visible rather than disposable.

## Why the tables matter

The tables are one of the most important parts of this workflow.

They make the report more useful because they force the workflow to present operational information in a structured way instead of burying it in paragraphs.

That helps maintainers quickly identify:

- security concerns that need follow-up
- pull requests that are blocked or risky
- issues that deserve attention
- patterns that may otherwise be missed in narrative text

The tables also make the output easier to read consistently from day to day.

## Why Renovate dashboard issues are excluded

Renovate dashboards are useful for dependency automation, but they are usually not the right signal for a daily human-facing status summary.

If they are included without filtering, they can create noise and make the report feel busier than it really is.

Excluding them helps the workflow stay focused on work that usually needs human attention.

## Why the security section matters

Security issues often get overlooked when repository activity is busy.

This workflow brings security concerns into the daily conversation by explicitly checking for signals like:

- risky workflow permissions
- secret handling problems
- unsafe automation patterns
- runner-related trust concerns
- repository-visible security findings

That does not replace formal security review, but it does improve daily awareness and helps surface obvious problems earlier.

## Why the readiness scorecard exists

The readiness scorecard is meant to give a **repository-level** view of how well the repo appears aligned with selected security and compliance frameworks.

Its purpose is not to claim certification or legal compliance.

Its purpose is to answer a narrower question:

**How much visible evidence does this repository provide for the kinds of controls and practices these frameworks expect?**

That makes the scorecard useful for:

- spotting missing documentation
- identifying weak policy coverage
- highlighting security tooling gaps
- tracking improvement over time

It is best understood as a conservative readiness estimate, not an audit result.

## Why self-hosted runners are used

This workflow is intended to run on self-hosted runners so it stays aligned with the repository’s broader operational environment and infrastructure practices.

That can be useful when:

- the repo already relies on self-hosted automation
- the team wants consistent execution behavior
- local tooling or network access assumptions matter
- the repository is part of a larger internal platform workflow

## Why markdownlint-friendly formatting matters

The output is designed to follow clean Markdown structure so the generated discussion post stays readable and maintainable.

That matters because messy bot output reduces trust quickly.

Clean formatting improves:

- readability
- consistency
- long-term documentation quality
- confidence in automation output

## What this workflow is not

This workflow is not:

- a replacement for CI
- a replacement for security review
- a replacement for project management
- a legal or compliance certification engine
- a full incident response system

It is a daily reporting workflow meant to improve visibility and help humans make better decisions faster.

## Summary

`daily-repo-announcement` exists to turn repository activity into a useful daily operational report.

It helps the team by creating a clear, readable, discussion-friendly summary of what changed, what looks risky, what needs attention, and what should happen next.

Its value is not just in reporting activity.

Its value is in making the repository easier to monitor, easier to discuss, and easier to manage every day.
