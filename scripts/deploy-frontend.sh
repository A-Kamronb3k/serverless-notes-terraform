#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform"

API_URL=$(terraform output -raw api_endpoint)
BUCKET=$(terraform output -raw frontend_bucket_name)
DIST_ID=$(terraform output -raw frontend_distribution_id)

# Cognito settings for the hosted-UI login flow
COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
COGNITO_DOMAIN=$(terraform output -raw cognito_domain)

# Generate config.js from live terraform outputs (never committed)
cat <<EOF > ../frontend/config.js
window.APP_CONFIG = {
  apiUrl: "${API_URL}",
  cognitoDomain: "${COGNITO_DOMAIN}",
  cognitoClientId: "${COGNITO_CLIENT_ID}"
};
EOF

aws s3 sync ../frontend "s3://${BUCKET}" --delete --exclude "config.example.js"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*"
