# Supply Chain Security Documentation and Resources

## What This Page Is For

This page is a curated reference for software supply-chain security.

It is meant to make it easier to find the right official documentation when working on:

- dependency trust and update policy
- SBOM generation and consumption
- provenance and artifact integrity
- signing and verification
- repository security hygiene
- build pipeline hardening
- secure software development practices
- supply-chain visibility and risk analysis

## Why Supply Chain Security Matters

Modern software is built from:

- first-party code
- third-party dependencies
- containers and base images
- build systems
- CI/CD workflows
- package registries
- cloud infrastructure
- release automation

That means software security is not just about your source code.
It is also about whether you can trust:

- what you depend on
- how software was built
- who produced an artifact
- whether the artifact was changed unexpectedly
- whether secrets or vulnerable dependencies entered the pipeline

## Foundational Frameworks and Standards

### NIST Secure Software Development Framework

Use this to understand how secure development practices should be integrated into the SDLC.

- [NIST SSDF Project Page](https://csrc.nist.gov/projects/ssdf)
- [NIST SP 800-218 (SSDF)](https://csrc.nist.gov/pubs/sp/800/218/final)

### SLSA

Use this to understand software supply-chain integrity, provenance, and build-level assurance.

- [SLSA](https://slsa.dev/)
- [SLSA Specification](https://slsa.dev/spec/v1.0/)
- [SLSA FAQ](https://slsa.dev/spec/v1.0/faq)
- [SLSA Blog](https://slsa.dev/blog)

## SBOM and Metadata Standards

### CycloneDX

Use this for SBOMs and broader bill-of-materials style supply-chain metadata.

- [CycloneDX](https://cyclonedx.org/)
- [CycloneDX Specification Overview](https://cyclonedx.org/specification/overview/)
- [CycloneDX Latest Docs](https://cyclonedx.org/docs/latest)
- [CycloneDX Guides and Resources](https://cyclonedx.org/guides/)
- [CycloneDX Tool Center](https://cyclonedx.org/tool-center/)
- [CycloneDX Authoritative Guide to SBOM](https://cyclonedx.org/guides/OWASP_CycloneDX-Authoritative-Guide-to-SBOM-en.pdf)

### SPDX

Use this for SBOM and supply-chain metadata exchange using the SPDX standard.

- [SPDX](https://spdx.dev/)
- [SPDX Overview](https://spdx.dev/learn/overview/)
- [SPDX Specifications](https://spdx.dev/use/specifications/)
- [SPDX About Overview](https://spdx.dev/about/overview/)

## Signing, Provenance, and Attestations

### Sigstore

Use this for modern artifact signing, verification, transparency logs, and keyless signing workflows.

- [Sigstore Overview](https://docs.sigstore.dev/about/overview/)
- [Sigstore Security Model](https://docs.sigstore.dev/about/security/)
- [Sigstore Cosign](https://docs.sigstore.dev/cosign/)
- [Cosign Signing Overview](https://docs.sigstore.dev/cosign/signing/overview/)
- [Sigstore Python Client](https://docs.sigstore.dev/language_clients/python/)

### in-toto

Use this to understand and verify software supply-chain steps and artifact integrity across the build pipeline.

- [in-toto](https://in-toto.io/)
- [in-toto Documentation](https://in-toto.io/docs/)
- [What is in-toto?](https://in-toto.io/docs/what-is-in-toto/)
- [Getting Started with in-toto](https://in-toto.io/docs/getting-started/)
- [in-toto Specifications](https://in-toto.io/docs/specs/)
- [in-toto Metadata Examples](https://in-toto.io/docs/examples/)

## Supply Chain Visibility and Graph Analysis

### GUAC

Use this to understand, organize, and query software supply-chain metadata and relationships.

- [GUAC](https://guac.sh/)
- [GUAC Documentation](https://docs.guac.sh/)
- [GUAC Docs](https://docs.guac.sh/guac/)
- [Getting Started with GUAC](https://docs.guac.sh/guac/getting-started/)
- [GUAC GraphQL Docs](https://docs.guac.sh/guac/graphql/)
- [GUAC Visualizer](https://docs.guac.sh/guac/guac-visualizer/)

## Repository and Open Source Security Signals

### OpenSSF Scorecard

Use this to assess repository security posture and open-source project hygiene.

- [OpenSSF Scorecard](https://scorecard.dev/)
- [OpenSSF Scorecard Project Page](https://openssf.org/projects/scorecard/)
- [OpenSSF Scorecard GitHub Repository](https://github.com/ossf/scorecard)

## GitHub-Native Supply Chain Security

### Dependency Review

Use this to understand dependency changes in pull requests before they are merged.

- [About Dependency Review](https://docs.github.com/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review)
- [Reviewing Dependency Changes in a Pull Request](https://docs.github.com/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-dependency-changes-in-a-pull-request)
- [Configuring the Dependency Review Action](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action)
- [Customizing the Dependency Review Action](https://docs.github.com/en/enterprise-cloud@latest/code-security/tutorials/secure-your-dependencies/customizing-your-dependency-review-action-configuration)
- [Dependency Review REST API](https://docs.github.com/en/rest/dependency-graph/dependency-review)

### Secret Scanning and Push Protection

Use these to detect and prevent secrets from entering the repository.

- [About Secret Scanning](https://docs.github.com/code-security/secret-scanning/about-secret-scanning)
- [Enabling Secret Scanning](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/detect-secret-leaks/enabling-secret-scanning-for-your-repository)
- [Supported Secret Scanning Patterns](https://docs.github.com/en/code-security/reference/secret-security/supported-secret-scanning-patterns)
- [About Push Protection](https://docs.github.com/en/code-security/concepts/secret-security/about-push-protection)
- [Enabling Push Protection](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/prevent-future-leaks/enabling-push-protection-for-your-repository)
- [Working with Push Protection from the Command Line](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/work-with-leak-prevention/working-with-push-protection-from-the-command-line)
- [Push Protection from the REST API](https://docs.github.com/en/code-security/concepts/secret-security/working-with-push-protection-from-the-rest-api)

### GitHub Security Overview

- [About GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)

## Suggested Learning Order

If you are new to supply-chain security, this order works well:

1. NIST SSDF
2. SLSA
3. CycloneDX
4. SPDX
5. Sigstore
6. in-toto
7. OpenSSF Scorecard
8. GitHub dependency review
9. GitHub secret scanning and push protection
10. GUAC

## Good Focus Areas

When studying supply-chain security, focus on these concepts:

### Secure Development Practices

- secure development lifecycle
- build integrity
- review discipline
- release process trust
- change control

### Dependency Risk

- dependency review
- version drift
- vulnerability exposure
- update policy
- third-party trust

### Artifact Integrity

- provenance
- signing
- verification
- attestations
- transparency logs

### Metadata and Visibility

- SBOMs
- package metadata
- component relationships
- supplier and provenance information
- graph-based risk analysis

### Repository Hygiene

- branch protection
- required checks
- workflow hardening
- least privilege
- secret prevention
- update automation

## Notes

A good supply-chain security program is not just about generating SBOMs.

It is about understanding and improving trust across:

- source
- dependencies
- build systems
- artifacts
- automation
- release processes
- repository controls

This page should grow over time as the repository’s own supply-chain practices mature.
