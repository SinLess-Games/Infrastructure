# Infrastructure Docs

This site is the operational handbook for the `Infrastructure` repository. It is meant to stay close to the code, easy to search, and reliable enough to use during real changes and incidents.

## What lives here

- Platform architecture and design decisions
- Network diagrams and port maps
- Environment setup and bootstrap guides
- Security, compliance, and operations references
- Workflow documentation for repository automation

## Quick paths

- Start with [Getting Started](Start-Here/00-Getting-Started.md) if you are setting up or rehydrating the environment.
- Use [Architecture](Architecture/ARCHITECTURE.md) for the current platform shape.
- Use [Decisions](Architecture/DECISIONS.md) and the ADR collection when you need the why behind a change.
- Use [Network](Network/Port-Map.md) during connectivity, routing, or firewall work.
- Use [Resources](Resources/Kubernetes.md) for day-two operations and platform references.

## Search and assets

The site uses full-text search, so you can jump straight to commands, services, ADRs, or diagrams from the search bar.

These documentation assets are all supported inside `Docs/` and will be published with the site:

- `.md`
- `.md5`
- `.svg`
- `.png`
- `.pdf`

## Working agreement

Documentation should be updated in the same branch as infrastructure changes whenever the operating model, dependencies, exposure, or recovery steps change. The goal is that the docs stay useful under pressure instead of becoming a museum.
