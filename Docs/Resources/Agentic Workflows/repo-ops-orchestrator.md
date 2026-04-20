# Repo Ops Orchestrator

## What this workflow does

`repo-ops-orchestrator` is the coordination layer for the repository’s agentic automation.

Unlike the other workflows, it is not primarily responsible for doing detailed analysis itself. Its role is to look at the current state of the repository, decide which specialized workflows are worth running, and then dispatch the right worker workflows.

In other words, it acts as the workflow that decides:

- what needs attention
- which agentic workflow is the right tool for the job
- whether work should be done now or skipped to avoid noise
- how to keep the overall automation system coordinated instead of fragmented

This makes it the top-level operational router for the repository’s agentic workflows.

## Why this workflow exists

As the number of agentic workflows grows, a repository can end up with many useful automations that are each good at one specific job:

- one workflow triages failed runs
- another handles issue triage
- another checks docs drift
- another posts daily status summaries
- another manages security posture
- another manages project routing or kanban state

That specialization is useful, but it creates a new problem: something still needs to decide **which** workflow should run, **when**, and **why**.

Without an orchestrator, automation tends to become one of two bad states:

- too much automation running too often
- useful workflows existing but not being used at the right time

`repo-ops-orchestrator` exists to solve that coordination problem.

## Primary purpose

The main purpose of `repo-ops-orchestrator` is to provide **central operational coordination** for the repository’s agentic workflows.

It helps by:

- reducing duplicate or unnecessary workflow runs
- dispatching specialized worker workflows only when they are justified
- keeping automation focused on the highest-value work
- creating a predictable control point for repository operations
- making the overall workflow system easier to reason about

It is the workflow that helps the rest of the workflow system act like a coherent platform instead of a pile of unrelated automations.

## How it works

This workflow follows the orchestrator/worker model.

That means:

- the orchestrator decides what should happen next
- worker workflows do the detailed work
- the orchestrator dispatches workers instead of trying to do all the work itself

In this repository, that means `repo-ops-orchestrator` should inspect the current repository state and decide whether to trigger things like:

- failed-run triage
- issue triage
- docs-drift review
- daily repo reporting
- other specialized workflows as the system grows

The workflow is meant to use agentic judgment to decide whether a worker run would actually add value, instead of dispatching everything on every schedule.

## Why dispatching is better here than doing the work directly

The orchestrator is intentionally not the place where all detailed work should happen.

If it tried to triage issues, inspect failed runs, review docs drift, summarize repo state, and manage project boards all by itself, it would become too broad, too noisy, and too hard to trust.

That is why it should stay focused on orchestration.

The specialized worker workflows already exist to do the concrete work. The orchestrator’s value comes from choosing the right workers, not from replacing them.

## What kinds of workflows it should coordinate

This workflow is best suited for coordinating other workflows that already have a clear, specialized job.

Examples include:

- `repo-failed-run-triage`
- `repo-issue-triage`
- `repo-docs-drift`
- `daily-repo-announcement`
- `repo-security-manager`
- `repo-kanban-manager`
- other future worker workflows that support manual or dispatch-style execution

The orchestrator should not dispatch workflows just because they exist.
It should dispatch them because there is visible evidence that their work is needed.

## Why that matters

This repository contains multiple kinds of operational activity:

- infrastructure changes
- workflow changes
- issue activity
- pull request activity
- documentation updates
- failed automation
- security and reporting needs

Those signals do not always happen at the same time, and they do not always justify the same workflows.

For example:

- a failed run might justify failed-run triage
- a docs-heavy PR might justify docs-drift review
- a day with meaningful activity might justify a daily announcement
- a quiet day might justify doing nothing at all

That is why orchestration matters.
It keeps the system responsive to real conditions instead of hard-coding every action into schedules.

## Why “doing nothing” is sometimes correct

One of the most important jobs of this workflow is to decide when **not** to run something.

That matters because bad orchestration creates noise:

- duplicate reports
- redundant triage
- repeated board updates
- unnecessary comments
- more workflow churn than actual value

A good orchestrator is not the one that dispatches the most work.
It is the one that dispatches the **smallest useful set of workflows**.

This workflow should treat “no dispatch needed” as a valid and healthy outcome.

## Why this workflow is useful in this repository

This repository is already structured around many specialized operational concerns.

That means it benefits from a workflow that can see the broader picture and answer questions like:

- is there meaningful activity worth summarizing today
- are there failures that deserve triage
- are there active issues that still need first-pass classification
- are there PRs that likely created docs drift
- which worker workflow will add the most value right now

A workflow like `repo-ops-orchestrator` is especially useful in a repository with a growing agentic workflow system because it prevents the automation layer from becoming fragmented.

## What this workflow is not

`repo-ops-orchestrator` is not:

- a replacement for the worker workflows
- a broad all-in-one reviewer
- a place to do every kind of repo analysis directly
- a workflow that should dispatch every worker on every run
- a project management system by itself

It is a control-plane workflow.

Its job is to decide what should happen next and let the specialized workflows do the real work.

## Why it improves maintainability

As agentic workflows are added over time, the repository needs a way to keep them organized.

Without that, each workflow tends to become more self-triggered, more overlapping, and more likely to create noise.

By centralizing decision-making, `repo-ops-orchestrator` improves maintainability because it:

- gives the repo one place to express operational priorities
- makes it easier to add new worker workflows later
- helps reduce overlapping responsibility between workflows
- keeps the system easier to debug and reason about

It becomes the workflow that answers not just “what can we automate,” but “what should we automate right now.”

## Summary

`repo-ops-orchestrator` exists to coordinate the repository’s agentic workflows.

It does not try to replace the specialized workflows.
Instead, it inspects the current state of the repository, decides which worker workflows are worth running, and dispatches only the workflows that are justified by current evidence.

Its value is simple: it turns a collection of specialized automations into a more coherent operational system.
