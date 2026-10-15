variable "tenant_id" {
  type        = string
  description = "Unique alphanumeric identifier for the tenant"
}

variable "region" {
  type        = string
  description = "Target deployment region (e.g., eu-west-1, us-east-1)"
}

variable "cpu_quota" {
  type    = string
  default = "16"
}

variable "memory_quota" {
  type    = string
  default = "32Gi"
}

resource "kubernetes_namespace" "tenant" {
  metadata {
    name = "tenant-${var.tenant_id}"
    labels = {
      "tenant"         = var.tenant_id
      "region"         = var.region
      "data-residency" = var.region == "eu-central-1" || var.region == "eu-west-1" ? "EU-STRICT" : "GLOBAL"
    }
  }
}

resource "kubernetes_resource_quota" "tenant_quota" {
  metadata {
    name      = "tenant-quota"
    namespace = kubernetes_namespace.tenant.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = var.cpu_quota
      "requests.memory" = var.memory_quota
      "limits.cpu"      = tostring(tonumber(var.cpu_quota) * 2)
      "limits.memory"   = tostring(tonumber(regex("[0-9]+", var.memory_quota)) * 2) + "Gi"
      "pods"            = "60"
    }
  }
}

resource "kubernetes_network_policy" "tenant_isolation" {
  metadata {
    name      = "default-deny-cross-tenant"
    namespace = kubernetes_namespace.tenant.metadata[0].name
  }
  spec {
    pod_selector {}
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }
      from {
        pod_selector {} # allow intra-namespace
      }
    }
    policy_types = ["Ingress"]
  }
}