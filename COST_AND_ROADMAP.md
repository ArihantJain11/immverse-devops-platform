# Infrastructure Budget and 90-Day Plan

## 1. Cost Breakdown (Baseline vs. Peak)

| Service | Baseline ($150\text{ req/s}$) | Peak ($2,250\text{ req/s}$) | Sizing Specs |
|---|---|---|---|
| AWS EKS Cluster (Control Plane) | $73 | $73 | Managed control plane |
| EC2 Node Compute (API & Worker) | $420 | $1,850 | Mix of `m6i.large` and Spot `m6i.xlarge` |
| AWS RDS Aurora PostgreSQL | $520 | $2,400 | `db.r6g.xlarge` to `db.r6g.4xlarge` |
| AWS ElastiCache Redis | $180 | $720 | `cache.m6g.large` Multi-AZ |
| Network Data Transfer & NAT | $350 | $2,800 | VPC Endpoints for S3/ECR to minimize NAT |
| Dedicated Tenant Stacks (3 Stacks) | $2,100 | $4,500 | Compute + storage partitioning |
| Observability & Telemetry | $800 | $1,600 | Self-hosted Prometheus/Thanos |
| **Total Monthly Spend** | **$4,443 / mo** | **$13,943 / mo** | **Within $9k base & $16k peak budget** |

## 2. 90-Day Implementation Roadmap

### Phase 1: Days 1 to 30 — Core Foundations & GitOps
- Automated terraform modules for local and cloud environments.
- Drift detection workflows in GitHub Actions.
- Single-command cluster bootstrap with Bitnami services and Argo Rollouts.

### Phase 2: Days 31 to 60 — Autoscaling & Zero Downtime Resilience
- Argo Rollouts Canary deployment configuration with automated Prometheus rollback hooks.
- KEDA integration for Redis queue autoscaling.
- Enforce pre-stop hooks and termination grace periods for worker draining.
- Automated Expand/Contract database migration pipelines.

### Phase 3: Days 61 to 90 — Multi-Tenancy & Disaster Recovery
- Self-service tenant provisioning via declarative GitOps templates (< 30 min SLA).
- Cross-region disaster recovery drills (failover within 10 minutes RTO, zero RPO data loss).
- Compliance and security auditing for EU data boundary isolation.