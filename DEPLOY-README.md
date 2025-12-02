# WSO2 APIM Kubernetes Deployment Assets

This repository contains deployment assets for WSO2 API Manager on Google Cloud Platform Kubernetes.

## Quick Clone and Deploy

```bash
# Clone the deployment assets
git clone https://github.com/sgayangi/gcp-apim-kubernetes.git
cd gcp-apim-kubernetes/gcp-deployer
```

## Prerequisites

- kubectl (Kubernetes CLI)
- gcloud (Google Cloud SDK)
- Helm 3.x
- A running GKE cluster

## Quick Start

### Option 1: Interactive Deployment

```bash
./deploy-cli.sh
```

### Option 2: Using mpdev

```bash
# Install mpdev
docker pull gcr.io/cloud-marketplace-tools/k8s/dev:latest

# Set up environment
export APP_INSTANCE_NAME=wso2-apim-1
export NAMESPACE=default

# Deploy
mpdev install \
  --deployer=us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5 \
  --parameters='{"name": "'${APP_INSTANCE_NAME}'", "namespace": "'${NAMESPACE}'"}'
```

### Option 3: Using Helm

```bash
# Install with Helm
helm install wso2-apim-1 \
  --namespace default \
  --create-namespace \
  --set gcp.enabled=true \
  --set acp.enabled=true \
  --set apk.enabled=true \
  --set apkagent.enabled=true \
  ./chart
```

## Documentation

- [Detailed CLI Deployment Guide](gcp-deployer/CLI-DEPLOYMENT.md)
- [Getting Started Guide](gcp-deployer/GETTING-STARTED.md)
- [Main README](gcp-deployer/README.md)

## Repository Structure

```
gcp-apim-kubernetes/
├── gcp-deployer/           # GCP Marketplace deployer
│   ├── chart/             # Helm chart
│   ├── deploy-cli.sh      # Quick deployment script
│   ├── CLI-DEPLOYMENT.md  # CLI deployment guide
│   └── schema.yaml        # Marketplace schema
├── helm-charts/           # Source Helm charts
└── terraform/             # Terraform deployment (optional)
```

## Support

For issues and questions:
- [GitHub Issues](https://github.com/sgayangi/gcp-apim-kubernetes/issues)
- [WSO2 Documentation](https://apim.docs.wso2.com/)

## License

See [LICENSE](LICENSE) file for details.
