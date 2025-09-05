#!/bin/bash

# Comprehensive test runner for Dairy Management System
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
UNIT_TESTS_PASSED=false
API_TESTS_PASSED=false
E2E_TESTS_PASSED=false
LOAD_TESTS_PASSED=false
DB_TESTS_PASSED=false

echo -e "${BLUE}🧪 Dairy Management System - Comprehensive Test Suite${NC}"
echo "=================================================================="

# Load environment variables
if [ -f ".env.tests" ]; then
    echo "📋 Loading environment variables..."
    export $(cat .env.tests | xargs)
else
    echo "⚠️  .env.tests file not found. Using default values."
fi

# Validate required environment variables
echo "🔍 Validating environment variables..."
if [ -z "$API_BASE_URL" ]; then
    echo -e "${RED}❌ API_BASE_URL environment variable is required${NC}"
    exit 1
fi

if [ -z "$DB_CONN" ]; then
    echo -e "${YELLOW}⚠️  DB_CONN not set. Database validation tests will be skipped.${NC}"
fi

echo -e "${GREEN}✅ Environment validation passed${NC}"
echo "   API_BASE_URL: $API_BASE_URL"

# Create report directory
mkdir -p report
echo "📁 Created report directory"

# Initialize results JSON
cat > report/results.json << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": {
    "API_BASE_URL": "$API_BASE_URL",
    "hasDbConnection": $([ -n "$DB_CONN" ] && echo "true" || echo "false")
  },
  "tests": {}
}
EOF

# Function to update results
update_results() {
    local test_name=$1
    local status=$2
    local duration=$3
    local details=$4
    
    # Use jq if available, otherwise simple append
    if command -v jq &> /dev/null; then
        jq --arg name "$test_name" --arg status "$status" --arg duration "$duration" --arg details "$details" \
           '.tests[$name] = {"status": $status, "duration": $duration, "details": $details}' \
           report/results.json > report/results.tmp && mv report/results.tmp report/results.json
    fi
}

# 1. Backend Unit Tests
echo -e "\n${YELLOW}1️⃣  Running Backend Unit Tests...${NC}"
start_time=$(date +%s)

if dotnet test backend/Dairy.Api.Tests --logger "trx;LogFileName=unit-tests.trx" --results-directory report/; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo -e "${GREEN}✅ Backend Unit Tests Passed (${duration}s)${NC}"
    UNIT_TESTS_PASSED=true
    update_results "unit_tests" "passed" "${duration}s" "All unit tests passed"
else
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo -e "${RED}❌ Backend Unit Tests Failed (${duration}s)${NC}"
    update_results "unit_tests" "failed" "${duration}s" "Some unit tests failed"
fi

# 2. API Tests with Newman
echo -e "\n${YELLOW}2️⃣  Running API Tests with Newman...${NC}"
start_time=$(date +%s)

if bash newman/run.sh; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo -e "${GREEN}✅ API Tests Passed (${duration}s)${NC}"
    API_TESTS_PASSED=true
    update_results "api_tests" "passed" "${duration}s" "All API tests passed"
else
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo -e "${RED}❌ API Tests Failed (${duration}s)${NC}"
    update_results "api_tests" "failed" "${duration}s" "Some API tests failed"
fi

# 3. E2E Tests with Playwright (if available)
echo -e "\n${YELLOW}3️⃣  Running E2E Tests with Playwright...${NC}"
start_time=$(date +%s)

if command -v npx &> /dev/null && [ -d "node_modules/@playwright/test" ]; then
    if npx playwright test --project=chromium frontend/playwright --reporter=json --output-dir=report/playwright; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✅ E2E Tests Passed (${duration}s)${NC}"
        E2E_TESTS_PASSED=true
        update_results "e2e_tests" "passed" "${duration}s" "All E2E tests passed"
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}❌ E2E Tests Failed (${duration}s)${NC}"
        update_results "e2e_tests" "failed" "${duration}s" "Some E2E tests failed"
    fi
else
    echo -e "${YELLOW}⚠️  Playwright not available. Skipping E2E tests.${NC}"
    update_results "e2e_tests" "skipped" "0s" "Playwright not installed"
fi

# 4. Load Tests with k6 (if available)
echo -e "\n${YELLOW}4️⃣  Running Load Tests with k6...${NC}"
start_time=$(date +%s)

if command -v k6 &> /dev/null; then
    if k6 run --out json=report/k6-results.json load/k6/collections.js; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✅ Load Tests Passed (${duration}s)${NC}"
        LOAD_TESTS_PASSED=true
        update_results "load_tests" "passed" "${duration}s" "Load tests completed successfully"
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}❌ Load Tests Failed (${duration}s)${NC}"
        update_results "load_tests" "failed" "${duration}s" "Load tests failed"
    fi
else
    echo -e "${YELLOW}⚠️  k6 not available. Skipping load tests.${NC}"
    update_results "load_tests" "skipped" "0s" "k6 not installed"
fi

# 5. Generate HTML Report
echo -e "\n${YELLOW}5️⃣  Generating Test Report...${NC}"

# Copy template and generate report
cp report/template-index.html report/index.html 2>/dev/null || cat > report/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Dairy Management System - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .pass { color: #27ae60; font-weight: bold; }
        .fail { color: #e74c3c; font-weight: bold; }
        .skip { color: #f39c12; font-weight: bold; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .metric { background: #ecf0f1; padding: 15px; border-radius: 5px; text-align: center; }
        .metric h3 { margin: 0 0 10px 0; }
        .links { margin: 20px 0; }
        .links a { display: inline-block; margin: 5px 10px 5px 0; padding: 8px 15px; background: #3498db; color: white; text-decoration: none; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Dairy Management System - Test Report</h1>
            <p>Generated on: <span id="timestamp"></span></p>
            <p>API Base URL: <span id="api-url"></span></p>
        </div>

        <div class="summary">
            <div class="metric">
                <h3>Unit Tests</h3>
                <div id="unit-status" class="status">-</div>
            </div>
            <div class="metric">
                <h3>API Tests</h3>
                <div id="api-status" class="status">-</div>
            </div>
            <div class="metric">
                <h3>E2E Tests</h3>
                <div id="e2e-status" class="status">-</div>
            </div>
            <div class="metric">
                <h3>Load Tests</h3>
                <div id="load-status" class="status">-</div>
            </div>
        </div>

        <div class="links">
            <h3>📋 Detailed Reports</h3>
            <a href="postman-report.html" target="_blank">API Test Report</a>
            <a href="unit-tests.trx" target="_blank">Unit Test Results</a>
            <a href="results.json" target="_blank">Raw Results (JSON)</a>
        </div>

        <div class="test-section">
            <h3>🔍 Test Execution Summary</h3>
            <div id="test-details"></div>
        </div>
    </div>

    <script>
        // Load and display results
        fetch('results.json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('timestamp').textContent = new Date(data.timestamp).toLocaleString();
                document.getElementById('api-url').textContent = data.environment.API_BASE_URL;
                
                // Update status indicators
                Object.entries(data.tests).forEach(([testName, result]) => {
                    const elementId = testName.replace('_', '-') + '-status';
                    const element = document.getElementById(elementId);
                    if (element) {
                        element.textContent = result.status.toUpperCase();
                        element.className = 'status ' + result.status;
                    }
                });
                
                // Generate test details
                const detailsDiv = document.getElementById('test-details');
                let detailsHtml = '';
                Object.entries(data.tests).forEach(([testName, result]) => {
                    const statusClass = result.status === 'passed' ? 'pass' : result.status === 'failed' ? 'fail' : 'skip';
                    detailsHtml += `
                        <p><strong>${testName.replace('_', ' ').toUpperCase()}:</strong> 
                        <span class="${statusClass}">${result.status.toUpperCase()}</span> 
                        (${result.duration}) - ${result.details}</p>
                    `;
                });
                detailsDiv.innerHTML = detailsHtml;
            })
            .catch(error => {
                console.error('Error loading results:', error);
                document.getElementById('test-details').innerHTML = '<p class="fail">Error loading test results</p>';
            });
    </script>
</body>
</html>
EOF

echo -e "${GREEN}✅ Test report generated: report/index.html${NC}"

# Final Summary
echo -e "\n${BLUE}🏁 Test Execution Summary${NC}"
echo "=================================="
echo -e "Unit Tests:    $([ "$UNIT_TESTS_PASSED" = true ] && echo "${GREEN}PASSED${NC}" || echo "${RED}FAILED${NC}")"
echo -e "API Tests:     $([ "$API_TESTS_PASSED" = true ] && echo "${GREEN}PASSED${NC}" || echo "${RED}FAILED${NC}")"
echo -e "E2E Tests:     $([ "$E2E_TESTS_PASSED" = true ] && echo "${GREEN}PASSED${NC}" || echo "${YELLOW}SKIPPED${NC}")"
echo -e "Load Tests:    $([ "$LOAD_TESTS_PASSED" = true ] && echo "${GREEN}PASSED${NC}" || echo "${YELLOW}SKIPPED${NC}")"

echo -e "\n📊 Reports available in: ${BLUE}tests/report/${NC}"
echo -e "📋 Main report: ${BLUE}tests/report/index.html${NC}"

# Exit with appropriate code
if [ "$UNIT_TESTS_PASSED" = true ] && [ "$API_TESTS_PASSED" = true ]; then
    echo -e "\n${GREEN}🎉 Core tests passed! System is ready for deployment.${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Critical tests failed! Please review and fix issues.${NC}"
    exit 1
fi