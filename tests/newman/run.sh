#!/bin/bash

# Newman test runner script
set -e

echo "🧪 Running API Tests with Newman..."

# Load environment variables if .env.tests exists
if [ -f "../.env.tests" ]; then
    export $(cat ../.env.tests | xargs)
fi

# Validate required environment variables
if [ -z "$API_BASE_URL" ]; then
    echo "❌ API_BASE_URL environment variable is required"
    exit 1
fi

# Create report directory
mkdir -p ../report

# Run Newman with collection and environment
newman run ../postman/collection.json \
    -e ../postman/environments/local.postman_environment.json \
    --env-var "API_BASE_URL=$API_BASE_URL" \
    --env-var "API_KEY=$API_KEY" \
    --reporters cli,json,htmlextra \
    --reporter-json-export ../report/postman-results.json \
    --reporter-htmlextra-export ../report/postman-report.html \
    --reporter-htmlextra-title "Dairy Management API Tests" \
    --reporter-htmlextra-showOnlyFails false \
    --timeout-request 30000 \
    --delay-request 100

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ All API tests passed!"
    exit 0
else
    echo "❌ Some API tests failed!"
    exit 1
fi