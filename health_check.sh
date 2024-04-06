#!/bin/bash
set -x

# Fetch the ALB DNS name from terraform state
ALB_DNS="$(terraform output -state=tf/terraform.tfstate -raw alb_dns_name)"

# Endpoint to check
ENDPOINT="http://${ALB_DNS}/health"

# Expected HTTP status code
EXPECTED_STATUS=200

# Curl the endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $ENDPOINT)

# Check if the status matches the expected status
if [ $HTTP_STATUS -eq $EXPECTED_STATUS ]; then
  echo "Health check passed!"
  exit 0
else
  echo "Health check failed! Expected HTTP status: $EXPECTED_STATUS, got: $HTTP_STATUS"
  exit 1
fi
