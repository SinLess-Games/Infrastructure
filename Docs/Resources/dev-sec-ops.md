# DevSecOps Documentation and Resources

## What DevSecOps Means

DevSecOps is the practice of building security into the software delivery lifecycle instead of treating it as a separate final step.

In practice, that usually means:

- secure design and threat modeling early
- security checks in CI/CD
- dependency and supply-chain controls
- secrets detection and prevention
- policy, review, and automation working together
- security findings being handled as normal engineering work

This page is a curated starting point for learning DevSecOps in a practical, modern way.

## Recommended Learning Order

If you are new to DevSecOps, use this order:

1. Learn the secure development lifecycle
2. Learn application security basics
3. Learn supply-chain security basics
4. Learn CI/CD security controls
5. Learn repository and workflow security
6. Learn cloud and infrastructure security automation
7. Learn how to measure maturity and improve over time

## Core Standards and Frameworks

### NIST Secure Software Development Framework

Use this to understand secure software development practices that can be integrated into normal SDLC work.

- [NIST SSDF SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final)

### NIST Cybersecurity Framework 2.0

Use this to understand how software and engineering work fit into broader cybersecurity outcomes and risk management.

- [NIST CSF 2.0](https://www.nist.gov/publications/nist-cybersecurity-framework-csf-20)

### OWASP SAMM

Use this to understand software security maturity and how to improve over time in a structured way.

- [OWASP SAMM](https://owasp.org/www-project-samm/)

### OWASP ASVS

Use this as a practical verification standard for application security controls.

- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)

### SLSA

Use this to learn software supply-chain integrity and build provenance concepts.

- [SLSA](https://slsa.dev/)

### OpenSSF Scorecard

Use this to evaluate repository and open-source security hygiene at a high level.

- [OpenSSF Scorecard](https://openssf.org/projects/scorecard/)
- [Scorecard](https://scorecard.dev/)

## GitHub-Native DevSecOps Resources

### Security and Analysis Features

These are core GitHub repository security features that matter in DevSecOps.

- [Managing security and analysis settings for your repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-security-and-analysis-settings-for-your-repository)
- [GitHub security features](https://docs.github.com/en/code-security/getting-started/github-security-features)

### Dependency Review

Use this to understand how dependency changes in pull requests can be reviewed and enforced.

- [About dependency review](https://docs.github.com/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review)
- [Configuring the dependency review action](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action)
- [Reviewing dependency changes in a pull request](https://docs.github.com/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-dependency-changes-in-a-pull-request)

### Secret Scanning and Push Protection

Use these to understand how to detect and prevent credential leaks in repositories.

- [About secret scanning](https://docs.github.com/code-security/secret-scanning/about-secret-scanning)
- [Enabling push protection for your repository](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/prevent-future-leaks/enabling-push-protection-for-your-repository)

## Supply Chain and Repository Security

These are some of the most important DevSecOps topics to understand after the SDLC basics.

### Learn These Concepts

- dependency review
- SBOMs
- provenance
- build integrity
- branch protection
- workflow hardening
- least privilege in CI/CD
- artifact trust
- secret prevention
- update automation

### Good Reference Material

- [SLSA specification](https://slsa.dev/spec/v1.0/)
- [OpenSSF Scorecard](https://github.com/ossf/scorecard)

## Application Security and Maturity

These resources are useful when you want to move from “we run scanners” to “we have a real secure engineering program.”

- [OWASP SAMM](https://owasp.org/www-project-samm/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Developer Guide: SAMM](https://devguide.owasp.org/en/11-security-gap-analysis/01-guides/01-samm/)
- [OWASP Developer Guide: ASVS](https://devguide.owasp.org/en/06-verification/01-guides/03-asvs/)

## Practical DevSecOps Focus Areas

When studying DevSecOps, focus on building skill in these areas:

### Secure Development Lifecycle

- requirements and security acceptance criteria
- threat modeling
- secure coding practices
- review and testing expectations
- release readiness
- incident response inputs from engineering

### CI/CD Security

- least-privilege workflow permissions
- safe secret handling
- build isolation
- branch protection and required checks
- dependency review gates
- artifact signing and provenance

### Infrastructure and Cloud Security

- IaC review
- policy as code
- misconfiguration detection
- runtime exposure awareness
- secrets management
- deployment safety and rollback planning

### Open Source and Dependency Management

- update automation
- dependency risk review
- vulnerability handling
- grouping strategies
- versioning discipline
- third-party trust decisions

## Videos

### Good Starting Video

- [DevOps from Zero to Hero: Build and Deploy a Production API](https://youtu.be/H5FAxTBuNM8?si=WCCMbAXZAdfOygH7)

### Suggested Video Topics to Search For

Look for current, practical content on:

- NIST SSDF walkthrough
- GitHub Actions security hardening
- dependency review action
- secret scanning and push protection
- OWASP SAMM overview
- SLSA and software supply-chain security
- OpenSSF Scorecard walkthrough
- secure CI/CD pipelines
- threat modeling for developers
- DevSecOps with Kubernetes and Terraform

## Suggested Study Path for This Repository

Because this repository includes infrastructure, workflows, Kubernetes, Terraform, scripts, and automation, this study order will be the most useful:

1. NIST SSDF
2. GitHub security and analysis settings
3. Dependency review and secret scanning
4. OWASP SAMM
5. OWASP ASVS
6. SLSA
7. OpenSSF Scorecard
8. Infrastructure-as-code security review
9. Workflow permission hardening
10. Supply-chain security automation

## Notes

A good DevSecOps program is not just a collection of scanners.

It is a repeatable engineering approach that makes security part of how software and infrastructure are designed, reviewed, built, shipped, and maintained.

This page should grow over time as better resources are found and as the repository’s own security practices mature.
