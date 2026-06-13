# Hermes Agent Memory Vault

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AWS](https://img.shields.io/badge/AWS-DynamoDB%20%7C%20S3%20%7C%20Lambda-orange.svg)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/security-secure--agent--memory-red.svg)](https://github.com/ojackson08/hermes-agent-memory-vault)
[![Maintained by Merkaba AI Risk](https://img.shields.io/badge/maintained%20by-Merkaba%20AI%20Risk-blueviolet)](https://merkabacreatives.org/ai-risk)

**Cloud-native, secure persistent memory backend for AI agents — enables multi-agent swarms to share learned skills and survive infrastructure failures.**

---

## Overview

`hermes-agent-memory-vault` provides a production-grade persistent memory layer for AI agents. API Gateway and Lambda intercept agent memory save operations and sync them to DynamoDB (metadata and fast lookups) and S3 (raw memory files and embeddings). This enables multi-agent swarms to share learned knowledge, maintain context across sessions, and recover from infrastructure failures without memory loss.

From a security perspective, the Vault is a critical component: it controls what agents remember, what they can access from shared memory, and ensures that sensitive information written to memory is encrypted and access-controlled.

---

## Architecture

```
Agent (memory save request)
    │
    ▼
API Gateway
    │
    ▼
Lambda (memory interceptor)
    ├── Metadata → DynamoDB (fast lookup, TTL support)
    └── Raw memory / embeddings → S3 (encrypted, versioned)

Agent (memory read request)
    │
    ▼
API Gateway → Lambda → DynamoDB lookup → S3 fetch
    │
    ▼
Return memory to agent
```

---

## Security Properties

| Property | Implementation |
|---|---|
| **Encryption at rest** | S3 SSE-KMS + DynamoDB encryption |
| **Access control** | IAM per-agent roles with memory namespace isolation |
| **Memory namespace isolation** | Agents can only access their own namespace by default |
| **Audit logging** | All memory reads/writes logged via CloudTrail |
| **TTL and expiry** | DynamoDB TTL prevents stale sensitive data accumulation |
| **Cross-agent sharing** | Explicit allowlist required for shared memory access |

---

## Deployment

```bash
cd terraform/
terraform init
terraform apply
```

---

## Case Study / Usage Notes

**Deployment at Merkaba AI Risk Management:**

The Hermes Agent Memory Vault is deployed as the memory backend for Merkaba's internal multi-agent security audit system. During a red team exercise, the security team attempted to use a compromised agent to read memory from a neighboring agent's namespace. The IAM namespace isolation policy blocked the cross-namespace read and generated a CloudTrail alert within 8 seconds. The vault's TTL configuration also ensures that client data written to agent memory during engagements is automatically purged after 30 days, supporting data minimization compliance requirements.

---

## Integration with Merkaba Security Stack

- [`agenthandoff`](https://github.com/ojackson08/agenthandoff) — Complementary state transfer for ephemeral handoff context
- [`merka-prompt-shield`](https://github.com/ojackson08/merka-prompt-shield) — Sanitize inputs before writing to memory
- [`agent-security-scanner`](https://github.com/ojackson08/agent-security-scanner) — Audit memory store configurations for security gaps
- [`ai-codebase-audit-engine`](https://github.com/ojackson08/ai-codebase-audit-engine) — Uses Hermes for cross-agent audit state persistence

---

## License

MIT License — see [LICENSE](./LICENSE) for details.

---

## Contact

**Merkaba AI Risk Management**
security@merkabacreatives.org
https://merkabacreatives.org/ai-risk
*Atlanta, GA — Remote Worldwide*
