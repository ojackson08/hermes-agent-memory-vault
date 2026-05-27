# Hermes Agent Memory Vault (AWS Persistent Storage)

## The Problem
Hermes Agent is a powerful self-improving AI agent that learns from experience. However, its memory system (SQLite FTS5 for session search, `MEMORY.md` for prompt memory, and local markdown files for skills) is entirely **local to the filesystem**. If the server crashes, the container restarts, or you want to run a swarm of Hermes agents across multiple machines, that memory is siloed or lost.

## The Solution
This project provides a cloud-native, infinitely scalable memory vault for Hermes Agent using AWS infrastructure. 

By pointing Hermes to this API Gateway endpoint, all memory updates are automatically synced to the cloud:
- **Prompt Memory (`MEMORY.md`/`USER.md`) & Skill Metadata** are stored in **Amazon DynamoDB** for sub-millisecond retrieval.
- **Procedural Memory (Skill `.md` files) & Episodic Memory (SQLite Session Archives)** are stored in **Amazon S3** with versioning enabled.

## Architecture
1. **Amazon API Gateway:** Provides a RESTful endpoint for the Hermes Agent to push memory updates.
2. **AWS Lambda (Python/Boto3):** Processes the incoming payloads and routes them to the correct storage backend based on memory type.
3. **Amazon DynamoDB:** Stores structured metadata and prompt memory text.
4. **Amazon S3:** Stores raw markdown skill files and SQLite database backups.
5. **Terraform:** Provisions the entire infrastructure as code.

## Business Impact
- **Agent Resilience:** Hermes can survive container restarts and server wipes without losing its learned skills or context.
- **Multi-Agent Sync:** Multiple Hermes instances can pull from the same cloud memory vault, sharing learned skills across a fleet.
- **Infinite Scalability:** Offloads heavy SQLite session archives to cheap S3 storage rather than filling up local EBS volumes.
