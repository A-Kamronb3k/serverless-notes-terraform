#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform"

API_URL=$(terraform output -raw api_endpoint)
BUCKET=$(terraform output -raw frontend_bucket_name)
DIST_ID=$(terraform output -raw frontend_distribution_id)

echo "window.APP_CONFIG = { apiUrl: \"${API_URL}\" };" > ../frontend/config.js

aws s3 sync ../frontend "s3://${BUCKET}" --delete --exclude "config.example.js"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*"