ARG MARKETPLACE_TOOLS_TAG=latest
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:0.12.10

# Add GCP Marketplace annotation
LABEL com.googleapis.cloudmarketplace.product.service.name="services/wso2-apim-apk.endpoints.wso2-marketplace-public.cloud.goog"

# Copy the Helm chart tarball into /data/chart/ directory
# The deployer will find and extract all *.tar.gz files in this directory
COPY chart.tar.gz /data/chart/chart.tar.gz

# Copy the Marketplace deployer schema
COPY schema.yaml /data/schema.yaml

# Copy test configuration for verification
COPY data-test/ /data-test/
