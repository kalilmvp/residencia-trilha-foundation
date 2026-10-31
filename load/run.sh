#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${K6_USERNAME:-}" || -z "${K6_PASSWORD:-}" ]]; then
  echo "Set K6_USERNAME and K6_PASSWORD for a Cognito user that already completed first sign-in." >&2
  exit 1
fi

if ! command -v k6 >/dev/null 2>&1; then
  echo "Install Grafana k6 first: brew install k6" >&2
  exit 1
fi

# One level per run. K6_VUS=1, 2, 5, ... and K6_DURATION=2m by default.
# Two minutes gives one steady CloudWatch minute. Use K6_DURATION=1m for a shorter sample.
export K6_VUS="${K6_VUS:-1}"
export K6_DURATION="${K6_DURATION:-2m}"
echo "Running ${K6_VUS} users for ${K6_DURATION}" >&2

# Stage "api" is the stage the site calls through CloudFront at /api.
# This URL hits API Gateway directly. Override K6_API_URL to use another stage.
export K6_API_URL="${K6_API_URL:-https://zxvkucxsu7.execute-api.us-east-1.amazonaws.com/api}"

# macOS bash does not abort on a failing command substitution, so check it explicitly.
K6_ID_TOKEN="$(node load/login.mjs)" || exit 1
if [[ -z "${K6_ID_TOKEN}" ]]; then
  echo "Cognito did not return an ID token." >&2
  exit 1
fi
export K6_ID_TOKEN

exec k6 run load/catalog-orders.js
