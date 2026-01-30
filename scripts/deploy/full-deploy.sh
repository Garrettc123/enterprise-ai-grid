#!/bin/bash
# Full deployment script for Enterprise AI Grid

set -e

echo "🚀 Starting Enterprise AI Grid Deployment..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform required"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI required"; exit 1; }

# 1. Deploy Infrastructure
echo "📦 Deploying infrastructure..."
cd infrastructure/terraform/environments/production
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 2. Configure kubectl
echo "⚙️ Configuring kubectl..."
aws eks update-kubeconfig --name enterprise-ai-grid --region us-east-1

# 3. Deploy Kubernetes resources
echo "☸️ Deploying Kubernetes resources..."
kubectl apply -f infrastructure/kubernetes/base/
kubectl apply -f infrastructure/kubernetes/apps/

# 4. Wait for rollout
echo "⏳ Waiting for services to be ready..."
kubectl rollout status deployment -n enterprise-ai-grid --timeout=10m

# 5. Deploy monitoring
echo "📊 Deploying monitoring stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace

echo "✅ Deployment complete!"
echo "🌐 Access your cluster:"
kubectl get svc -n enterprise-ai-grid
