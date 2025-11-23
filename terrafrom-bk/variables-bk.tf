# Variables for GKE cluster and Helm deployment

# GCP Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

# GKE Cluster Configuration
variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "network" {
  description = "The VPC network to host the cluster"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster"
  type        = string
  default     = "default"
}

variable "pods_range_name" {
  description = "The name of the secondary range for pods"
  type        = string
  default     = "pods"
}

variable "services_range_name" {
  description = "The name of the secondary range for services"
  type        = string
  default     = "services"
}

variable "release_channel" {
  description = "The release channel of the GKE cluster"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (in UTC)"
  type        = string
  default     = "03:00"
}

variable "enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Service for Prometheus"
  type        = bool
  default     = false
}

variable "enable_autopilot" {
  description = "Enable Autopilot mode for GKE cluster"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "cluster_resource_limits" {
  description = "Resource limits for cluster autoscaling"
  type = list(object({
    resource_type = string
    minimum       = number
    maximum       = number
  }))
  default = []
}

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = true
}

# Node Pool Configuration
variable "node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 10
}

variable "machine_type" {
  description = "The machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Disk type for nodes"
  type        = string
  default     = "pd-standard"
}

variable "preemptible_nodes" {
  description = "Use preemptible nodes"
  type        = bool
  default     = false
}

variable "node_labels" {
  description = "Labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags to apply to nodes"
  type        = list(string)
  default     = []
}

# Helm Configuration
variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
}

variable "helm_repository" {
  description = "Helm chart repository URL"
  type        = string
}

variable "helm_chart" {
  description = "Helm chart name"
  type        = string
}

variable "helm_chart_version" {
  description = "Helm chart version"
  type        = string
  default     = ""
}

variable "helm_namespace" {
  description = "Kubernetes namespace for Helm release"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "helm_values_files" {
  description = "List of values files for Helm chart"
  type        = list(string)
  default     = []
}

variable "helm_set_values" {
  description = "Set values for Helm chart"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "helm_set_sensitive_values" {
  description = "Set sensitive values for Helm chart"
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "helm_wait" {
  description = "Wait for Helm release to complete"
  type        = bool
  default     = true
}

variable "helm_timeout" {
  description = "Timeout for Helm operations (in seconds)"
  type        = number
  default     = 300
}

variable "helm_force_update" {
  description = "Force Helm resource update"
  type        = bool
  default     = false
}

variable "helm_recreate_pods" {
  description = "Recreate pods on Helm update"
  type        = bool
  default     = false
}
