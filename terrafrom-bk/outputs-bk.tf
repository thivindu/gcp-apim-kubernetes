# Outputs for GKE cluster and Helm deployment

# GKE Cluster Outputs
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_master_version" {
  description = "The Kubernetes master version of the GKE cluster"
  value       = google_container_cluster.primary.master_version
}

output "cluster_node_version" {
  description = "The Kubernetes node version of the GKE cluster"
  value       = google_container_node_pool.primary_nodes.version
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "cluster_zones" {
  description = "The zones in which the cluster is running"
  value       = data.google_compute_zones.available.names
}

# Kubectl config command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}

# Helm Release Outputs
output "helm_release_name" {
  description = "The name of the Helm release"
  value       = helm_release.application.name
}

output "helm_release_namespace" {
  description = "The namespace of the Helm release"
  value       = helm_release.application.namespace
}

output "helm_release_version" {
  description = "The version of the Helm release"
  value       = helm_release.application.version
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = helm_release.application.status
}

output "helm_chart" {
  description = "The Helm chart name"
  value       = helm_release.application.chart
}

output "helm_release_metadata" {
  description = "The metadata of the Helm release"
  value       = helm_release.application.metadata
}
