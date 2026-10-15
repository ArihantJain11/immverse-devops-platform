terraform {
  required_version = ">= 1.6.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "base_platform" {
  source = "../../modules/kubernetes_base"
}

module "tenant_shared" {
  source       = "../../modules/tenant_isolated"
  tenant_id    = "shared"
  region       = "local"
  cpu_quota    = "8"
  memory_quota = "16Gi"
}