# Threat Modeling Documentation and Resources

## What This Page Is For

This page is a curated reference for threat modeling.

It is meant to make it easier to find the right documentation, frameworks, tools, and learning material when working on:

- application security design
- architecture reviews
- secure development lifecycle work
- privacy engineering
- cloud and infrastructure threat analysis
- system decomposition and trust boundaries
- threat identification and mitigation planning

## Why Threat Modeling Matters

Threat modeling helps teams identify, communicate, and understand threats and mitigations in the context of protecting something valuable.

In practice, it is most useful when done early and repeated as the system changes.

## Foundational Guides

### OWASP

- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)
- [OWASP Threat Modeling Overview](https://owasp.org/www-community/Threat_Modeling)
- [OWASP Threat Modeling Process](https://owasp.org/www-community/Threat_Modeling_Process)

### Threat Modeling Manifesto

- [Threat Modeling Manifesto](https://www.threatmodelingmanifesto.org/)
- [Threat Modeling Manifesto Capabilities](https://www.threatmodelingmanifesto.org/capabilities/)

### NIST

- [NIST Glossary: Threat Modeling](https://csrc.nist.gov/glossary/term/threat_modeling)
- [NIST SP 800-154: Guide to Data-Centric System Threat Modeling](https://csrc.nist.gov/pubs/sp/800/154/ipd)
- [NIST Secure Software Development Framework Project](https://csrc.nist.gov/projects/ssdf)
- [NIST SP 800-218 (SSDF)](https://csrc.nist.gov/pubs/sp/800/218/final)

## Methodologies and Frameworks

### STRIDE

- [Microsoft Threat Modeling Tool Overview](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool)
- [Microsoft Threat Modeling Tool Threats and STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [Getting Started with Microsoft Threat Modeling Tool](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-getting-started)

### PASTA

- [CMS Threat Modeling Handbook](https://security.cms.gov/learn/cms-threat-modeling-handbook)
- [PASTA Threat Modeling Overview](https://threat-modeling.com/pasta-threat-modeling/)

### Privacy Threat Modeling

- [LINDDUN](https://linddun.org/)
- [Why Use LINDDUN](https://linddun.org/linddun/whyuselinddun/)
- [LINDDUN Threat Knowledge Support](https://linddun.org/threats/)
- [LINDDUN Go](https://linddun.org/go/)
- [NIST Privacy Framework: LINDDUN Threat Modeling Framework](https://www.nist.gov/privacy-framework/linddun-privacy-threat-modeling-framework)

## Tools

### OWASP Threat Dragon

- [OWASP Threat Dragon](https://owasp.org/www-project-threat-dragon/)
- [Threat Dragon Documentation](https://www.threatdragon.com/docs/)
- [OWASP Threat Dragon GitHub Repository](https://github.com/OWASP/threat-dragon)
- [OWASP Developer Guide: Threat Dragon](https://devguide.owasp.org/en/04-design/01-threat-modeling/03-threat-dragon/)

### Microsoft Threat Modeling Tool

- [Microsoft Threat Modeling Tool Overview](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool)
- [Getting Started with Microsoft Threat Modeling Tool](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-getting-started)
- [Microsoft Threat Modeling Tool Download](https://aka.ms/threatmodelingtool)
- [CISA: Microsoft Threat Modeling Tool](https://www.cisa.gov/resources-tools/services/microsoft-threat-modeling-tool)

## Learning and Training

### Microsoft Learn

- [Threat Modeling Fundamentals Learning Path](https://learn.microsoft.com/en-us/training/paths/tm-threat-modeling-fundamentals/)

### OWASP and Community Learning

- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)
- [Threat Modeling Manifesto](https://www.threatmodelingmanifesto.org/)
- [OWASP Threat Dragon](https://owasp.org/www-project-threat-dragon/)

## Videos

### Official and High-Value Videos

- [Master Threat Modeling: Clear and Concise Guide by OWASP](https://www.youtube.com/watch?v=RlKf3un7Uho)
- [OWASP Spotlight - Project 22 - OWASP Threat Dragon](https://www.youtube.com/watch?v=hUOAoc6QGJo)
- [Threat modeling | SC-100 | Episode 22](https://www.youtube.com/watch?v=O-hx2cZ2_EE)
- [Threat modelling with OWASP Threat Dragon](https://www.youtube.com/watch?v=mL5G8HeI8zI)

## Suggested Learning Order

If you are learning threat modeling from scratch, this order works well:

1. OWASP Threat Modeling Overview
2. OWASP Threat Modeling Cheat Sheet
3. Threat Modeling Manifesto
4. STRIDE with Microsoft Threat Modeling Tool
5. OWASP Threat Dragon
6. NIST threat modeling references
7. PASTA
8. LINDDUN for privacy-focused work

## Good Focus Areas

When studying threat modeling, focus on these concepts:

### System Understanding

- assets
- actors
- entry points
- trust boundaries
- data flows
- deployment context

### Threat Identification

- what can go wrong
- who might attack
- what they can reach
- where controls are weak
- how abuse paths form

### Mitigation Planning

- preventive controls
- detective controls
- compensating controls
- validation steps
- residual risk

### Operational Integration

- architecture review
- secure design
- SDLC checkpoints
- security stories
- review and re-modeling after change

## Notes

A few practical habits make threat modeling more useful:

- do it early
- keep it lightweight when needed
- repeat it when architecture changes
- focus on real system boundaries and data flows
- use it to drive design and backlog decisions, not just documentation
