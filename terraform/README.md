# GKE Cluster with Helm Chart Deployment

This Terraform module deploys a Google Kubernetes Engine (GKE) cluster and installs a Helm chart on it.

## Features

- **GKE Cluster**: Creates a production-ready GKE cluster with:
  - VPC-native networking
  - Workload Identity
  - Managed node pools with autoscaling
  - Release channels for managed upgrades
  - Logging and monitoring integration
  - Shielded GKE nodes
  
- **Helm Deployment**: Deploys any Helm chart to the cluster with:
  - Custom values support
  - Namespace management
  - Sensitive values handling
  - Wait and timeout configurations

## Prerequisites

1. **Google Cloud SDK**: Install and authenticate
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Terraform**: Install Terraform >= 1.0

3. **Enable Required APIs**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

4. **GCP Project**: You need a GCP project with appropriate permissions

## Usage

### Basic Example

```hcl
module "gke_with_helm" {
  source = "./terraform"

  # GCP Configuration
  project_id = "your-project-id"
  region     = "us-central1"

  # GKE Cluster
  cluster_name = "my-gke-cluster"

  # Node Pool
  node_count     = 3
  min_node_count = 1
  max_node_count = 5
  machine_type   = "e2-medium"

  # Helm Chart
  helm_release_name = "nginx"
  helm_repository   = "https://charts.bitnami.com/bitnami"
  helm_chart        = "nginx"
  helm_namespace    = "web"
}
```

### With Custom VPC

```hcl
module "gke_with_helm" {
  source = "./terraform"

  project_id = "your-project-id"
  region     = "us-central1"

  cluster_name = "my-gke-cluster"
  
  # Custom VPC
  network             = "my-vpc-network"
  subnetwork          = "my-subnet"
  pods_range_name     = "gke-pods-range"
  services_range_name = "gke-services-range"

  # Helm Configuration
  helm_release_name  = "my-app"
  helm_repository    = "https://charts.example.com"
  helm_chart         = "my-app-chart"
  helm_chart_version = "1.0.0"
  helm_namespace     = "production"
  
  helm_set_values = [
    {
      name  = "image.tag"
      value = "v1.2.3"
    },
    {
      name  = "replicaCount"
      value = "3"
    }
  ]
}
```

### With Custom Values File

```hcl
module "gke_with_helm" {
  source = "./terraform"

  project_id   = "your-project-id"
  cluster_name = "my-cluster"

  helm_release_name = "my-app"
  helm_repository   = "https://charts.example.com"
  helm_chart        = "my-app"
  helm_namespace    = "production"
  
  helm_values_files = [
    "${path.module}/custom-values.yaml"
  ]
}
```

## Quick Start

1. **Clone this repository**

2. **Copy the example tfvars file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars`** with your configuration

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Review the plan**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

7. **Configure kubectl** (use the output command):
   ```bash
   gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
   ```

8. **Verify the deployment**:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   helm list -A
   ```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | The GCP project ID | string | - | yes |
| region | The GCP region for the cluster | string | us-central1 | no |
| cluster_name | The name of the GKE cluster | string | - | yes |
| helm_release_name | Name of the Helm release | string | - | yes |
| helm_repository | Helm chart repository URL | string | - | yes |
| helm_chart | Helm chart name | string | - | yes |

See `variables.tf` for all available inputs.

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | The name of the GKE cluster |
| cluster_endpoint | The endpoint of the GKE cluster |
| kubectl_config_command | Command to configure kubectl |
| helm_release_name | The name of the Helm release |
| helm_release_status | The status of the Helm release |

See `outputs.tf` for all available outputs.

## Examples

### Deploy NGINX Ingress Controller

```hcl
helm_release_name  = "nginx-ingress"
helm_repository    = "https://kubernetes.github.io/ingress-nginx"
helm_chart         = "ingress-nginx"
helm_chart_version = "4.8.3"
helm_namespace     = "ingress-nginx"
create_namespace   = true

helm_set_values = [
  {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
]
```

### Deploy cert-manager

```hcl
helm_release_name  = "cert-manager"
helm_repository    = "https://charts.jetstack.io"
helm_chart         = "cert-manager"
helm_chart_version = "v1.13.2"
helm_namespace     = "cert-manager"
create_namespace   = true

helm_set_values = [
  {
    name  = "installCRDs"
    value = "true"
  }
]
```

### Deploy Prometheus

```hcl
helm_release_name = "prometheus"
helm_repository   = "https://prometheus-community.github.io/helm-charts"
helm_chart        = "kube-prometheus-stack"
helm_namespace    = "monitoring"
create_namespace  = true
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Security Considerations

1. **Workload Identity**: This module enables Workload Identity for secure pod-to-GCP authentication
2. **Shielded Nodes**: Nodes are configured with secure boot and integrity monitoring
3. **Private Clusters**: Consider configuring private clusters for production
4. **Sensitive Values**: Use `helm_set_sensitive_values` for secrets
5. **Deletion Protection**: Enable `deletion_protection = true` in production

## Troubleshooting

### Authentication Issues

If you encounter authentication issues:
```bash
gcloud auth application-default login
gcloud config set project <project-id>
```

### Cluster Access

To access the cluster:
```bash
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
kubectl get nodes
```

### Helm Release Issues

Check Helm release status:
```bash
helm list -A
helm status <release-name> -n <namespace>
```

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
