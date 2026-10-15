#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "Creating k3d cluster with 1 server, 3 agents..."
echo "=============================================="

k3d cluster create platform-cluster \
  --servers 1 \
  --agents 3 \
  --port 8080:80@loadbalancer \
  --k3s-arg "--disable=traefik@server:0"

echo "Waiting for cluster nodes to be ready..."
kubectl wait --for=condition=ready nodes --all --timeout=120s

echo "=============================================="
echo "Installing NGINX Ingress Controller..."
echo "=============================================="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "=============================================="
echo "Installing Argo Rollouts Controller..."
echo "=============================================="
kubectl create namespace argo-rollouts || true
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl wait --namespace argo-rollouts \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argo-rollouts \
  --timeout=120s

echo "=============================================="
echo "Installing KEDA..."
echo "=============================================="
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda --namespace keda --create-namespace

echo "=============================================="
echo "Deploying PostgreSQL and Redis..."
echo "=============================================="
kubectl create namespace datastores || true
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install postgres-postgresql bitnami/postgresql \
  --namespace datastores \
  --set auth.postgresPassword=devpassword

helm upgrade --install redis bitnami/redis \
  --namespace datastores \
  --set auth.password=devpassword \
  --set architecture=standalone

echo "=============================================="
echo "Cluster bootstrap complete!"
echo "Ingress mapped to: http://localhost:8080"
echo "=============================================="