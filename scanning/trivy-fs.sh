#!/bin/bash

# Create result directory if it does not exist
mkdir -p result

# Scan the file system for vulnerabilities and secrets, and save the output to a file
trivy fs --scanners secret --format json --output result/trivy_fs_report.json .

# Save the plain text scan results to trivy-fs.txt
trivy fs --scanners secret --format table . > result/trivy-fs.txt

# Check for high or critical vulnerabilities
if jq '.Results[].Vulnerabilities[] | select(.Severity == "HIGH" or .Severity == "CRITICAL")' result/trivy_fs_report.json | grep -q .; then
  echo "High or critical vulnerabilities found in file system scan!"
  exit 1
fi

# Check for secrets
if jq '.Results[].Secrets[]' result/trivy_fs_report.json | grep -q .; then
  echo "Secrets found in file system scan!"
  exit 1
fi

echo "No high or critical vulnerabilities or secrets found in file system scan."
