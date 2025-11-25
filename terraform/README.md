# Terraform K8s App Starter

# WSO2 APIM on GKE - Terraform Configuration

This Terraform configuration deploys WSO2 API Manager (APIM) on Google Kubernetes Engine (GKE) using Helm charts.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Files](#configuration-files)
- [Configuration Variables](#configuration-variables)
  - [GCP Configuration](#gcp-configuration)
  - [GKE Cluster Configuration](#gke-cluster-configuration)
  - [Node Pool Configuration](#node-pool-configuration)
  - [Networking Configuration](#networking-configuration)
  - [Helm Configuration](#helm-configuration)
  - [Container Images Configuration](#container-images-configuration)
- [Usage Examples](#usage-examples)
- [Deployment](#deployment)

## Prerequisites

- Terraform >= 1.0
- gcloud CLI configured with appropriate credentials
- kubectl installed
- Helm 3.x installed
- GCP project with billing enabled
- Appropriate IAM permissions

## Quick Start

1. **Copy the example configuration file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   > 📋 The `terraform.tfvars.example` file contains all available variables with descriptions and examples for different deployment scenarios.

2. **Edit `terraform.tfvars` with your values:**
   ```bash
   # Edit with your preferred editor
   vim terraform.tfvars
   # or
   nano terraform.tfvars
   ```
   At minimum, update:
   - `project_id`: Your GCP project ID
   - `cluster_name`: Desired cluster name
   - `region` and `cluster_location`: Your preferred GCP region

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the planned changes:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Get cluster credentials:**
   ```bash
   gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
   ```

## Configuration Files

### terraform.tfvars.example

The `terraform.tfvars.example` file provides a comprehensive template with:
- ✅ All available variables with descriptions
- ✅ Default values and recommended settings
- ✅ Inline comments explaining each option
- ✅ Example configurations for different scenarios:
  - Development environment (cost-optimized)
  - Production environment (high availability)
  - Using existing GKE cluster
  - Custom image registries

**Key sections in the example file:**
- **GCP Configuration**: Project, region, and service accounts
- **GKE Cluster Configuration**: Cluster name, location, and Kubernetes version
- **Node Pool Configuration**: Machine types, autoscaling, and disk settings
- **Networking Configuration**: VPC, subnets, and IP ranges
- **Helm Configuration**: Chart repository and version settings
- **Container Images Configuration**: All 8 WSO2 component images

> 💡 **Tip**: Review the example file before making changes to understand all available options.

## Configuration Variables

### GCP Configuration

#### `project_id`
- **Type**: `string`
- **Description**: GCP project ID where resources will be created
- **Default**: `"wso2-marketplace-public"`
- **Example**:
```hcl
project_id = "my-gcp-project-123"
```

#### `region`
- **Type**: `string`
- **Description**: The GCP region for the cluster and resources
- **Default**: `"us-east1"`
- **Available Regions**: `us-east1`, `us-west1`, `europe-west1`, `asia-southeast1`, etc.
- **Example**:
```hcl
region = "us-central1"
```

#### `create_cluster_service_account`
- **Type**: `bool`
- **Description**: Whether to create a new service account for the cluster
- **Default**: `false`
- **Example**:
```hcl
create_cluster_service_account = true
```

#### `cluster_service_account`
- **Type**: `string`
- **Description**: Email of existing service account to use (if not creating new one)
- **Default**: `""`
- **Example**:
```hcl
cluster_service_account = "gke-service-account@my-project.iam.gserviceaccount.com"
```

---

### GKE Cluster Configuration

#### `cluster_name`
- **Type**: `string`
- **Description**: Name of the GKE cluster to create
- **Default**: `"wso2-apim"`
- **Example**:
```hcl
cluster_name = "production-apim-cluster"
```

#### `cluster_location`
- **Type**: `string`
- **Description**: The location (region or zone) for the GKE cluster
- **Default**: `"us-east1"`
- **Example**:
```hcl
# Regional cluster (recommended for production)
cluster_location = "us-central1"

# Zonal cluster (for development/testing)
cluster_location = "us-central1-a"
```

#### `create_cluster`
- **Type**: `bool`
- **Description**: Whether to create a new GKE cluster or use existing one
- **Default**: `true`
- **Example**:
```hcl
# Create new cluster
create_cluster = true

# Use existing cluster
create_cluster = false
```

#### `kubernetes_version`
- **Type**: `string`
- **Description**: Kubernetes version for the cluster
- **Default**: `"1.32"`
- **Example**:
```hcl
kubernetes_version = "1.30"
```

---

### Node Pool Configuration

#### `cpu_pools`
- **Type**: `list(map(any))`
- **Description**: Configuration for CPU-based node pools
- **Default**:
```hcl
cpu_pools = [{
  name         = "cpu-pool"
  machine_type = "n1-standard-16"
  autoscaling  = true
  min_count    = 1
  max_count    = 3
  disk_size_gb = 100
  disk_type    = "pd-standard"
}]
```
- **Example - Development Environment**:
```hcl
cpu_pools = [{
  name         = "dev-pool"
  machine_type = "e2-medium"
  autoscaling  = true
  min_count    = 1
  max_count    = 3
  disk_size_gb = 50
  disk_type    = "pd-standard"
}]
```
- **Example - Production Environment**:
```hcl
cpu_pools = [
  {
    name         = "app-pool"
    machine_type = "n1-standard-16"
    autoscaling  = true
    min_count    = 3
    max_count    = 10
    disk_size_gb = 200
    disk_type    = "pd-ssd"
  },
  {
    name         = "worker-pool"
    machine_type = "n1-standard-8"
    autoscaling  = true
    min_count    = 2
    max_count    = 5
    disk_size_gb = 100
    disk_type    = "pd-standard"
  }
]
```

**Machine Type Reference**:
- `e2-medium`: 2 vCPU, 4GB RAM (development)
- `n1-standard-4`: 4 vCPU, 15GB RAM (small workloads)
- `n1-standard-8`: 8 vCPU, 30GB RAM (medium workloads)
- `n1-standard-16`: 16 vCPU, 60GB RAM (production)

#### `enable_gpu`
- **Type**: `bool`
- **Description**: Set to true to create GPU node pools
- **Default**: `false`
- **Example**:
```hcl
enable_gpu = true
```

#### `gpu_pools`
- **Type**: `list(map(any))`
- **Description**: Configuration for GPU-based node pools
- **Default**: `[]`
- **Example**:
```hcl
enable_gpu = true

gpu_pools = [{
  name         = "gpu-pool"
  machine_type = "n1-standard-4"
  gpu_type     = "nvidia-tesla-t4"
  gpu_count    = 1
  autoscaling  = true
  min_count    = 0
  max_count    = 2
  disk_size_gb = 100
  disk_type    = "pd-standard"
}]
```

#### `enable_tpu`
- **Type**: `bool`
- **Description**: Set to true to create TPU node pools
- **Default**: `false`
- **Example**:
```hcl
enable_tpu = true
```

#### `tpu_pools`
- **Type**: `list(map(any))`
- **Description**: Configuration for TPU-based node pools
- **Default**: `[]`

---

### Networking Configuration

#### `network_name`
- **Type**: `string`
- **Description**: Name of the VPC network to use
- **Default**: `"default"`
- **Example**:
```hcl
network_name = "wso2-vpc"
```

#### `subnetwork_name`
- **Type**: `string`
- **Description**: Name of the subnetwork to use
- **Default**: `"default"`
- **Example**:
```hcl
subnetwork_name = "wso2-apim-subnet"
```

#### `subnetwork_region`
- **Type**: `string`
- **Description**: Region of the subnetwork
- **Default**: `"us-east1"`
- **Example**:
```hcl
subnetwork_region = "us-central1"
```

#### `ip_range_pods`
- **Type**: `string`
- **Description**: Secondary IP range for pods
- **Default**: `""`
- **Example**:
```hcl
ip_range_pods = "gke-pods-range"
```

#### `ip_range_services`
- **Type**: `string`
- **Description**: Secondary IP range for services
- **Default**: `""`
- **Example**:
```hcl
ip_range_services = "gke-services-range"
```

---

### Helm Configuration

#### `helm_release_name`
- **Type**: `string`
- **Description**: Name for the Helm release
- **Default**: `"apim"`
- **Example**:
```hcl
helm_release_name = "wso2-apim-prod"
```

#### `helm_chart_repo`
- **Type**: `string`
- **Description**: Helm chart repository URL. Leave empty for local charts.
- **Default**: `"oci://us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"`
- **Example - Remote Repository**:
```hcl
helm_chart_repo = "oci://us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"
```
- **Example - Local Chart**:
```hcl
helm_chart_repo = ""
helm_chart_name = "../helm-charts/wso2-apim-kubernetes"
helm_chart_version = ""
```

#### `helm_chart_name`
- **Type**: `string`
- **Description**: Helm chart name (for remote repos) or path to local chart directory
- **Default**: `"wso2-apim"`
- **Example - Remote**:
```hcl
helm_chart_name = "wso2-apim"
```
- **Example - Local**:
```hcl
helm_chart_name = "../helm-charts/wso2-apim-kubernetes"
```

#### `helm_chart_version`
- **Type**: `string`
- **Description**: Helm chart version. Leave empty for local charts.
- **Default**: `"4.5"`
- **Example**:
```hcl
helm_chart_version = "4.5.0"
```

---

### Container Images Configuration

All WSO2 APIM components use container images from GCP Artifact Registry. Each component has three configurable properties:

#### ACP (API Control Plane) Image

##### `acp_image_registry`
- **Type**: `string`
- **Description**: Registry for WSO2 APIM ACP image
- **Default**: `"us-docker.pkg.dev"`

##### `acp_image_repo`
- **Type**: `string`
- **Description**: Repository path for WSO2 APIM ACP image
- **Default**: `"wso2-marketplace-public/wso2-marketplace/wso2am-acp"`

##### `acp_image_tag`
- **Type**: `string`
- **Description**: Tag for WSO2 APIM ACP image
- **Default**: `"4.5"`

**Example**:
```hcl
acp_image_registry = "us-docker.pkg.dev"
acp_image_repo     = "my-project/wso2/wso2am-acp"
acp_image_tag      = "4.5.0"
```

#### APK Config Deployer Image

##### `apk_config_deployer_image_registry`
- **Type**: `string`
- **Default**: `"us-docker.pkg.dev"`

##### `apk_config_deployer_image_repo`
- **Type**: `string`
- **Default**: `"wso2-marketplace-public/wso2-marketplace/apk-config-deployer-service"`

##### `apk_config_deployer_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

**Example**:
```hcl
apk_config_deployer_image_registry = "us-docker.pkg.dev"
apk_config_deployer_image_repo     = "my-project/wso2/apk-config-deployer"
apk_config_deployer_image_tag      = "4.5.1"
```

#### APK Adapter Image

##### `apk_adapter_image_registry`
- **Type**: `string`
- **Default**: `"us-docker.pkg.dev"`

##### `apk_adapter_image_repo`
- **Type**: `string`
- **Default**: `"wso2-marketplace-public/wso2-marketplace/apk-adapter"`

##### `apk_adapter_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

#### APK Common Controller Image

##### `apk_common_controller_image_registry`
- **Type**: `string`
- **Default**: `"us-docker.pkg.dev"`

##### `apk_common_controller_image_repo`
- **Type**: `string`
- **Default**: `"wso2-marketplace-public/wso2-marketplace/apk-common-controller"`

##### `apk_common_controller_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

#### APK Ratelimiter Image

##### `apk_ratelimiter_image_registry`
- **Type**: `string`
- **Default**: `"us-docker.pkg.dev"`

##### `apk_ratelimiter_image_repo`
- **Type**: `string`
- **Default**: `"wso2-marketplace-public/wso2-marketplace/apk-ratelimiter"`

##### `apk_ratelimiter_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

#### APK Router Image

##### `apk_router_image_registry`
- **Type**: `string`
- **Default**: `"us-docker.pkg.dev"`

##### `apk_router_image_repo`
- **Type**: `string`
- **Default**: `"wso2-marketplace-public/wso2-marketplace/apk-router"`

##### `apk_router_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

#### APK Enforcer Image

##### `apk_enforcer_image_registry`
- **Type**: `string`
- **Default**: `"us-docker.pkg.dev"`

##### `apk_enforcer_image_repo`
- **Type**: `string`
- **Default**: `"wso2-marketplace-public/wso2-marketplace/apk-enforcer"`

##### `apk_enforcer_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

#### APK Agent Image

##### `apk_agent_image_repo`
- **Type**: `string`
- **Description**: Full repository path with registry for APK Agent image
- **Default**: `"us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apim-apk-agent"`

##### `apk_agent_image_tag`
- **Type**: `string`
- **Default**: `"4.5"`

**Example - Using Custom Registry for All Images**:
```hcl
# ACP
acp_image_registry = "gcr.io"
acp_image_repo     = "my-project/wso2am-acp"
acp_image_tag      = "4.5.0-custom"

# APK Components
apk_adapter_image_registry = "gcr.io"
apk_adapter_image_repo     = "my-project/apk-adapter"
apk_adapter_image_tag      = "4.5.0-custom"

# ... (similar for other components)

# APK Agent (uses full path)
apk_agent_image_repo = "gcr.io/my-project/apim-apk-agent"
apk_agent_image_tag  = "4.5.0-custom"
```

---

## Usage Examples

### Example 1: Development Environment with Local Chart

```hcl
# terraform.tfvars

# GCP Configuration
project_id = "my-dev-project"
region     = "us-east1"

# GKE Cluster
cluster_name     = "wso2-apim-dev"
cluster_location = "us-east1-b"
create_cluster   = true

# Smaller node pool for development
cpu_pools = [{
  name         = "dev-pool"
  machine_type = "e2-medium"
  autoscaling  = true
  min_count    = 1
  max_count    = 2
  disk_size_gb = 50
  disk_type    = "pd-standard"
}]

# Local Helm chart
helm_release_name  = "apim-dev"
helm_chart_repo    = ""
helm_chart_name    = "../helm-charts/wso2-apim-kubernetes"
helm_chart_version = ""

# Use default images
```

### Example 2: Production Environment with Remote Chart

```hcl
# terraform.tfvars

# GCP Configuration
project_id = "my-prod-project"
region     = "us-central1"

# GKE Cluster - Regional for high availability
cluster_name     = "wso2-apim-production"
cluster_location = "us-central1"
create_cluster   = true
kubernetes_version = "1.30"

# Production-grade node pools
cpu_pools = [
  {
    name         = "apim-pool"
    machine_type = "n1-standard-16"
    autoscaling  = true
    min_count    = 3
    max_count    = 10
    disk_size_gb = 200
    disk_type    = "pd-ssd"
  }
]

# Networking
network_name       = "wso2-prod-vpc"
subnetwork_name    = "wso2-apim-subnet"
subnetwork_region  = "us-central1"
ip_range_pods      = "gke-pods"
ip_range_services  = "gke-services"

# Remote Helm chart
helm_release_name  = "wso2-apim"
helm_chart_repo    = "oci://us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"
helm_chart_name    = "wso2-apim"
helm_chart_version = "4.5"

# Production images
acp_image_tag = "4.5.0"
apk_adapter_image_tag = "4.5.0"
apk_router_image_tag = "4.5.0"
apk_enforcer_image_tag = "4.5.0"
```

### Example 3: Using Existing Cluster

```hcl
# terraform.tfvars

# GCP Configuration
project_id = "my-project"
region     = "us-east1"

# Use existing cluster
create_cluster   = false
cluster_name     = "existing-gke-cluster"
cluster_location = "us-east1"

# Helm configuration
helm_release_name  = "apim"
helm_chart_repo    = "oci://us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"
helm_chart_name    = "wso2-apim"
helm_chart_version = "4.5"
```

### Example 4: Custom Image Registry

```hcl
# terraform.tfvars

# ... other configuration ...

# Custom registry for all images
acp_image_registry = "europe-docker.pkg.dev"
acp_image_repo     = "my-company/wso2/wso2am-acp"
acp_image_tag      = "4.5.0-patched"

apk_adapter_image_registry = "europe-docker.pkg.dev"
apk_adapter_image_repo     = "my-company/wso2/apk-adapter"
apk_adapter_image_tag      = "4.5.0-patched"

# ... (configure other images similarly)

apk_agent_image_repo = "europe-docker.pkg.dev/my-company/wso2/apim-apk-agent"
apk_agent_image_tag  = "4.5.0-patched"
```

---

## Deployment

### Initial Deployment

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply

# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>

# Verify deployment
kubectl get pods -A
kubectl get ingress -A
```

### Updating Configuration

```bash
# Modify terraform.tfvars
vim terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Destroying Resources

```bash
# Destroy all resources
terraform destroy
```

---

## Outputs

After successful deployment, Terraform will output:

- `cluster_name`: Name of the GKE cluster
- `cluster_endpoint`: Cluster API endpoint
- `cluster_location`: Cluster location
- `helm_release_name`: Name of the deployed Helm release

---

## Troubleshooting

### Common Issues

1. **Insufficient Quota**: Increase GCP quotas for the region
2. **Authentication Errors**: Run `gcloud auth application-default login`
3. **Helm Release Fails**: Check logs with `kubectl logs -n <namespace> <pod-name>`
4. **Image Pull Errors**: Verify image registry access and credentials

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info

# View all resources
kubectl get all -A

# Check Helm releases
helm list -A

# View pod logs
kubectl logs -f <pod-name> -n <namespace>

# Describe pod for debugging
kubectl describe pod <pod-name> -n <namespace>
```
