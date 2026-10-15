# Architecture Decision Document

## 1. High-Level Diagram

[ Clients / Load Balancer ]
|
[ NGINX / ALB Controller ]
/

[ API Canary (10%) ]     [ API Stable (90%) ]
\                 /
[ PgBouncer Connection Pool ]
|
[ PostgreSQL Aurora ]
^
| (Tasks)
[ Redis Cluster ]
|
[ Asynchronous Workers (KEDA Scaled) ]

## 2. Five Architectural Decisions & Rejected Alternatives

1. **Deployment Strategy: Argo Rollouts Canary vs. Blue/Green**
   - *Choice:* Argo Rollouts Canary with automated metric queries.
   - *Rejected Alternative:* Pure Blue/Green. Blue/Green requires doubling full capacity upfront (instantly incurring duplicate instance costs) and offers all-or-nothing traffic exposure without incremental confidence sampling.

2. **Infrastructure as Code: Terraform vs. Pulumi**
   - *Choice:* Terraform/OpenTofu with decoupled provider layers.
   - *Rejected Alternative:* Pulumi. Terraform has the broadest cross-cloud provider maturity, clearer static drift detection, and native GitOps tooling integration across standard CI platforms.

3. **Autoscaling: KEDA vs. Native Custom Metric Server**
   - *Choice:* KEDA (Kubernetes Event-driven Autoscaling).
   - *Rejected Alternative:* Prometheus Adapter with generic HPA. KEDA provides native out-of-the-box Redis list triggers without needing to write custom Prometheus recording rules for worker queue depths.

4. **Database Connection Management: PgBouncer vs. Direct Connection**
   - *Choice:* PgBouncer connection pooler in transaction pooling mode.
   - *Rejected Alternative:* Direct microservice database connections. 55 API pods + 40 worker pods with multiple concurrent threads easily exceed PostgreSQL's max client connection threshold and exhaust memory.

5. **Multi-Tenancy Isolation: Soft Namespaces + NetworkPolicy vs. Dedicated Clusters**
   - *Choice:* Virtual tenant isolation via Kubernetes Namespaces, dedicated schemas/instances, and strict NetworkPolicies.
   - *Rejected Alternative:* Dedicated EKS cluster per tenant. Provisioning separate control planes per tenant exceeds the $9,000 baseline budget and violates the 30-minute provisioning target.

## 3. Top 5 Architectural Risks & Mitigations

1. **Non-Backward-Compatible Migrations Running on Boot**
   - *Risk:* Pod restarts running newer DDL lock out or break active older replicas.
   - *Mitigation:* Decouple migrations from app startup containers into dedicated pre-deployment Helm hook jobs adopting the Expand/Contract (parallel column) pattern.
2. **Worker Interruption During Long-Running Tasks (60s)**
   - *Risk:* Pod scaledown kills jobs mid-execution, losing queue progress.
   - *Mitigation:* `terminationGracePeriodSeconds` set to 70 seconds combined with SIGTERM trap handling that stops pulling from Redis and completes active tasks.
3. **EU Data Residency Breaches**
   - *Risk:* Cross-region replication or centralized logging routes EU PII to non-EU regions.
   - *Mitigation:* Pinned node selectors (`topology.kubernetes.io/region: eu-west-1`), regional log sinks, and egress network policies.
4. **Sudden 15x Traffic Spikes Causing Node Throttling**
   - *Risk:* Pods stay in `Pending` waiting for new cluster nodes to spin up.
   - *Mitigation:* Overprovisioning dummy "balloon" pods with low priority class to hold warm headroom, coupled with Karpenter sub-minute EC2 provisioning.
5. **Cascading Redis Failure**