# Namespace definition
resource "kubernetes_namespace" "weather" {
  metadata {
    name = "weather"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# RBAC configuration
resource "kubernetes_service_account" "weather_app" {
  metadata {
    name      = "weather-app-sa"
    namespace = kubernetes_namespace.weather.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "weather_app" {
  metadata {
    name = "weather-app-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "weather_app" {
  metadata {
    name = "weather-app-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.weather_app.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.weather_app.metadata[0].name
    namespace = kubernetes_namespace.weather.metadata[0].name
  }
}

# Storage Class
resource "kubernetes_storage_class" "weather_storage" {
  metadata {
    name = var.storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = var.storage_class_provisioner
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"
}

# Ingress Controller (Nginx for local and standard environments)
resource "helm_release" "ingress_nginx" {
  count            = var.ingress_class_name == "nginx" ? 1 : 0
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
}

# Monitoring (Prometheus & Grafana)
resource "helm_release" "prometheus_stack" {
  name             = "prometheus-community"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelix"
    value = "false"
  }
}

# ArgoCD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}

# Application Helm Release
resource "helm_release" "weather_platform" {
  name      = "weather-platform"
  chart     = "${path.module}/../../../helm/weather-platform"
  namespace = kubernetes_namespace.weather.metadata[0].name

  values = var.helm_values_file != "" ? [file(var.helm_values_file)] : []

  set {
    name  = "secrets.groqApiKey"
    value = var.groq_api_key
  }

  set {
    name  = "image.repository"
    value = var.docker_image_repository
  }

  set {
    name  = "image.tag"
    value = var.docker_image_tag
  }

  set {
    name  = "monitoring.enabled"
    value = "true"
  }

  depends_on = [
    helm_release.prometheus_stack,
    kubernetes_storage_class.weather_storage
  ]
}
