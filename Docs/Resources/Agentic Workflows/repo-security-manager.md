# Repo Security Manager

## What this workflow does

`repo-security-manager` manages the repository’s security posture at the repository level.

It is designed to do two related kinds of work:

- manage security policy and security-related documentation
- manage repository security settings conservatively when explicitly allowed

This makes it a **security manager** workflow rather than a general reviewer.

It does not just look at security and comment on it.
It is meant to evaluate the repository’s security baseline, detect drift, propose policy updates, summarize posture, and optionally enforce approved repository-level protections.

In practical terms, this workflow is responsible for things like:

- keeping `SECURITY.md` accurate and current
- reviewing security-related docs under `Docs/`
- checking whether the repository’s security baseline appears aligned with its expectations
- summarizing strengths, gaps, and next actions
- opening a draft PR when security documentation or policy is stale
- enabling approved repository security settings in enforce mode

## Why this workflow exists

Repository security can drift quietly.

A repository might still function normally while its security policy becomes stale, its documentation falls behind, or important repository protections are missing or inconsistently configured.

That drift usually shows up in forms like:

- `SECURITY.md` exists but no longer matches the real reporting process
- security documentation no longer reflects repository structure or operational expectations
- vulnerability handling is not clearly documented
- secret scanning or push protection is missing or inconsistently enabled
- private vulnerability reporting is absent or undocumented
- security configuration is spread across repository settings and docs, but nobody is reviewing them together
- maintainers have no consistent repo-level picture of security posture

This workflow exists to prevent that drift from becoming invisible.

## Primary purpose

The main purpose of `repo-security-manager` is to improve **repository-level security hygiene**, **policy accuracy**, and **baseline consistency**.

It helps by:

- treating security policy as a maintained repository asset
- checking whether repository protections appear to match the intended baseline
- creating a clearer, repeatable view of repo-scoped security posture
- reducing the chance that security documentation becomes stale
- making security improvements reviewable and explicit instead of ad hoc

## Audit mode versus enforce mode

This workflow is intentionally designed with two operating modes.

### Audit mode

In audit mode, the workflow reads and evaluates the repository.

It is meant to:

- inspect security policy and security-related documentation
- summarize repository security posture
- identify gaps or drift
- open a draft PR for policy or docs updates when appropriate

It does **not** change repository security settings in this mode.

### Enforce mode

In enforce mode, the workflow can do everything audit mode does, but it may also apply approved repository setting changes.

That means it can move from:

- describing the missing protection

to:

- actually enabling the protection

This split matters because security automation is safer when it defaults to observation and proposal, then only performs mutations when explicitly authorized.

## Why that mode split matters

Security automation becomes dangerous quickly if it can silently change repository behavior without clear boundaries.

This workflow avoids that by using a conservative operating model:

- audit by default
- enforce only with explicit intent
- never disable protections
- never widen permissions
- never treat repository-level changes as equivalent to full compliance

That design helps keep the workflow useful without making it too powerful too early.

## What it manages

This workflow is meant to manage the repository’s security posture in the places where repository-level controls actually live.

That includes:

- `SECURITY.md`
- security-related docs in `Docs/`
- security-related sections in `Readme.md`
- repository-visible security baseline summaries
- approved repository-level security settings

It is not intended to manage all of organizational security.
It is scoped to the repository and the controls that are visible or actionable there.

## What it checks in the repository baseline

The workflow is built around a repository security baseline.

That baseline generally includes expectations such as:

- `SECURITY.md` exists
- the vulnerability reporting path is clear
- security docs match current repository reality
- vulnerability-related settings are enabled where appropriate
- secret prevention and leak-detection controls are present where supported
- repo guidance discourages storing secrets or sensitive material in tracked files
- security-sensitive workflows and behaviors are documented clearly

The goal is not to prove perfection.
The goal is to keep the repository from silently falling below its intended baseline.

## Why `SECURITY.md` matters

`SECURITY.md` is one of the most important files this workflow manages.

It acts as the human-facing entry point for vulnerability reporting and security expectations.
If it is missing, stale, or incomplete, people may not know:

- how to report a security issue
- where to send a vulnerability disclosure
- what kinds of versions or branches are supported
- how the maintainers expect security concerns to be handled

This workflow treats that file as a maintained part of the repository’s security interface, not just optional documentation.

## Why documentation is part of security management

Repository security is not only about toggling settings.

It is also about whether humans working with the repository understand:

- how to report vulnerabilities
- what protections exist
- what the expected handling process is
- how sensitive repository operations should be approached
- how security-sensitive workflows are supposed to behave

That is why this workflow manages documentation and policy alongside repository settings.

Security settings without accurate docs create confusion.
Docs without aligned settings create false confidence.

This workflow exists to keep those two things connected.

## Why repository settings are handled separately from docs

Documentation changes and repository setting changes are not equally risky.

A small policy or docs update is usually safe to propose in a draft pull request.
A repository security setting change is a real mutation of repository behavior.

That is why the workflow separates them.

For docs and policy:

- it can open a draft PR

For repository security settings:

- it uses a custom safe-output job
- it applies only approved changes
- it does so only in enforce mode

This separation keeps the workflow aligned with the principle of making reviewable changes where possible and tightly scoped mutations only where necessary.

## What kinds of settings it can manage

The workflow is intended to manage repository-level security settings that improve repository protection without weakening it.

Examples include enabling protections related to:

- vulnerability alerts
- Dependabot security updates
- private vulnerability reporting
- secret-scanning-related protections where supported

These are appropriate because they strengthen the repository baseline rather than loosening it.

## What it should never do automatically

This workflow is intentionally not a broad repo-admin bot.

It should not:

- disable security protections
- widen repository permissions
- modify unrelated repository settings
- change branch protection casually
- create security exceptions without explicit human direction
- make claims of legal or audit compliance

Its value comes from being conservative and trustworthy.

## Why compliance and standards alignment are part of the workflow

This workflow also exists because repository security is often discussed in the language of standards and frameworks.

Teams may want to know how well the repository appears aligned with expectations from things like:

- GDPR
- HIPAA
- TSC
- SOC 2
- SOC 3
- NIST SP 800-53
- NIST CSF 2.0
- NIST SSDF
- PCI DSS
- ISO/IEC 27001:2022
- ISO/IEC 27002
- CIS Controls v8
- CSA CCM
- CSA STAR
- CAIQ
- OWASP ASVS
- OWASP SAMM
- OWASP Top 10
- SLSA
- OpenSSF Scorecard

This workflow is useful because it can produce a **repository-readiness view** for those standards and frameworks.

That does not mean it certifies or proves compliance.
It means it estimates how much visible repository evidence exists for the kinds of controls, practices, and expectations those frameworks care about.

## Why repository-readiness is the right framing

A repository can provide useful evidence for security maturity and control alignment, but it is only one part of the full picture.

Many frameworks include broader requirements such as:

- organization-wide policies
- administrative controls
- physical safeguards
- incident response procedures outside the repo
- legal and audit processes
- asset inventories and governance outside GitHub

This workflow uses a narrower and more honest framing:

**repository-readiness**

That makes the output useful without overstating what the repository alone can prove.

## Why this workflow is useful in this repository

This repository includes infrastructure, automation, workflows, provisioning, scripts, documentation, and operational logic.

That means security at the repository level matters in several ways:

- workflow permissions can affect trust boundaries
- scripts and automation can influence operational risk
- docs can influence how humans handle sensitive operations
- secret leakage risk can exist in tracked files and automation paths
- security reporting paths need to remain clear and current

A workflow like `repo-security-manager` helps keep that security surface visible and maintained instead of leaving it to occasional manual review.

## Why it uses draft pull requests

When security policy or security-related docs need to change, the workflow opens a draft PR instead of changing the files silently.

That is important because even a “simple” security documentation change can influence:

- reporting expectations
- maintainer obligations
- security posture communication
- external trust in the repository

Using a draft PR keeps those changes reviewable and intentional.

## Why it uses a summary comment

The workflow can also add a concise summary comment describing the current repo-scoped security posture.

That matters because not every run should produce a PR.
Sometimes the most useful outcome is simply:

- a baseline summary
- a clear list of gaps
- a readiness-alignment view
- a short next-action list

This makes the workflow useful even when it does not change anything.

## What this workflow is not

`repo-security-manager` is not:

- a full compliance program
- a legal decision-maker
- an audit engine
- a replacement for human security review
- a complete incident response system
- a permission to let automation change security settings without oversight

It is a repository security management workflow.

Its purpose is to keep repository-level policy, documentation, and approved security settings aligned with a conservative baseline.

## Summary

`repo-security-manager` exists to manage repository-level security posture in a practical and conservative way.

It helps by reviewing policy, docs, and baseline settings together, proposing narrow documentation updates when needed, summarizing repo-scoped readiness across multiple standards and frameworks, and optionally enforcing approved protections in explicit enforce mode.

Its value is not just that it checks security.

Its value is that it keeps the repository’s security posture visible, reviewable, and less likely to drift over time.
