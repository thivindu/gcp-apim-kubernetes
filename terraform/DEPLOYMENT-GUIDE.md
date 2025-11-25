# WSO2 APIM GKE Deployment Guide

Complete step-by-step guide to deploy WSO2 APIM on Google Kubernetes Engine using Terraform.

## Prerequisites

✅ Terraform installed (v1.3+)
✅ Google Cloud SDK installed (`gcloud`)
✅ kubectl installed
✅ Active GCP project with billing enabled
✅ Appropriate IAM permissions

## Step 1: Authenticate with GCP

```bash
# Login to GCP
gcloud auth login

# Set your default project
gcloud config set project wso2-marketplace-public

# Get application-default credentials for Terraform
gcloud auth application-default login
```

## Step 2: Enable Required GCP APIs

```bash
# Enable required APIs (Terraform will also enable these, but it's faster to do it upfront)
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  config.googleapis.com
```

## Step 3: Verify Network Configuration

Check if you need to create a VPC network or use the default:

```bash
# List existing networks
gcloud compute networks list

# List existing subnets in us-east1
gcloud compute networks subnets list --filter="region:us-east1"
```

If using custom networking, update `terraform.tfvars`:
```hcl
network_name      = "your-vpc-name"
subnetwork_name   = "your-subnet-name"
subnetwork_region = "us-east1"
```

## Step 4: Review and Update Configuration

Edit `terraform.tfvars` if needed:

```bash
cd terraform
nano terraform.tfvars  # or use your preferred editor
```

**Key settings to verify:**
- `project_id`: Your GCP project ID
- `cluster_name`: Name for your GKE cluster
- `cluster_location`: Region or zone (`us-east1` = regional cluster)
- `create_cluster`: Set to `true` to create a new cluster
- `network_name` and `subnetwork_name`: VPC configuration

## Step 5: Initialize Terraform

```bash
cd /Users/thivindu/Desktop/APIM/repos/gcp-apim-kubernetes/terraform

# Initialize Terraform (already done, but safe to run again)
terraform init
```

Expected output:
```
✅ Terraform has been successfully initialized!
```

## Step 6: Validate Configuration

```bash
terraform validate
```

Expected output:
```
✅ Success! The configuration is valid.
```

## Step 7: Review Deployment Plan

```bash
terraform plan
```

This will show you:
- **GKE Cluster**: Control plane, node pools, networking
- **Nginx Ingress**: Helm release in `ingress-nginx` namespace
- **WSO2 APIM**: Helm release with ACP, APK, and Agent components
- **Total resources**: Approximately 200+ Kubernetes resources

**Review carefully:**
- Node pool configurations (machine types, disk sizes)
- Networking (IP ranges, firewall rules)
- Cost estimates (GKE nodes, load balancers)

## Step 8: Deploy Infrastructure

```bash
# Deploy everything
terraform apply

# Review the plan one more time, then type 'yes' to confirm
```

**Deployment timeline:**
1. **GCP APIs enabled** (~1-2 minutes)
2. **GKE Cluster created** (~10-15 minutes)
3. **Nginx Ingress installed** (~2-3 minutes)
4. **WSO2 APIM deployed** (~5-10 minutes)

**Total time**: ~20-30 minutes

## Step 9: Connect to Your Cluster

Once deployment is complete:

```bash
# Get cluster credentials
gcloud container clusters get-credentials wso2-apim-gke-test \
  --region us-east1 \
  --project wso2-marketplace-public

# Verify connection
kubectl cluster-info

# Check nodes
kubectl get nodes
```

## Step 10: Verify Deployment

### Check Nginx Ingress Controller

```bash
# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller service (should have EXTERNAL-IP)
kubectl get svc -n ingress-nginx
```

Expected output:
```
NAME                                 TYPE           EXTERNAL-IP
ingress-nginx-controller             LoadBalancer   35.x.x.x
```

### Check WSO2 APIM Components

```bash
# List all pods (should see ACP, APK, Agent pods)
kubectl get pods -A | grep wso2

# Check Helm releases
helm list -A

# Check services
kubectl get svc -A | grep wso2
```

Expected components:
- **ACP pods**: WSO2 API Manager Control Plane
- **APK pods**: Config deployer, adapter, common controller, ratelimiter, router, enforcer
- **Agent pods**: APIM-APK Agent

### Check Pod Status

```bash
# Wait for all pods to be ready
kubectl get pods -A --watch

# Check for any failed pods
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

## Step 11: Access Your Application

### Get Ingress External IP

```bash
# Get the ingress controller's external IP
kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Get WSO2 Service Endpoints

```bash
# List all services
kubectl get svc -A

# Get specific service details
kubectl describe svc <service-name> -n <namespace>
```

### Access the Application

Depending on your Helm chart configuration, you can access:

1. **Via LoadBalancer** (if services are type LoadBalancer)
2. **Via Ingress** (if ingress resources are configured)
3. **Via Port-Forward** (for testing)

```bash
# Example: Port-forward to ACP service
kubectl port-forward svc/<acp-service-name> 9443:9443 -n default

# Access at: https://localhost:9443
```

## Step 12: Monitor Deployment

### Check Logs

```bash
# Check pod logs
kubectl logs -f <pod-name> -n <namespace>

# Check ingress controller logs
kubectl logs -f -n ingress-nginx -l app.kubernetes.io/component=controller

# Check for errors across all pods
kubectl get events -A --sort-by='.lastTimestamp'
```

### Common Issues and Solutions

#### ImagePullBackOff Errors

If you see `ImagePullBackOff` errors:

```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# 1. GKE cluster can't authenticate to GCP Artifact Registry
# 2. Image doesn't exist or wrong digest/tag
```

**Solution for Artifact Registry authentication:**

```bash
# Option 1: Grant GKE node service account permission
gcloud projects add-iam-policy-binding wso2-marketplace-public \
  --member="serviceAccount:<cluster-service-account>" \
  --role="roles/artifactregistry.reader"

# Find your cluster's service account
gcloud container clusters describe wso2-apim-gke-test \
  --region us-east1 \
  --format="get(nodeConfig.serviceAccount)"
```

#### Pods Stuck in Pending

```bash
# Check why pods are pending
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# - Insufficient resources
# - Node selector/affinity issues
# - PersistentVolume issues
```

**Solution:**
```bash
# Check node resources
kubectl top nodes

# Check resource requests
kubectl describe pod <pod-name> | grep -A 5 Requests
```

#### Helm Release Failed

```bash
# Check Helm release status
helm status <release-name> -n <namespace>

# Get Helm release history
helm history <release-name> -n <namespace>

# Rollback if needed
helm rollback <release-name> -n <namespace>
```

## Step 13: Verify Image Configuration

Check that Terraform successfully overrode the Helm values with your images:

```bash
# Get the Helm release values
helm get values apim -n default

# Should show your GCP Artifact Registry images:
# acp.wso2.deployment.image.registry: us-east1-docker.pkg.dev
# acp.wso2.deployment.image.repository: wso2-marketplace-public/wso2-marketplace/wso2am-acp
# etc.
```

## Step 14: Test the Application

Once all pods are running:

1. **Access the API Manager Console**
2. **Create a test API**
3. **Test API invocation**
4. **Verify monitoring and logging**

## Terraform Outputs

After deployment, check Terraform outputs:

```bash
terraform output
```

This will show you important information like:
- Cluster name
- Cluster endpoint
- Helm release names
- Service endpoints

## Updating the Deployment

If you need to update the Helm chart or configuration:

```bash
# Make changes to helm-charts/wso2-apim-kubernetes/values.yaml or Chart.yaml

# Update specific Terraform variables in terraform.tfvars

# Apply changes
terraform plan
terraform apply
```

Terraform will update the Helm release with the new configuration.

## Cleanup

To destroy all resources:

```bash
# WARNING: This will delete the GKE cluster and all deployed applications!
terraform destroy

# Review what will be destroyed, then type 'yes' to confirm
```

**Important:** This will:
- Delete the GKE cluster
- Delete all Helm releases
- Delete networking resources (if created by Terraform)
- **NOT** delete the VPC/subnet if they existed before

## Cost Optimization

### Development Environment

For a development/testing environment, consider:

```hcl
# In terraform.tfvars
cpu_pools = [{
  name         = "cpu-pool"
  machine_type = "e2-standard-4"  # Smaller than n1-standard-16
  autoscaling  = true
  min_count    = 1
  max_count    = 2
  disk_size_gb = 50
  disk_type    = "pd-standard"
}]
```

### Production Environment

For production:
- Use regional cluster (already configured)
- Enable autoscaling (already configured)
- Use preemptible nodes for non-critical workloads (optional)
- Enable deletion protection:
  ```hcl
  deletion_protection = true
  ```

## Estimated Costs (us-east1)

Approximate monthly costs:

| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| GKE Control Plane | Regional | $73 |
| Node Pool (n1-standard-16) | 1-3 nodes | $450-$1,350 |
| LoadBalancer (Ingress) | 1 IP | $18 |
| Persistent Disks | 100GB SSD | $17 |
| **Total** | | **~$558-$1,458** |

Use Google Cloud Pricing Calculator for accurate estimates: https://cloud.google.com/products/calculator

## Troubleshooting Commands Quick Reference

```bash
# Cluster info
gcloud container clusters describe wso2-apim-gke-test --region us-east1

# Get all resources
kubectl get all -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Check pod logs
kubectl logs -f <pod-name> -n <namespace>

# Check Helm releases
helm list -A

# Check Terraform state
terraform state list

# Refresh Terraform state
terraform refresh

# Check what Terraform will change
terraform plan

# Validate Terraform config
terraform validate
```

## Next Steps

1. **Configure DNS** - Point your domain to the ingress external IP
2. **Set up TLS/SSL** - Configure cert-manager for automatic certificates
3. **Configure monitoring** - Set up Google Cloud Monitoring/Logging
4. **Set up CI/CD** - Automate deployments with Cloud Build or GitHub Actions
5. **Implement backup** - Configure backup for persistent data
6. **Security hardening** - Review and implement security best practices

## Support Resources

- **WSO2 APIM Documentation**: https://apim.docs.wso2.com/
- **GKE Documentation**: https://cloud.google.com/kubernetes-engine/docs
- **Terraform GCP Provider**: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- **Helm Documentation**: https://helm.sh/docs/

## Files Reference

- `terraform.tfvars` - Your deployment configuration
- `variables.tf` - Variable definitions
- `helm.tf` - Helm releases configuration
- `gke.tf` - GKE cluster configuration
- `../helm-charts/wso2-apim-kubernetes/` - Your local Helm chart
- `TERRAFORM-SETUP.md` - Technical setup details
- `GCP-MARKETPLACE-SETUP.md` - GCP Marketplace configuration

---

**Ready to deploy?** Start with Step 1 and work through each step carefully. 🚀
