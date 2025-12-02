#!/usr/bin/env bash
set -euo pipefail

# Config
IMAGE_REPO="us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/wso2am-acp"
TAG="4.5"

ANNOTATION_KEY="com.googleapis.cloudmarketplace.product.service.name"
ANNOTATION_VALUE="services/wso2-apim-apk.endpoints.wso2-marketplace-public.cloud.goog"

IMAGE="${IMAGE_REPO}:${TAG}"

echo "Image: ${IMAGE}"
echo "Updating annotation:"
echo "  ${ANNOTATION_KEY} = ${ANNOTATION_VALUE}"
echo

# Check dependencies
for cmd in crane jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is not installed or not on PATH." >&2
    exit 1
  fi
done

echo "Fetching index manifest..."
INDEX_JSON="$(crane manifest "${IMAGE}")"

MEDIA_TYPE="$(printf '%s\n' "${INDEX_JSON}" | jq -r '.mediaType')"

if [ "${MEDIA_TYPE}" != "application/vnd.oci.image.index.v1+json" ] && \
   [ "${MEDIA_TYPE}" != "application/vnd.docker.distribution.manifest.list.v2+json" ]; then
  echo "Error: ${IMAGE} is not a multi platform index (mediaType=${MEDIA_TYPE})." >&2
  echo "If it is a single image you can probably run:" >&2
  echo "  crane mutate --annotation ${ANNOTATION_KEY}=${ANNOTATION_VALUE} -t ${IMAGE} ${IMAGE}" >&2
  exit 1
fi

echo "Image is a multi platform index. Processing per platform manifests..."
echo

# We read digest and platform together so they stay aligned
MANIFEST_LINES="$(printf '%s\n' "${INDEX_JSON}" \
  | jq -r '.manifests[] | "\(.digest) \(.platform.os)/\(.platform.architecture)"')"

if [ -z "${MANIFEST_LINES}" ]; then
  echo "Error: no manifests found in index." >&2
  exit 1
fi

TMP_TAGS=()

# Tag and mutate each platform manifest
echo "${MANIFEST_LINES}" | while read -r digest platform; do
  if [ -z "${digest}" ] || [ -z "${platform}" ]; then
    continue
  fi

  tmp_tag="${TAG}-${platform//\//-}-tmp"
  tmp_ref="${IMAGE_REPO}:${tmp_tag}"

  echo "Processing platform ${platform}"
  echo "  Source digest: ${digest}"
  echo "  Temp tag:      ${tmp_ref}"

  # Tag digest with temp tag
  # IMPORTANT: second arg is just the tag name, not repo:tag
  crane tag "${IMAGE_REPO}@${digest}" "${tmp_tag}"

  # Mutate annotation on the temp tag
  crane mutate \
    --annotation "${ANNOTATION_KEY}=${ANNOTATION_VALUE}" \
    -t "${tmp_ref}" \
    "${tmp_ref}"

  TMP_TAGS+=("${tmp_ref}")
  echo "  Annotation updated on ${tmp_ref}"
  echo
done

# Because `while` in a pipe runs in a subshell in bash, re-derive TMP_TAGS from the registry
# instead of relying on the array from inside the loop.
echo "Collecting mutated temp tags from registry..."
TMP_TAGS=()
for ref in $(crane ls "${IMAGE_REPO}" | grep "^${TAG}-" || true); do
  TMP_TAGS+=("${IMAGE_REPO}:${ref}")
done

if [ "${#TMP_TAGS[@]}" -eq 0 ]; then
  echo "Error: no temp tags found after mutation. Something went wrong." >&2
  exit 1
fi

echo "Rebuilding multi platform index on original tag: ${IMAGE}"
APPEND_ARGS=()
for t in "${TMP_TAGS[@]}"; do
  echo "  Including ${t} in new index"
  APPEND_ARGS+=("-m" "$t")
done

crane index append "${APPEND_ARGS[@]}" -t "${IMAGE}"

echo
echo "Verifying annotations on per platform manifests in the new index..."

crane manifest "${IMAGE}" \
  | jq '.manifests[] | {platform, annotations}'

echo
echo "Done."
echo "The image ${IMAGE} now should have ${ANNOTATION_KEY} set to:"
echo "  ${ANNOTATION_VALUE}"
