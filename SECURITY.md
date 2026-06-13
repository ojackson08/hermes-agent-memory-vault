# Security Policy

## About This Project

`hermes-agent-memory-vault` is a **secure persistent memory backend** for AI agents, developed by Merkaba AI Risk Management. It stores agent memory, learned skills, and shared knowledge across DynamoDB and S3. As a system that may store sensitive information from agent operations, its security is critical.

## Supported Versions

| Version | Supported |
|---|---|
| Current main | Yes |

## Reporting a Vulnerability

If you discover a security vulnerability in `hermes-agent-memory-vault` — including cross-agent memory namespace bypass, unencrypted storage paths, API Gateway authentication weaknesses, or IAM privilege escalation — **please do not open a public GitHub issue.**

Report vulnerabilities directly to:

**Email:** security@merkabacreatives.org
**Subject line:** `[SECURITY] hermes-agent-memory-vault — <brief description>`

We will acknowledge receipt within **48 hours** and provide a remediation timeline within **5 business days**.

## Security Design Notes

- All memory data is encrypted at rest: S3 SSE-KMS and DynamoDB encryption enabled.
- Memory namespaces are isolated by IAM policy — agents cannot access other agents' memory by default.
- Cross-agent memory sharing requires explicit allowlist configuration.
- DynamoDB TTL is configured to automatically expire sensitive data after a configurable retention period.
- All memory read/write operations are logged via CloudTrail.
- API Gateway endpoints require IAM authentication; no unauthenticated access is permitted.

## Responsible Disclosure

We follow coordinated disclosure. We ask that you give us reasonable time to investigate and patch before public disclosure.

## Contact

Merkaba AI Risk Management
security@merkabacreatives.org
https://merkabacreatives.org/ai-risk
