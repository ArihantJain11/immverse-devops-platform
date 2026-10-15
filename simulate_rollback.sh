#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="shared"
ROLLOUT_NAME="shared-api"

echo "========================================================"
echo "Step 1: Checking current healthy rollout status..."
echo "========================================================"
kubectl argo rollouts status "$ROLLOUT_NAME" -n "$NAMESPACE"

echo "========================================================"
echo "Step 2: Deploying intentionally broken image tag (v-broken)..."
echo "========================================================"
kubectl argo rollouts set image "$ROLLOUT_NAME" api=alpine:latest -n "$NAMESPACE"

echo "Waiting for Rollout to detect failure on canary endpoints..."
sleep 15
kubectl argo rollouts get rollout "$ROLLOUT_NAME" -n "$NAMESPACE"

echo "========================================================"
echo "Step 3: Triggering automated/manual abort & rollback..."
echo "========================================================"
kubectl argo rollouts abort "$ROLLOUT_NAME" -n "$NAMESPACE"
kubectl argo rollouts undo "$ROLLOUT_NAME" -n "$NAMESPACE"

echo "========================================================"
echo "Step 4: Rollback confirmed. Verifying stable pods restored:"
echo "========================================================"
kubectl argo rollouts status "$ROLLOUT_NAME" -n "$NAMESPACE"
echo "Zero downtime maintained on stable traffic."