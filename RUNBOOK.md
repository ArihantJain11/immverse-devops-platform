# Operational Runbooks

## Runbook 1: Manual Worker Queue Draining

### Context
Required when updating the worker deployment or performing maintenance on Redis without losing in-flight jobs.

### Steps
1. Scale down incoming ingestion to queue (if possible) or hold publisher traffic:
   ```bash
   kubectl scale rollout shared-api --replicas=0 -n shared # ONLY during maintenance window