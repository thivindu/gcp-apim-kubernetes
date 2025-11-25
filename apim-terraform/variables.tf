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

variable "project_id" {
  type        = string
  description = "GCP project id"
  default     = "wso2-marketplace-public"
}

variable "region" {
  description = "The GCP region for the cluster"
  type        = string
  default     = "us-east1"
}

variable "create_cluster_service_account" {
  type    = bool
  default = false
}

variable "cluster_service_account" {
  type    = string
  default = ""
}

# Helm

variable "helm_release_name" {
  type    = string
  default = "apim"
}

variable "helm_chart_repo" {
  type        = string
  description = "Helm chart repository URL. Leave empty for local charts."
  default     = "oci://us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"
}

variable "helm_chart_name" {
  type        = string
  description = "Helm chart name (for remote repos) or path to local chart directory"
  default     = "wso2-apim"
}

variable "helm_chart_version" {
  type        = string
  description = "Helm chart version. Leave empty for local charts."
  default     = "4.5"
}

# GKE

variable "kubernetes_version" {
  type    = string
  default = "1.32"
}

variable "cluster_name" {
  type    = string
  default = "wso2-apim"
}

variable "cluster_location" {
  type    = string
  default = "us-east1"
}

variable "create_cluster" {
  type    = bool
  default = true
}

variable "cpu_pools" {
  type = list(map(any))
  default = [{
    name         = "cpu-pool"
    machine_type = "n1-standard-16"
    autoscaling  = true
    min_count    = 1
    max_count    = 3
    disk_size_gb = 100
    disk_type    = "pd-standard"
  }]
}

variable "enable_gpu" {
  type        = bool
  description = "Set to true to create GPU node pool"
  default     = false
}

variable "gpu_pools" {
  type    = list(map(any))
  default = []
}

variable "enable_tpu" {
  type        = bool
  description = "Set to true to create TPU node pool"
  default     = false
}

variable "tpu_pools" {
  type    = list(map(any))
  default = []
}

variable "ip_range_pods" {
  type    = string
  default = ""
}

variable "ip_range_services" {
  type    = string
  default = ""
}

variable "network_name" {
  type    = string
  default = "default"
}

variable "subnetwork_name" {
  type    = string
  default = "default"
}

variable "subnetwork_region" {
  type    = string
  default = "us-east1"
}

# TODO: Add variables for your app, including images and other customizable values

# ACP Image Variables
variable "acp_image_registry" {
  type        = string
  description = "Registry for WSO2 APIM ACP image"
  default     = "us-docker.pkg.dev"
}

variable "acp_image_repo" {
  type        = string
  description = "Repository path for WSO2 APIM ACP image"
  default     = "wso2-marketplace-public/wso2-marketplace/wso2am-acp"
}

variable "acp_image_tag" {
  type        = string
  description = "Tag for WSO2 APIM ACP image"
  default     = "4.5"
}

# APK Config Deployer Image Variables
variable "apk_config_deployer_image_registry" {
  type        = string
  description = "Registry for APK Config Deployer image"
  default     = "us-docker.pkg.dev"
}

variable "apk_config_deployer_image_repo" {
  type        = string
  description = "Repository path for APK Config Deployer image"
  default     = "wso2-marketplace-public/wso2-marketplace/apk-config-deployer-service"
}

variable "apk_config_deployer_image_tag" {
  type        = string
  description = "Tag for APK Config Deployer image"
  default     = "4.5"
}

# APK Adapter Image Variables
variable "apk_adapter_image_registry" {
  type        = string
  description = "Registry for APK Adapter image"
  default     = "us-docker.pkg.dev"
}

variable "apk_adapter_image_repo" {
  type        = string
  description = "Repository path for APK Adapter image"
  default     = "wso2-marketplace-public/wso2-marketplace/apk-adapter"
}

variable "apk_adapter_image_tag" {
  type        = string
  description = "Tag for APK Adapter image"
  default     = "4.5"
}

# APK Common Controller Image Variables
variable "apk_common_controller_image_registry" {
  type        = string
  description = "Registry for APK Common Controller image"
  default     = "us-docker.pkg.dev"
}

variable "apk_common_controller_image_repo" {
  type        = string
  description = "Repository path for APK Common Controller image"
  default     = "wso2-marketplace-public/wso2-marketplace/apk-common-controller"
}

variable "apk_common_controller_image_tag" {
  type        = string
  description = "Tag for APK Common Controller image"
  default     = "4.5"
}

# APK Ratelimiter Image Variables
variable "apk_ratelimiter_image_registry" {
  type        = string
  description = "Registry for APK Ratelimiter image"
  default     = "us-docker.pkg.dev"
}

variable "apk_ratelimiter_image_repo" {
  type        = string
  description = "Repository path for APK Ratelimiter image"
  default     = "wso2-marketplace-public/wso2-marketplace/apk-ratelimiter"
}

variable "apk_ratelimiter_image_tag" {
  type        = string
  description = "Tag for APK Ratelimiter image"
  default     = "4.5"
}

# APK Router Image Variables
variable "apk_router_image_registry" {
  type        = string
  description = "Registry for APK Router image"
  default     = "us-docker.pkg.dev"
}

variable "apk_router_image_repo" {
  type        = string
  description = "Repository path for APK Router image"
  default     = "wso2-marketplace-public/wso2-marketplace/apk-router"
}

variable "apk_router_image_tag" {
  type        = string
  description = "Tag for APK Router image"
  default     = "4.5"
}

# APK Enforcer Image Variables
variable "apk_enforcer_image_registry" {
  type        = string
  description = "Registry for APK Enforcer image"
  default     = "us-docker.pkg.dev"
}

variable "apk_enforcer_image_repo" {
  type        = string
  description = "Repository path for APK Enforcer image"
  default     = "wso2-marketplace-public/wso2-marketplace/apk-enforcer"
}

variable "apk_enforcer_image_tag" {
  type        = string
  description = "Tag for APK Enforcer image"
  default     = "4.5"
}

# APK Agent Image Variables
variable "apk_agent_image_repo" {
  type        = string
  description = "Full repository path with registry for APK Agent image"
  default     = "us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apim-apk-agent"
}

variable "apk_agent_image_tag" {
  type        = string
  description = "Tag for APK Agent image"
  default     = "4.5"
}
