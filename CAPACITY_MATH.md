# Capacity Mathematics & Limits

## 1. API Compute Capacity

- **Baseline:** $150 \text{ req/s}$
- **Peak ($15\times$):** $2,250 \text{ req/s}$
- **Target p95 Latency:** $< 400\text{ ms}$

### Pod Sizing Derivation
Assume an average compute-bound request response duration of $50\text{ ms}$ per worker thread:
$$\text{Max Throughput per Pod} = \frac{1 \text{ core}}{0.05 \text{ s}} \approx 20 \text{ concurrent queries/sec} \approx 50 \text{ total req/s with I/O pipelining}$$

- **Baseline Pods:**
  $$\text{Replicas}_{\text{base}} = \frac{150 \text{ req/s}}{50 \text{ req/s/pod}} = 3 \text{ pods} \quad (\text{Allocated: } 4 \text{ for High Availability})$$
- **Peak Pods:**
  $$\text{Replicas}_{\text{peak}} = \frac{2,250 \text{ req/s}}{50 \text{ req/s/pod}} = 45 \text{ pods} \quad (\text{HPA ceiling set to } 55)$$

## 2. Worker Queue Sizing

- **Job Throughput:** $20,000 \text{ jobs/hour} \approx 5.56 \text{ jobs/sec}$
- **Max Execution Window:** Up to $60\text{ seconds}$ per job.
- **Concurrency (Little's Law):**
  $$L = \lambda \times W$$
  - At maximum duration ($W = 60\text{ s}$): $L = 5.56 \times 60 \approx 334 \text{ concurrent active jobs}$.
  - At standard duration ($W = 10\text{ s}$): $L = 5.56 \times 10 \approx 56 \text{ concurrent active jobs}$.
- **Baseline Worker Count:** 8 pods (each running concurrency pool of 8 jobs = 64 jobs concurrent capacity).
- **Peak Autoscaling:** If Redis queue length exceeds 500, KEDA scales worker instances up to 40 pods.

## 3. Database Connection Math

- $45 \text{ API Pods} \times 10 \text{ connections/pool} = 450 \text{ connections}$
- $40 \text{ Worker Pods} \times 5 \text{ connections/pool} = 200 \text{ connections}$
- **Total Unpooled Connections:** $650 \text{ connections}$
- PostgreSQL recommended connection ceiling for balanced memory: $\le 200 \text{ connections}$.
- **Solution:** PgBouncer configured with `pool_mode = transaction`, exposing 1,000 virtual connections while clamping backend database connections to 80.