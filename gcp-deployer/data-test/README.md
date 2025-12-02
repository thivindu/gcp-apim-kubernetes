# Tester image is now built inline - no separate build needed
# The tester pod uses kubectl which is already available in standard images

# For reference, if you need a custom tester image, use:
# gcr.io/cloud-marketplace-tools/testrunner:0.1.5
# or
# google/cloud-sdk:slim

# The deployer will automatically run the test pod defined in data-test/chart/templates/tester.yaml
