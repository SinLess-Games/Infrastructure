---
on:
  workflow_dispatch:
  schedule: daily

description: "Daily repository announcement discussion with security, PR, issue, and readiness reporting"
engine: copilot
strict: true
run-name: "Daily repo announcement"
timeout-minutes: 20
imports:
  - .github/agents/daily-announcement-reviewer.md

runs-on: [self-hosted, linux, x64]
runs-on-slim: self-hosted

permissions:
  contents: read
  actions: read
  checks: read
  statuses: read
  issues: read
  pull-requests: read
  discussions: read
  security-events: read

network:
  allowed:
    - defaults

safe-outputs:
  jobs:
    publish-announcement:
      description: "Create or update the daily GitHub Discussion announcement"
      runs-on: self-hosted
      output: "Daily announcement discussion published."
      permissions:
        contents: read
        discussions: write
      inputs:
        title:
          description: "Optional post title. If omitted, a dated default title is used."
          required: false
          type: string
        body:
          description: "Full markdown body for the discussion announcement."
          required: true
          type: string
      steps:
        - name: Create or update announcement discussion
          uses: actions/github-script@v8
          with:
            script: |
              # keep your existing script here
---

# Daily Repository Announcement

Review the repository and publish exactly one polished daily announcement discussion.

Your audience is humans. The post should be readable, moderately detailed, visually engaging, and worth replying to.
Use tasteful emojis throughout, but do not overdo them.
Write clean GitHub-flavored Markdown that is friendly to markdownlint formatting.

Analyze:

- repository changes from the last 24 hours
- pull requests that are blocked, stale, risky, high-impact, or otherwise notable
- open issues that need attention
- failed or flaky GitHub Actions runs
- changes under `.github/`, `terraform/`, `Terraform/`, `Ansible/`, `kubernetes/`, `Kubernetes/`, `scripts/`, `docs/`, `Docs/`, `packer/`, and `Packer/`
- obvious security risks in workflow permissions, secret handling, runner usage, unsafe shell usage, exposed credentials, missing hardening, dangerous defaults, or risky automation
- code scanning or repository-visible security findings that are available through current repository context

Required output style:

- concise but polished
- moderately detailed
- emoji-friendly
- announcement tone, not dry audit prose
- no fluff
- no fake certainty
- no legal or certification claims
- markdownlint-friendly formatting

Markdown formatting rules:

- use consistent heading levels and do not skip heading levels
- include a blank line before and after each heading
- include a blank line before and after each table
- keep tables valid GitHub markdown tables with the same number of columns in every row
- escape any literal pipe characters in titles or cell content as `\|`
- do not use trailing spaces for line breaks
- keep list nesting simple and consistent
- if a table section has no entries, still include the table with one placeholder row saying none found

The body must include these sections in this order:

## ✨ TL;DR

Provide 3 to 5 short bullets that summarize the day.

## 🚀 What changed

Provide a short paragraph summarizing the most important repository movement.
Then add 3 to 6 bullets with concrete filenames, workflow names, PR numbers, issue numbers, or commit references when available.

## 🔐 Security problems

Start with a short 1-paragraph summary of the overall security posture visible from this repository today.

Then include this markdown table exactly with these columns:

| Severity | Area | Problem | Evidence | Recommended action |

Table rules:

- include only actual security concerns, risky patterns, missing controls, or likely weaknesses
- sort by severity first, then by urgency
- severity must use one of: `🟥 High`, `🟧 Medium`, `🟨 Low`, `🟩 Good signal`
- keep each cell concise but informative
- evidence should mention concrete files, workflows, alerts, or patterns when possible
- recommended action should be specific and short
- if there are no meaningful problems, include one row that clearly says no material security problems were found and explain the strongest positive signal in the Evidence column

## 🔀 Pull requests

Write 1 short sentence describing the current PR queue.

Then include this markdown table exactly with these columns:

| PR | Title | Author | Status | Risk | Age | Next step |

Table rules:

- include the most relevant open pull requests
- prefer blocked, stale, risky, merge-conflicted, high-impact, or ready-to-merge PRs first
- PR column should use `#123`
- status should be concise, such as `blocked`, `in review`, `ready`, `stale`, `merge conflict`, or `waiting on CI`
- risk should be `high`, `medium`, or `low`
- age should be human-friendly, such as `2d` or `3w`
- next step should be a short concrete action
- if there are no open pull requests, include one placeholder row stating that there are no open PRs

## 🐛 Issues

Write 1 short sentence describing the current issue queue.

Then include this markdown table exactly with these columns:

| Issue | Title | Labels | Priority | Age | Next step |

Filtering rules:

- ignore the Renovate Dashboard issue
- ignore issues whose title contains `Renovate Dashboard`
- ignore issues whose title contains `Dependency Dashboard`
- ignore bot-created dashboard or tracking issues from `renovate[bot]`
- do not ignore real human-created dependency issues just because they mention Renovate

Table rules:

- include the most relevant open issues after filtering
- sort by urgency and maintainership impact
- issue column should use `#123`
- labels should be short and comma-separated
- priority should be `high`, `medium`, or `low`
- age should be human-friendly, such as `1d` or `2w`
- next step should be a short concrete action
- if there are no qualifying issues, include one placeholder row stating that there are no qualifying open issues

## 📊 Readiness scorecard

Give whole-number percentages from 0 to 100 for:

- GDPR readiness
- NIST SP 800-53 readiness
- HIPAA readiness
- TSC coverage
- SOC 2 readiness

Important scoring rules:

- these are repository evidence and readiness estimates only
- they are not official compliance, legal, or audit conclusions
- base them only on evidence visible from the repository and GitHub metadata available to you
- be conservative
- if evidence is weak, score lower
- add one concise sentence of reasoning per framework
- keep SOC 2 and TSC reasoning aligned where appropriate

Present this as a markdown table with exactly these columns:

| Framework | Score | Why |

## 🛠 Recommended next actions

Provide 3 to 5 concrete next steps, ordered by priority.
Each item should be actionable and specific.

## 💬 Discussion prompt

End with exactly one short question that encourages maintainers and contributors to reply.

Publishing rules:

- call `publish_announcement` exactly once
- provide the full markdown body in the `body` field
- you may provide `title`, but keep it short, engaging, and suitable for an announcement
- never publish more than one discussion per run
- if there is very little activity, still publish a compact daily heartbeat with the same structure
