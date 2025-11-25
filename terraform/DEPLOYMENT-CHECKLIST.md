# Deployment Checklist

Quick checklist for deploying WSO2 APIM on GKE with Terraform.

## Pre-Deployment Checklist

- [ ] **GCP Authentication**
  ```bash
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project wso2-marketplace-public
  ```

- [ ] **Verify terraform.tfvars**
  - [ ] `project_id` is correct
  - [ ] `cluster_name` is unique
  - [ ] `cluster_location` is set (e.g., `us-east1`)
  - [ ] `network_name` and `subnetwork_name` are correct
  - [ ] `helm_chart_name` points to `../helm-charts/wso2-apim-kubernetes`

- [ ] **Check Network Resources**
  ```bash
  gcloud compute networks list
  gcloud compute networks subnets list --filter="region:us-east1"
  ```

- [ ] **Enable Required APIs**
  ```bash
  gcloud services enable \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com \
    config.googleapis.com
  ```

## Deployment Checklist

- [ ] **Initialize Terraform**
  ```bash
  cd terraform
  terraform init
  ```

- [ ] **Validate Configuration**
  ```bash
  terraform validate
  ```

- [ ] **Review Plan**
  ```bash
  terraform plan
  ```
  Review:
  - [ ] GKE cluster will be created
  - [ ] Nginx ingress will be installed
  - [ ] WSO2 APIM will be deployed
  - [ ] Node pool configuration is correct
  - [ ] Cost implications are acceptable

- [ ] **Apply Configuration**
  ```bash
  terraform apply
  ```
  Expected time: ~20-30 minutes

- [ ] **Get Cluster Credentials**
  ```bash
  gcloud container clusters get-credentials wso2-apim-gke-test \
    --region us-east1 \
    --project wso2-marketplace-public
  ```

## Post-Deployment Verification

- [ ] **Check Cluster**
  ```bash
  kubectl cluster-info
  kubectl get nodes
  ```

- [ ] **Verify Nginx Ingress**
  ```bash
  kubectl get pods -n ingress-nginx
  kubectl get svc -n ingress-nginx
  ```
  Expected: `ingress-nginx-controller` service has EXTERNAL-IP

- [ ] **Verify WSO2 APIM Pods**
  ```bash
  kubectl get pods -A | grep wso2
  ```
  Expected pods:
  - [ ] ACP pods running
  - [ ] APK config-deployer running
  - [ ] APK adapter running
  - [ ] APK common-controller running
  - [ ] APK ratelimiter running
  - [ ] APK router running
  - [ ] APK enforcer running
  - [ ] Agent pods running

- [ ] **Check Helm Releases**
  ```bash
  helm list -A
  ```
  Expected:
  - [ ] `ingress-nginx` in `ingress-nginx` namespace
  - [ ] `apim-xxxx` in default namespace (or configured namespace)

- [ ] **Check All Pods are Running**
  ```bash
  kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
  ```
  Expected: No output (all pods running)

- [ ] **Verify Image Configuration**
  ```bash
  helm get values apim -n default
  ```
  Verify images point to GCP Artifact Registry

## Troubleshooting Checklist

### If Terraform Apply Fails

- [ ] Check GCP API permissions
  ```bash
  gcloud projects get-iam-policy wso2-marketplace-public
  ```

- [ ] Verify network resources exist
  ```bash
  gcloud compute networks describe <network-name>
  gcloud compute networks subnets describe <subnet-name> --region us-east1
  ```

- [ ] Check Terraform state
  ```bash
  terraform state list
  ```

### If Pods are ImagePullBackOff

- [ ] Check image URLs in pod description
  ```bash
  kubectl describe pod <pod-name> -n <namespace>
  ```

- [ ] Grant Artifact Registry access to GKE service account
  ```bash
  # Get cluster service account
  SA=$(gcloud container clusters describe wso2-apim-gke-test \
    --region us-east1 \
    --format="get(nodeConfig.serviceAccount)")
  
  # Grant permission
  gcloud projects add-iam-policy-binding wso2-marketplace-public \
    --member="serviceAccount:$SA" \
    --role="roles/artifactregistry.reader"
  ```

- [ ] Verify images exist in registry
  ```bash
  gcloud artifacts docker images list \
    us-east1-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace
  ```

### If Pods are Pending

- [ ] Check node resources
  ```bash
  kubectl describe nodes
  kubectl top nodes
  ```

- [ ] Check pod resource requests
  ```bash
  kubectl describe pod <pod-name> | grep -A 5 Requests
  ```

- [ ] Scale node pool if needed
  ```bash
  gcloud container clusters resize wso2-apim-gke-test \
    --num-nodes 2 \
    --region us-east1 \
    --node-pool cpu-pool
  ```

### If Helm Release Fails

- [ ] Check Helm release status
  ```bash
  helm status apim -n default
  ```

- [ ] Check Helm release history
  ```bash
  helm history apim -n default
  ```

- [ ] View Helm release notes
  ```bash
  helm get notes apim -n default
  ```

- [ ] Check Helm values
  ```bash
  helm get values apim -n default
  ```

## Access Application

- [ ] **Get Ingress External IP**
  ```bash
  kubectl get svc ingress-nginx-controller -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  ```

- [ ] **Get Service Endpoints**
  ```bash
  kubectl get svc -A
  ```

- [ ] **Port-forward for Testing** (if needed)
  ```bash
  kubectl port-forward svc/<service-name> 9443:9443 -n <namespace>
  ```

- [ ] **Access Application**
  - [ ] Open browser to application URL
  - [ ] Login with credentials
  - [ ] Verify functionality

## Monitoring

- [ ] **Check Logs**
  ```bash
  kubectl logs -f <pod-name> -n <namespace>
  ```

- [ ] **Check Events**
  ```bash
  kubectl get events -A --sort-by='.lastTimestamp' | tail -20
  ```

- [ ] **Set up Cloud Monitoring** (optional)
  ```bash
  # Enable monitoring for cluster
  gcloud container clusters update wso2-apim-gke-test \
    --region us-east1 \
    --enable-cloud-logging \
    --enable-cloud-monitoring
  ```

## Cleanup (When Done)

⚠️ **WARNING**: This will delete everything!

- [ ] **Backup any important data**

- [ ] **Destroy Terraform resources**
  ```bash
  terraform destroy
  ```

- [ ] **Verify cleanup**
  ```bash
  gcloud container clusters list
  kubectl config get-contexts
  ```

## Status

- **Deployment Date**: ___________
- **Cluster Name**: `wso2-apim-gke-test`
- **Region**: `us-east1`
- **Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete | ⬜ Failed
- **Notes**: ___________________________________

---

**Documentation**: See `DEPLOYMENT-GUIDE.md` for detailed instructions.
