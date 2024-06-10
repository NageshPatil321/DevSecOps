#!/bin/bash

# Create result directory if it does not exist
mkdir -p result

# Scan the Docker image for vulnerabilities and save the output to a file
trivy image nagesh0205/youtube-clone:latest --format json --output result/trivy_image_report.json

# Save the plain text scan results to trivy-image.txt
trivy image nagesh0205/youtube-clone:latest --format table > result/trivy-image.txt

# Define your policy criteria
SEVERITY="HIGH,CRITICAL"
CVSS_THRESHOLD=7.0

# Convert comma-separated lists to arrays
IFS=',' read -r -a SEVERITY_ARRAY <<< "$SEVERITY"

# Check for high or critical vulnerabilities
if jq '.Results[].Vulnerabilities[] | select(.Severity == "HIGH" or .Severity == "CRITICAL")' result/trivy_image_report.json | grep -q .; then
  echo "High or critical vulnerabilities found in image scan!"
  exit 1
fi

# Check for CVSS score
if jq --argjson threshold "$CVSS_THRESHOLD" '.Results[].Vulnerabilities[] | select(.CVSS.nvd.V3Score >= $threshold)' result/trivy_image_report.json | grep -q .; then
  echo "Vulnerabilities with CVSS score >= $CVSS_THRESHOLD found in image scan!"
  exit 1
fi

echo "No high or critical vulnerabilities or severe vulnerabilities found in image scan."
