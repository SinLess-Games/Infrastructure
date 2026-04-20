# Chaos Engineering Documentation and Resources

## What This Page Is For

This page is a curated reference for chaos engineering, resilience testing, fault injection, and reliability experimentation.

It is meant to make it easier to find the right documentation, tools, and learning material when working on:

- resilience engineering
- fault injection
- reliability validation
- disaster recovery testing
- Kubernetes chaos experiments
- cloud failure simulation
- steady-state verification
- incident learning and operational hardening

## Why Chaos Engineering Matters

Chaos engineering is the discipline of experimenting on a system in order to build confidence in the system’s ability to withstand turbulent conditions.

In practice, that means deliberately introducing controlled failure into a system so teams can learn:

- what breaks
- what degrades
- what alerts correctly
- what recovers automatically
- what needs stronger safeguards

The goal is not random destruction.
The goal is controlled learning that improves resilience.

## Foundational Concepts and Principles

### Principles of Chaos Engineering

These are the most important starting points for understanding the mindset behind chaos engineering.

- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Principles Overview](https://principlesofchaos.org/)
- [Chaos Engineering Definition](https://principlesofchaos.org/)
- [Steady-State and Turbulent Conditions](https://principlesofchaos.org/)

## Core Chaos Engineering Platforms and Tools

### Chaos Mesh

Chaos Mesh is a cloud-native chaos engineering platform for Kubernetes.
It supports many fault types and orchestrated experiment flows.

- [Chaos Mesh Documentation](https://chaos-mesh.org/docs/)
- [Chaos Mesh Overview](https://chaos-mesh.org/docs/)
- [Run a Chaos Experiment](https://chaos-mesh.org/docs/run-a-chaos-experiment/)
- [Chaosd Overview](https://chaos-mesh.org/docs/chaosd-overview/)
- [Supported Versions](https://chaos-mesh.org/versions/)

### Litmus

Litmus is a cloud-native chaos engineering framework and platform designed for Kubernetes and modern infrastructure.

- [Litmus Docs](https://docs.litmuschaos.io/)
- [What is Litmus?](https://docs.litmuschaos.io/docs/introduction/what-is-litmus)
- [Chaos Workflows and Experiments](https://docs.litmuschaos.io/docs/concepts/chaos-workflow)
- [Litmus Overview Site](https://litmuschaos.io/)
- [Litmus ChaosHub and Platform Overview](https://litmuschaos.io/enterprise)

### Gremlin

Gremlin is a commercial chaos engineering and reliability platform focused on safe, structured fault injection and resilience validation.

- [Gremlin Chaos Engineering Overview](https://www.gremlin.com/chaos-engineering)
- [Gremlin Product Overview](https://www.gremlin.com/product/chaos-engineering)
- [Gremlin Resources](https://www.gremlin.com/resources)
- [Gremlin Free Software Overview](https://www.gremlin.com/gremlin-free-software)

### Chaos Monkey

Chaos Monkey is a classic resiliency tool from Netflix focused on random instance termination to validate service resilience.

- [Chaos Monkey Docs](https://netflix.github.io/chaosmonkey/)
- [How to Deploy Chaos Monkey](https://netflix.github.io/chaosmonkey/How-to-deploy/)
- [Chaos Monkey GitHub Repository](https://github.com/netflix/chaosmonkey)
- [Chaos Monkey Background in SimianArmy Wiki](https://github.com/Netflix/SimianArmy/wiki/Chaos-Monkey)

## Cloud Provider Chaos Engineering

### AWS Fault Injection Service

AWS FIS is a managed fault-injection service for AWS workloads.

- [AWS Fault Injection Service Documentation](https://docs.aws.amazon.com/fis/)
- [What is AWS FIS?](https://docs.aws.amazon.com/fis/latest/userguide/what-is.html)
- [AWS FIS Tutorials](https://docs.aws.amazon.com/fis/latest/userguide/fis-tutorials.html)
- [AWS FIS Actions Reference](https://docs.aws.amazon.com/fis/latest/userguide/fis-actions-reference.html)
- [AWS Resilience Hub and FIS Testing](https://docs.aws.amazon.com/resilience-hub/latest/userguide/testing.html)

### Azure Chaos Studio

Azure Chaos Studio is Microsoft’s managed chaos engineering platform for Azure services and workloads.

- [Azure Chaos Studio Documentation](https://learn.microsoft.com/en-us/azure/chaos-studio/)
- [Azure Chaos Studio Overview](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-overview)
- [Azure Chaos Studio Tutorials](https://learn.microsoft.com/en-us/azure/chaos-studio/)
- [Azure Chaos Studio Faults and Targets](https://learn.microsoft.com/en-us/azure/chaos-studio/)
- [Azure Chaos Studio Virtual Network Injection](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-private-networking)

## Good Focus Areas

When studying chaos engineering, focus on these ideas:

### Experiment Design

- define a steady state
- form a hypothesis
- inject one controlled variable at a time
- measure impact
- stop safely if the blast radius is wrong

### Reliability Signals

- availability
- latency
- error rate
- saturation
- recovery time
- alert quality
- rollback behavior

### Operational Safety

- guardrails
- blast-radius control
- experiment scopes
- safe abort conditions
- runbooks
- approvals
- observability coverage

### Platform Engineering Context

- Kubernetes pod and node failures
- network latency and partitioning
- DNS failure
- dependency outage simulation
- CPU and memory stress
- storage disruption
- region or zone failure assumptions

## Suggested Learning Order

If you are learning chaos engineering from scratch, this order works well:

1. Principles of Chaos Engineering
2. Chaos Mesh overview
3. Litmus overview
4. Gremlin chaos engineering overview
5. Chaos Monkey basics
6. AWS Fault Injection Service
7. Azure Chaos Studio
8. experiment design and safety guardrails
9. continuous resilience validation in CI/CD and platform workflows

## Practical Study Path for Kubernetes and Platform Engineering

If your main goal is platform reliability, use this order:

1. Principles of Chaos Engineering
2. Chaos Mesh
3. Litmus
4. Kubernetes observability and alerting
5. AWS FIS or Azure Chaos Studio if you are cloud-specific
6. incident response and postmortem practice
7. automation of recurring resilience tests

## Videos

### Official and High-Value Videos

- [Gremlin YouTube Channel](https://www.youtube.com/@Gremlin)
- [Gremlin Chaos Engineering Playlist](https://www.youtube.com/playlist?list=PLLIx5ktghjqKGCCcYXQb9leb5zhlXvE0r)
- [Chaos Mesh YouTube Channel](https://www.youtube.com/channel/UC4OwT4QTd0ML3YNnV1ybT6g)
- [Chaos Mesh: Introducing Chaos in Kubernetes](https://www.youtube.com/watch?v=F0C1LK549xg)
- [Chaos Mesh 2.0](https://www.youtube.com/watch?v=HmQ9cFwxF7g)
- [LitmusChaos YouTube Channel](https://www.youtube.com/@litmuschaos)
- [Getting Started with LitmusChaos](https://www.youtube.com/watch?v=FSNS5cxqPzc)
- [How to Create Chaos Experiments with Litmus](https://www.youtube.com/watch?v=mwu5eLgUKq4)
- [Azure Chaos Studio Overview Video](https://www.youtube.com/watch?v=IkEQm6m46Ow)
- [Azure Friday: An Introduction to Azure Chaos Studio](https://www.youtube.com/watch?v=pSEDDiWfnVY)

## Notes

A few practical habits make chaos engineering more useful:

- start small
- define success and failure before the experiment
- use good observability before injecting faults
- treat chaos experiments as learning tools, not stunts
- feed lessons back into architecture, alerting, runbooks, and recovery design
- repeat experiments after meaningful platform changes
