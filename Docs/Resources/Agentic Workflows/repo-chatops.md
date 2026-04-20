# Repo ChatOps

## What this workflow does

`repo-chatops` gives the repository a GitHub-native command interface so maintainers can trigger focused analysis directly from issues, pull requests, discussions, and comments instead of opening a separate workflow or digging through logs. In gh-aw, this is built on the `slash_command` trigger, which is designed for workflows that respond to commands typed into GitHub conversations. :contentReference[oaicite:0]{index=0}

In practice, this workflow acts like an on-demand operator. Rather than running continuously on every repository event, it waits for a human to ask for something specific, such as a risk review, a summary, a docs-drift check, or a run-triage response. The command text and surrounding discussion context are made available to the workflow in sanitized form so the workflow can respond to the current conversation rather than relying on guesswork. :contentReference[oaicite:1]{index=1}

The current design uses a single `/ops` command as the entry point, then interprets the next token as a subcommand such as `help`, `review-risk`, `triage-issue`, `triage-run`, `docs-drift`, or `summarize`. That structure keeps the workflow simple and compatible while still allowing multiple operator actions through one command surface. The matched slash command is exposed to the workflow, and sanitized context is available from `steps.sanitized.outputs.text`. :contentReference[oaicite:2]{index=2}

## Why this workflow exists

Most repositories accumulate a lot of state that is difficult to inspect quickly. A maintainer may want to know whether a PR is risky, whether an issue is missing information, whether a failed run looks transient, or whether a long thread can be summarized. Without ChatOps, those answers usually require opening multiple pages, scanning comments manually, and mentally stitching context together.

This workflow exists to reduce that friction.

Instead of forcing a maintainer to leave the conversation, gather context, and then come back with an answer, `repo-chatops` brings that analysis into the thread where the question is already being discussed. That is the core value of ChatOps in gh-aw: automation that is invoked directly from GitHub conversations, close to the work itself. :contentReference[oaicite:3]{index=3}

## Primary purpose

The main purpose of `repo-chatops` is to provide **on-demand operational assistance**.

It is meant to help with tasks that are:

- too contextual for a scheduled workflow
- too small to justify a full manual investigation
- too frequent to keep doing by hand
- best answered in the same thread where the question was asked

That makes it a good fit for maintainers who want fast, contextual answers without turning every question into a separate workflow design problem.

## How it works

The workflow is triggered by a GitHub slash command. gh-aw supports slash-command workflows specifically for issues, pull requests, and comment-driven contexts, which makes them ideal for interactive automation. The workflow can also be combined with `workflow_dispatch` so it can still be run manually if needed. :contentReference[oaicite:4]{index=4}

Once triggered, the workflow reads the sanitized command context and decides which subcommand behavior to execute. In your version, `/ops` is the main command and the workflow interprets the remainder of the text as the requested action.

That means commands like these are possible:

- `/ops help`
- `/ops review-risk`
- `/ops triage-issue`
- `/ops triage-run`
- `/ops docs-drift`
- `/ops summarize`

This approach gives the repository a compact command surface without needing a separate dedicated slash command for every small operation.

## What it is meant to help with

The workflow is designed to answer lightweight but high-value questions inside GitHub threads.

Typical use cases include:

- summarizing a noisy issue or discussion
- giving a quick PR risk summary
- pointing out likely docs drift
- triaging a failed workflow run when someone pastes a run URL or discusses a failure
- giving a concise help response for supported command patterns
- extracting blockers and next steps from a long thread

These are exactly the kinds of interactive, thread-local tasks that ChatOps is good at.

## Why it uses comments instead of direct mutation

The workflow is intentionally designed to reply in-thread, and only use more targeted actions when they clearly add value. gh-aw’s safe outputs exist so workflows can create GitHub comments, PR review comments, issues, or PRs without giving the agentic part of the workflow broad write access. That separation is one of the core security properties of gh-aw. :contentReference[oaicite:5]{index=5}

For `repo-chatops`, that matters because most commands are advisory. The goal is usually to explain, summarize, or guide, not to silently mutate repository state. Keeping the output centered on one top-level comment makes the workflow easier to trust and easier to follow in GitHub conversations.

## Why inline PR comments are limited

When the workflow is used in pull request contexts, it may create inline PR review comments for line-specific issues. gh-aw supports review-comment safe outputs for that purpose. However, the workflow is intentionally conservative about using them, because inline comments are most useful when the issue is concrete, file-specific, and actionable. Overusing them would turn ChatOps into noise instead of help. :contentReference[oaicite:6]{index=6}

That is why `repo-chatops` is designed to use inline comments only for targeted PR feedback, usually when `review-risk` finds something specific enough to annotate.

## Why it uses sanitized context

A command workflow is only useful if it can understand the thread it was called from. gh-aw exposes sanitized context text so the workflow can analyze the current issue body, PR description, or comment content safely. For issues and pull requests, this includes title and body content; for comments and reviews, it includes the body text. :contentReference[oaicite:7]{index=7}

That matters because ChatOps is inherently conversational. The workflow is supposed to respond to the current discussion, not produce a generic answer disconnected from the actual thread.

## Why access control matters

A workflow that responds to comments can become noisy or risky if anyone can trigger it without limits. gh-aw’s ChatOps and command-trigger model supports access control and filtering so command-based workflows can be limited to the right users and contexts. This is one of the reasons ChatOps fits maintainers well: it can be interactive without becoming open-ended or uncontrolled. :contentReference[oaicite:8]{index=8}

In your repository, this matters because the workflow is intended to assist maintainers and reviewers, not act as a public free-for-all bot.

## Why this is useful in this repository

This repository spans infrastructure, automation, CI/CD, Kubernetes, Terraform, PXE, Packer, scripts, and documentation. That means many threads involve operational context that is not obvious from a single file or a single message.

A workflow like `repo-chatops` is useful here because it can answer practical questions in context:

- what changed in this PR that looks risky
- what is missing from this issue
- does this failed run sound like a runner issue or a repo issue
- do the docs still match what the repo is doing
- what are the next steps in this thread

That makes it a natural operator tool for a repository where many discussions are about systems behavior rather than just code snippets.

## What this workflow is not

`repo-chatops` is not:

- a replacement for scheduled reporting
- a replacement for CI
- a replacement for dedicated triage workflows
- a replacement for formal review
- a general-purpose chatbot for anything and everything

It is a targeted GitHub-native operator interface.

Its job is to provide concise, high-signal analysis in the place where maintainers are already collaborating.

## Summary

`repo-chatops` exists to bring useful, on-demand repository analysis directly into GitHub conversations.

It helps by turning a slash command into a focused operator action, such as summarizing a thread, triaging an issue, reviewing PR risk, or identifying docs drift. The reason it exists is simple: it is faster, more contextual, and more maintainable to ask for help in the thread where the work is happening than to gather everything manually somewhere else
