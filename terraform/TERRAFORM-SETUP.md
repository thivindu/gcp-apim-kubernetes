# Terraform Setup and Initialization

## Overview

This Terraform configuration deploys WSO2 APIM on Google Kubernetes Engine (GKE) with proper dependency management and nginx ingress controller.

## Provider Versions

The configuration uses the following provider versions:

```hcl
terraform {
  required_providers {
    google        = ">= 7.0.0, < 8.0.0"
    google-beta   = ">= 7.0.0, < 8.0.0"
    helm          = "~> 2.8.0"
    kubernetes    = "~> 2.10"
  }
}
```

### Why Google Provider >= 7.0?

The GKE module (`terraform-google-modules/kubernetes-engine/google`) version 29.0+ requires Google provider >= 7.0.0. We've ensured all modules are compatible:

- **GKE Module**: `>= 29.0` (uses latest features, requires Google provider >= 7.0)
- **Project Factory Module**: `~> 18.0` (compatible with Google provider >= 7.0)

## Module Versions

| Module | Version | Purpose |
|--------|---------|---------|
| `terraform-google-modules/kubernetes-engine/google` | `>= 29.0` | Creates and manages GKE cluster |
| `terraform-google-modules/project-factory/google//modules/project_services` | `~> 18.0` | Enables required GCP APIs |

## Initialization

### First Time Setup

```bash
cd terraform
terraform init
```

This will:
1. Download the GKE module (v41.0.2 or later)
2. Download the Project Factory module (v18.2.0 or later)
3. Install provider plugins:
   - `hashicorp/google` v7.12.0
   - `hashicorp/google-beta` v7.12.0
   - `hashicorp/helm` v2.8.0
   - `hashicorp/kubernetes` v2.38.0
   - `hashicorp/random` v3.7.2

### Validate Configuration

```bash
terraform validate
```

Expected output: `Success! The configuration is valid.`

### Review Changes

```bash
terraform plan
```

This will show you:
- Resources to be created (GKE cluster, node pools, etc.)
- Helm releases (nginx ingress, WSO2 APIM stack)
- Service accounts and IAM bindings

### Apply Configuration

```bash
terraform apply
```

This will deploy:
1. **GKE Cluster** (if `create_cluster = true`)
2. **Nginx Ingress Controller** in `ingress-nginx` namespace
3. **WSO2 APIM Stack** (ACP + APK + Agent)

## Troubleshooting

### Error: Conflicting Provider Versions

**Symptom:**
```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider hashicorp/google: 
no available releases match the given constraints >= 3.43.0, >= 7.0.0, < 7.0.0, < 8.0.0
```

**Cause:** 
Module version conflicts between GKE module and Project Factory module.

**Solution:**
✅ This has been fixed by:
- Updating `versions.tf` to require Google provider >= 7.0.0
- Updating Project Factory module to `~> 18.0` (compatible with provider >= 7.0)

### Error: Module Not Installed

**Symptom:**
```
Error: Module not installed
This module is not yet installed. Run "terraform init" to install all modules.
```

**Solution:**
```bash
terraform init
```

### Error: Provider Version Mismatch

**Symptom:**
After updating versions, Terraform still uses old providers.

**Solution:**
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

## Deployment Order

The Terraform configuration ensures proper deployment order:

```
1. GCP Project APIs Enabled
   ↓
2. GKE Cluster Created (if needed)
   ↓
3. Nginx Ingress Controller Installed
   ↓
4. WSO2 APIM Stack Deployed
```

### Nginx Ingress Controller

- **Namespace:** `ingress-nginx`
- **Chart:** `kubernetes.github.io/ingress-nginx`
- **Wait Time:** Up to 10 minutes for controller to be ready
- **Dependencies:** GKE cluster must be ready

### WSO2 APIM Stack

- **Dependencies:** Nginx ingress controller service must exist
- **Components:**
  - ACP (API Manager Control Plane)
  - APK (API Platform for Kubernetes)
  - APK Agent
- **Images:** All configured to use GCP Artifact Registry

## Configuration Files

| File | Purpose |
|------|---------|
| `versions.tf` | Provider version constraints |
| `main.tf` | Project services and random suffix |
| `gke.tf` | GKE cluster configuration |
| `helm.tf` | Nginx ingress and WSO2 APIM Helm releases |
| `variables.tf` | Input variables (24 image variables + cluster config) |
| `outputs.tf` | Output values after deployment |
| `terraform.tfvars` | Default variable values |
| `schema.yaml` | GCP Marketplace schema definition |

## Variables

### Required Variables

- `project_id`: GCP project ID
- `cluster_location`: GKE cluster location (region or zone)
- `network_name`: VPC network name
- `subnetwork_name`: Subnetwork name
- `subnetwork_region`: Subnetwork region

### Image Variables

24 variables for container images (3-4 per image):
- `acp_image_*`: WSO2 APIM ACP image (registry, repo, digest)
- `apk_*_image_*`: APK component images (registry, repo, tag)
- `apk_agent_image_*`: Agent image (repo, tag)

See `variables.tf` for complete list with defaults.

## Next Steps

1. ✅ **Terraform Init** - Complete
2. ✅ **Terraform Validate** - Complete
3. ⏸️ **Configure Variables** - Set your GCP project details in `terraform.tfvars`
4. ⏸️ **Terraform Plan** - Review planned changes
5. ⏸️ **Terraform Apply** - Deploy to GCP
6. ⏸️ **Verify Deployment** - Check pods and services

## Useful Commands

```bash
# Show current providers
terraform providers

# Update providers to latest compatible versions
terraform init -upgrade

# Format Terraform files
terraform fmt

# Show current state
terraform show

# List resources
terraform state list

# Destroy everything
terraform destroy
```

## GCP Marketplace Publishing

Once the local deployment is working, follow these steps for GCP Marketplace:

1. Build deployer image with all container images
2. Upload `schema.yaml` to define the UI
3. Test with `mpdev` tool
4. Submit for review

See [GCP-MARKETPLACE-SETUP.md](./GCP-MARKETPLACE-SETUP.md) for detailed marketplace configuration.
