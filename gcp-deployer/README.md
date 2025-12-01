# WSO2 APIM Kubernetes - GCP Marketplace Deployer

This directory contains the deployer image structure for deploying WSO2 APIM on Google Cloud Platform (GCP) Marketplace.

## Deployment Options

- **[Cloud Console Deployment](https://console.cloud.google.com/marketplace)** - Deploy via GCP Marketplace UI
- **[Command Line Deployment](CLI-DEPLOYMENT.md)** - Deploy using kubectl, Helm, or mpdev
- **[Quick Start Guide](GETTING-STARTED.md)** - Step-by-step deployment guide

## Quick Deploy via CLI

For command-line deployment, use the interactive script:

```bash
cd gcp-deployer
./deploy-cli.sh
```

See [CLI-DEPLOYMENT.md](CLI-DEPLOYMENT.md) for detailed command-line instructions.

## Structure

```
gcp-deployer/
├── Dockerfile                      # Deployer image definition
├── Makefile                        # Build and deployment automation
├── schema.yaml                     # GCP Marketplace schema definition
├── .dockerignore                   # Docker build exclusions
├── data-test/                     # Test configuration for verification
│   ├── schema.yaml               # Test schema
│   └── chart/
│       └── templates/
│           └── tester.yaml       # Test pod manifest
├── chart/                         # Helm chart (copy from helm-charts/wso2-apim-kubernetes/)
├── CLI-DEPLOYMENT.md              # Command-line deployment guide
├── deploy-cli.sh                  # Quick CLI deployment script
├── GETTING-STARTED.md             # Comprehensive setup guide
└── README.md                      # This file
```

## Prerequisites

1. **GCP Project**: A Google Cloud Platform project with billing enabled
2. **GKE Cluster**: A running Google Kubernetes Engine cluster
3. **Docker**: Docker installed and configured
4. **gcloud CLI**: Google Cloud SDK installed and authenticated
5. **kubectl**: Kubernetes CLI configured to access your GKE cluster
6. **Helm**: Helm 3.x installed

## Setup Instructions

### 1. Prepare the Chart

Copy your Helm chart to the deployer directory:

```bash
# From the repository root
cp -r helm-charts/wso2-apim-kubernetes gcp-deployer/chart
```

### 2. Configure GCP Project

```bash
# Set your GCP project ID
export PROJECT=your-gcp-project-id
export CLUSTER=your-gke-cluster-name
export ZONE=your-gcp-zone

# Configure gcloud
gcloud config set project $PROJECT
gcloud container clusters get-credentials $CLUSTER --zone=$ZONE
```

### 3. Build the Deployer Image

```bash
cd gcp-deployer

# Set the registry and app details
export REGISTRY=us-docker.pkg.dev/wso2-marketplace-public
export APP_ID=wso2-marketplace
export RELEASE=4.5.0

# Build the deployer image
docker build \
  --build-arg MARKETPLACE_TOOLS_TAG=latest \
  --tag us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5.0 \
  -f Dockerfile .
```

### 4. Push the Deployer Image

```bash
# Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker

# Push the image to GCR
docker push $REGISTRY/$APP_ID/deployer:$RELEASE
```

### 5. Deploy Using mpdev

Install the Google Cloud Marketplace tools:

```bash
# Install mpdev
docker pull gcr.io/cloud-marketplace-tools/k8s/dev:latest

# Create an alias for easier use
alias mpdev='docker run --rm \
  -v ~/.config/gcloud:/root/.config/gcloud \
  -v ~/.kube:/root/.kube \
  -v $(pwd):/data \
  gcr.io/cloud-marketplace-tools/k8s/dev:latest'
```

Test the deployment:

```bash
# Install the application
mpdev install \
  --deployer=$REGISTRY/$APP_ID/deployer:$RELEASE \
  --parameters='{"name": "wso2-apim-test", "namespace": "default", "gcp.enabled": true}'
```

### 6. Verify Deployment

```bash
# Check the deployment status
kubectl get applications -n default

# Check pods
kubectl get pods -n default -l app.kubernetes.io/name=wso2-apim

# View logs
kubectl logs -n default -l app.kubernetes.io/name=wso2-apim --tail=100
```

## Configuration Parameters

The deployer accepts the following parameters (defined in `schema.yaml`):

### Required Parameters
- `name`: Application instance name
- `namespace`: Kubernetes namespace for deployment
- `gcp.enabled`: Enable GCP-specific configurations (default: true)

### GCP FileStore Configuration
- `gcp.fs.capacity`: Storage capacity (e.g., "1Ti")
- `gcp.fs.fileshares.carbonDB1.*`: FileStore config for CarbonDB instance 1
- `gcp.fs.fileshares.solr1.*`: FileStore config for Solr instance 1
- `gcp.fs.fileshares.carbonDB2.*`: FileStore config for CarbonDB instance 2
- `gcp.fs.fileshares.solr2.*`: FileStore config for Solr instance 2

Each fileshare requires:
- `fileStoreName`: Name of the GCP FileStore
- `fileShareName`: Name of the file share within FileStore
- `ip`: IP address of the FileStore

### Component Toggles
- `acp.enabled`: Enable WSO2 API Manager Control Plane (default: true)
- `apk.enabled`: Enable APK installation (default: true)
- `apkagent.enabled`: Enable APIM APK Agent (default: true)

## Updating the Chart

When you make changes to the Helm chart:

```bash
# Re-copy the chart
rm -rf gcp-deployer/chart
cp -r helm-charts/wso2-apim-kubernetes gcp-deployer/chart

# Rebuild and push the deployer image
cd gcp-deployer
docker build --tag $REGISTRY/$APP_ID/deployer:$RELEASE -f Dockerfile .
docker push $REGISTRY/$APP_ID/deployer:$RELEASE
```

## Troubleshooting

### Image Pull Errors
Ensure your GKE cluster has access to the container registry:
```bash
kubectl create secret docker-registry gcr-json-key \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat ~/key.json)" \
  --docker-email=user@example.com
```

### Dependency Issues
If chart dependencies are missing:
```bash
cd gcp-deployer/chart
helm dependency update
```

### Deployment Failures
Check deployer logs:
```bash
kubectl logs -n default -l app.kubernetes.io/name=wso2-apim-deployer
```

## Clean Up

To remove the deployment:

```bash
mpdev delete \
  --name=wso2-apim-test \
  --namespace=default
```

## Additional Resources

- [GCP Marketplace Documentation](https://cloud.google.com/marketplace/docs/kubernetes-apps)
- [Kubernetes Application CRD](https://github.com/kubernetes-sigs/application)
- [WSO2 APIM Documentation](https://apim.docs.wso2.com/)
