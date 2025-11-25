# GCP Marketplace Terraform Configuration

This document explains the GCP Marketplace deployment setup for WSO2 APIM on Kubernetes.

## Quick Reference

**Deployment Order:**
1. GKE Cluster (if `create_cluster = true`)
2. Nginx Ingress Controller (namespace: `ingress-nginx`)
3. WSO2 APIM Stack (ACP + APK + Agent)

**Key Features:**
- ✅ Automatic nginx ingress controller installation
- ✅ Proper dependency ordering with wait conditions
- ✅ All 8 container images configured for GCP Marketplace substitution
- ✅ Billing integration with usage tracking
- ✅ Support for digest-based (ACP) and tag-based (APK) images

## Overview

The Terraform configuration follows the [GCP Marketplace K8s App Packaging Guide](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/building-deployer.md) to deploy the WSO2 APIM unified Helm chart through GCP Marketplace.

## Architecture

```
GCP Marketplace
    ↓
Terraform (InfraManager)
    ↓
├── Nginx Ingress Controller (installed first)
    ↓
Helm Chart (wso2-apim-kubernetes)
    ↓
├── WSO2 APIM ACP (patched local chart)
├── WSO2 APK (from GitHub)
└── WSO2 APIM-APK Agent (from GitHub)
```

## Image Configuration

All 8 container images are configured to be substituted by GCP Marketplace:

### 1. WSO2 APIM ACP
- **Variables**: `acp_image_registry`, `acp_image_repo`, `acp_image_digest`
- **Type**: Uses digest for immutable deployment
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/wso2am-acp@sha256:7d45a3...`

### 2. APK Config Deployer Service
- **Variables**: `apk_config_deployer_image_registry`, `apk_config_deployer_image_repo`, `apk_config_deployer_image_tag`
- **Type**: Uses tag
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apk-config-deployer-service:1.3.0`

### 3. APK Adapter
- **Variables**: `apk_adapter_image_registry`, `apk_adapter_image_repo`, `apk_adapter_image_tag`
- **Type**: Uses tag
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apk-adapter:1.3.0`

### 4. APK Common Controller
- **Variables**: `apk_common_controller_image_registry`, `apk_common_controller_image_repo`, `apk_common_controller_image_tag`
- **Type**: Uses tag
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apk-common-controller:1.3.0`

### 5. APK Ratelimiter
- **Variables**: `apk_ratelimiter_image_registry`, `apk_ratelimiter_image_repo`, `apk_ratelimiter_image_tag`
- **Type**: Uses tag
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apk-ratelimiter:1.3.0`

### 6. APK Router
- **Variables**: `apk_router_image_registry`, `apk_router_image_repo`, `apk_router_image_tag`
- **Type**: Uses tag
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apk-router:1.3.0`

### 7. APK Enforcer
- **Variables**: `apk_enforcer_image_registry`, `apk_enforcer_image_repo`, `apk_enforcer_image_tag`
- **Type**: Uses tag
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apk-enforcer:1.3.0`

### 8. APIM-APK Agent
- **Variables**: `apk_agent_image_repo`, `apk_agent_image_tag`
- **Type**: Uses tag (repo includes registry)
- **Default**: `us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/apim-apk-agent:1.3.0`

## Key Files

### helm.tf
Configures Helm releases with proper dependencies:

#### Nginx Ingress Controller
- Installed first in `ingress-nginx` namespace
- Uses official Kubernetes nginx ingress chart
- Waits for controller to be ready (10 minute timeout)
- Creates namespace automatically if it doesn't exist

#### WSO2 APIM Primary Release
- Depends on nginx ingress controller being ready
- Uses `set` blocks to pass Terraform variables to Helm chart
- Overrides default image values from `values.yaml`
- Configures marketplace service name and level

### schema.yaml
Defines the GCP Marketplace UI and image mappings:
- Maps each container image to Terraform variables
- Defines variable types (REGISTRY, REPO_WITHOUT_REGISTRY_WITH_NAME, TAG, DIGEST)
- Used by GCP Marketplace to populate image URLs during publishing

### variables.tf
Defines all Terraform variables:
- 24 variables for images (3-4 per image)
- Default values point to current image locations
- GCP Marketplace will override these during deployment

### helm.tf
Configures Helm release with image overrides:
- Uses `set` blocks to pass Terraform variables to Helm chart
- Overrides default image values from `values.yaml`
- Configures marketplace service name and level

### terraform.tfvars
User-customizable deployment parameters:
- `helm_chart_repo`: Path to local Helm chart (default: `../helm-charts/wso2-apim-kubernetes`)
- `helm_chart_name`: Chart name
- GKE cluster configuration

## Deployment Flow

1. **User deploys from GCP Marketplace**
   - Selects configuration options
   - GCP Marketplace substitutes image URLs with Google-hosted copies

2. **Terraform provisions infrastructure**
   - Creates GKE cluster (if needed)
   - Sets up networking and storage

3. **Nginx Ingress Controller Installation**
   - Helm installs nginx ingress controller in `ingress-nginx` namespace
   - Waits for controller service to be ready (timeout: 10 minutes)
   - This happens before any WSO2 components are deployed

4. **Helm deploys WSO2 APIM application**
   - Uses image URLs from Terraform variables
   - Deploys all three charts (ACP, APK, Agent)
   - Configures billing annotation for usage tracking

5. **Application becomes available**
   - 199 Kubernetes resources created (plus nginx ingress resources)
   - Services exposed via Ingress/LoadBalancer

## Helm Value Overrides

The Terraform configuration overrides these Helm values:

```yaml
# ACP Image
acp.wso2.deployment.image.registry: <from terraform>
acp.wso2.deployment.image.repository: <from terraform>
acp.wso2.deployment.image.digest: <from terraform>

# APK Component Images
apk.wso2.apk.dp.configdeployer.deployment.image: <from terraform>
apk.wso2.apk.dp.adapter.deployment.image: <from terraform>
apk.wso2.apk.dp.commonController.deployment.image: <from terraform>
apk.wso2.apk.dp.ratelimiter.deployment.image: <from terraform>
apk.wso2.apk.dp.gatewayRuntime.deployment.router.image: <from terraform>
apk.wso2.apk.dp.gatewayRuntime.deployment.enforcer.image: <from terraform>

# Agent Image
apkagent.image.repository: <from terraform>
apkagent.image.tag: <from terraform>

# Marketplace Configuration
marketplace.serviceName: wso2-apimanager.endpoints.wso2-marketplace-public.cloud.goog
marketplace.serviceLevel: default
```

## Marketplace Billing

The deployment includes GCP Marketplace billing annotation:
```yaml
cloudmarketplace.googleapis.com/product.metadata: |
  v1:{
    "services":[{
      "service_name":"wso2-apimanager.endpoints.wso2-marketplace-public.cloud.goog",
      "service_level":"default"
    }]
  }
```

This annotation enables:
- Usage tracking and reporting
- Billing integration with GCP Marketplace
- Customer license validation

## Testing Locally

To test the deployment before publishing to GCP Marketplace:

```bash
# Initialize Terraform
cd terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Verify deployment
kubectl get pods -A | grep wso2
helm list
```

## GCP Marketplace Publishing

1. **Build deployer image** with application containers
2. **Upload schema.yaml** defining the UI and variables
3. **Test deployment** using mpdev tool
4. **Submit for review** to GCP Marketplace team

## Image Pull Authentication

For private images in GCP Artifact Registry, the GKE cluster needs authentication:

### Option 1: Node Service Account (Recommended for GKE)
```bash
# Grant the GKE node service account permission
gcloud projects add-iam-policy-binding wso2-marketplace-public \
  --member="serviceAccount:<cluster-service-account>" \
  --role="roles/artifactregistry.reader"
```

### Option 2: Workload Identity (Best Practice)
```bash
# Create Kubernetes service account
kubectl create serviceaccount wso2-apim-sa -n default

# Bind to GCP service account
gcloud iam service-accounts add-iam-policy-binding \
  <gcp-sa>@<project>.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<project>.svc.id.goog[default/wso2-apim-sa]"

# Annotate K8s service account
kubectl annotate serviceaccount wso2-apim-sa \
  iam.gke.io/gcp-service-account=<gcp-sa>@<project>.iam.gserviceaccount.com
```

### Option 3: Image Pull Secret (Manual)
```bash
# Create secret
kubectl create secret docker-registry gcr-json-key \
  --docker-server=us-east1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat key.json)"
```

## Troubleshooting

### ImagePullBackOff Errors
- Check service account permissions
- Verify image URLs are correct
- Check GCP Artifact Registry access

### Terraform Validation Errors
- Run `terraform init` to install modules
- Check variable types match schema.yaml
- Verify Helm chart path exists

### Helm Deployment Failures
- Check Terraform set blocks match Helm value paths
- Verify image registries are accessible
- Review pod logs: `kubectl logs <pod-name>`

## Next Steps

1. ✅ Configure schema.yaml with all images
2. ✅ Add variables to variables.tf
3. ✅ Configure helm.tf with set blocks
4. ⏸️ Add billing annotation to ACP deployment
5. ⏸️ Configure image pull authentication
6. ⏸️ Test complete deployment
7. ⏸️ Build deployer image for GCP Marketplace
8. ⏸️ Submit to GCP Marketplace

## References

- [GCP Marketplace K8s App Tools](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [WSO2 APIM Documentation](https://apim.docs.wso2.com/)
