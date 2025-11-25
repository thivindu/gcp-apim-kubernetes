# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "helm" {
  alias = "app"
  kubernetes {
    host                   = local.host
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = local.ca_certificate
  }
}

locals {
  # TODO: Change the prefix to your app name
  helm_release_name = var.helm_release_name != "" ? var.helm_release_name : "apim-${random_string.suffix.result}"
}

# Install nginx ingress controller first
resource "helm_release" "ingress_nginx" {
  provider = helm.app

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  create_namespace = true

  # Wait for the controller to be ready before proceeding
  wait          = true
  wait_for_jobs = true
  timeout       = 600 # 10 minutes

  depends_on = [
    module.gke
  ]
}

# Data source to verify ingress controller deployment is ready
data "kubernetes_service" "ingress_nginx_controller" {
  provider = kubernetes.app

  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.ingress_nginx
  ]
}

resource "helm_release" "primary" {
  provider = helm.app

  name = local.helm_release_name

  # For local charts, use the chart path directly (repository should be null or empty)
  # For remote charts, specify both repository and chart name
  repository = var.helm_chart_repo != "" ? var.helm_chart_repo : null
  chart      = var.helm_chart_name
  version    = var.helm_chart_version != "" ? var.helm_chart_version : null

  # Wait for ingress controller to be ready first
  depends_on = [
    data.kubernetes_service.ingress_nginx_controller
  ]

  # ACP Image Configuration
  # set {
  #   name  = "acp.wso2.deployment.image.registry"
  #   value = var.acp_image_registry
  # }

  # set {
  #   name  = "acp.wso2.deployment.image.repository"
  #   value = var.acp_image_repo
  # }

  # set {
  #   name  = "acp.wso2.deployment.image.digest"
  #   value = var.acp_image_digest
  # }
  set {
    name  = "acp.wso2.deployment.image"
    value = "${var.acp_image_registry}/${var.acp_image_repo}:${var.acp_image_tag}"
  }

  # APK Config Deployer Image
  set {
    name  = "apk.wso2.apk.dp.configdeployer.deployment.image"
    value = "${var.apk_config_deployer_image_registry}/${var.apk_config_deployer_image_repo}:${var.apk_config_deployer_image_tag}"
  }

  # APK Adapter Image
  set {
    name  = "apk.wso2.apk.dp.adapter.deployment.image"
    value = "${var.apk_adapter_image_registry}/${var.apk_adapter_image_repo}:${var.apk_adapter_image_tag}"
  }

  # APK Common Controller Image
  set {
    name  = "apk.wso2.apk.dp.commonController.deployment.image"
    value = "${var.apk_common_controller_image_registry}/${var.apk_common_controller_image_repo}:${var.apk_common_controller_image_tag}"
  }

  # APK Ratelimiter Image
  set {
    name  = "apk.wso2.apk.dp.ratelimiter.deployment.image"
    value = "${var.apk_ratelimiter_image_registry}/${var.apk_ratelimiter_image_repo}:${var.apk_ratelimiter_image_tag}"
  }

  # APK Router Image
  set {
    name  = "apk.wso2.apk.dp.gatewayRuntime.deployment.router.image"
    value = "${var.apk_router_image_registry}/${var.apk_router_image_repo}:${var.apk_router_image_tag}"
  }

  # APK Enforcer Image
  set {
    name  = "apk.wso2.apk.dp.gatewayRuntime.deployment.enforcer.image"
    value = "${var.apk_enforcer_image_registry}/${var.apk_enforcer_image_repo}:${var.apk_enforcer_image_tag}"
  }

  # APK Agent Image
  set {
    name  = "apkagent.image.repository"
    value = var.apk_agent_image_repo
  }

  set {
    name  = "apkagent.image.tag"
    value = var.apk_agent_image_tag
  }

  # Marketplace Configuration
  set {
    name  = "marketplace.serviceName"
    value = "wso2-apimanager.endpoints.wso2-marketplace-public.cloud.goog"
  }

  set {
    name  = "marketplace.serviceLevel"
    value = "default"
  }
}
