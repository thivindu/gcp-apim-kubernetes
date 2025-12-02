# WSO2 APIM Chart Patching Notes

## Issue

The official `wso2am-all-in-one` chart version 4.5.0-1 from https://helm.wso2.com contains a bug in its `templates/_helpers.tpl` file that prevents it from working as a Helm sub-chart dependency.

### Root Cause

The chart's `_helpers.tpl` defines an unused `image` template helper (lines 68-82) that tries to access `.deployment.imageName` and `.deployment.imageTag` fields that don't exist in the chart's values structure. When used as a sub-chart, Helm evaluates all templates including unused helpers, causing the template rendering to fail with:

```
Error: template: wso2-apim-kubernetes/charts/apim/templates/_helpers.tpl:68:29: 
executing "image" at <.deployment.imageName>: can't evaluate field deployment in type []interface {}
```

The chart actually uses `.Values.wso2.deployment.image.registry/repository/digest` structure directly in its deployment.yaml and never calls the buggy `image` helper template.

## Solution

We've created a patched version of the chart by:

1. Extracting the official chart from the `.tgz` archive
2. Replacing the buggy `image` template in `_helpers.tpl` with an empty, safe version:

```helm
{{- define "image" }}
{{- /* This template is deprecated and not used in this chart version */ -}}
{{- /* The actual image is defined directly in the deployment using .Values.wso2.deployment.image.* */ -}}
{{- end -}}
```

3. Using the patched chart as a local file dependency in `Chart.yaml`:

```yaml
dependencies:
  - name: wso2am-all-in-one
    version: 4.5.0-1
    repository: file://./charts/wso2am-all-in-one-patched
    alias: apim
    condition: apim.enabled
```

## Chart Structure

```
helm-charts/wso2-apim-kubernetes/
├── Chart.yaml                          # Parent chart with dependencies
├── values.yaml                         # Unified configuration
├── charts/
│   ├── wso2am-all-in-one-patched/     # Patched APIM chart (local)
│   ├── apk-helm-1.3.0-1.tgz           # APK chart (from GitHub)
│   └── apim-apk-agent-1.3.0.tgz       # APK Agent chart (from GitHub)
└── templates/
    └── nginx-ingress.yaml              # Conditional nginx ingress
```

## Testing

The patched chart successfully renders 199 Kubernetes resources:

```bash
helm template test . | grep -c "^kind:"
# Output: 199
```

## Upstream Report

This issue should be reported to WSO2 so they can fix it in future releases of the `wso2am-all-in-one` chart. The fix is simple - either remove the unused `image` template or make it safe to evaluate in all contexts.

## Maintenance

When upgrading to a newer version of `wso2am-all-in-one`:

1. Check if the issue is fixed upstream by testing the chart as a sub-chart
2. If still broken, re-apply this patch to the new version
3. Update the version number in Chart.yaml accordingly

## Files Modified

- `charts/wso2am-all-in-one-patched/templates/_helpers.tpl` - Replaced buggy image template
- `Chart.yaml` - Changed repository from `https://helm.wso2.com` to `file://./charts/wso2am-all-in-one-patched`
