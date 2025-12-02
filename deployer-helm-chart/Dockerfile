# You can pin a version of deployer_helm if you want
ARG BASE_IMAGE=gcr.io/cloud-marketplace-tools/k8s/deployer_helm:latest
FROM ${BASE_IMAGE}

# Copy your Helm chart into the expected location
COPY chart/ /data/chart/

# Copy the Marketplace deployer schema
COPY schema.yaml /data/schema.yaml
