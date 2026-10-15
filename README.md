# immverse-devops-platform
Design and build an automated platform that provisions infrastructure on any cloud provider, deploys an application through multi-stage pipelines with zero downtime, and scales automatically to peak load. Both a shared environment and dedicated per-tenant environments must be supported.


```markdown
# Cloud-Agnostic Zero-Downtime Deployment Platform

Production-ready platform provisioning, GitOps deployment, and autoscaling engine for high-throughput APIs and background workers.

## Quickstart (Local Test Environment)

### Prerequisites
- Docker Engine
- `k3d`
- `kubectl`
- `helm`
- `k6`

### 1. Launch Local Cluster & Core Services
```bash
./scripts/setup_local_cluster.sh

### 2. Apply Platform Resources
helm upgrade --install shared gitops/shared-cluster/chart \
  --namespace shared \
  --create-namespace \
  -f gitops/shared-cluster/chart/values.yaml

### 3. Run Verification Tests
Autoscaling Test (150 -> 2,250 req/s):
./scripts/run_15x_load_test.sh

Automated Rollback Test:
./scripts/simulate_rollback.sh

### Auxiliary File: `Dockerfile.mock`
(Used by `.github/workflows/ci-artifact.yaml` for container packaging tests)
```dockerfile
FROM alpine:3.19
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["sh", "-c", "echo 'Platform service running'; sleep 3600"]
