# Dairy Management System - Test Suite

## Overview
Comprehensive automated testing for the Dairy Milk Collection & Sales Management System.

## Test Types
- **API Tests**: Postman/Newman collection testing all endpoints
- **Backend Tests**: xUnit integration tests with database validation
- **Frontend Tests**: Playwright E2E tests
- **Load Tests**: k6 performance testing
- **Security Tests**: SQL injection, XSS prevention

## Prerequisites
- .NET 8 SDK
- Node.js 18+
- Newman (`npm install -g newman`)
- Playwright (`npx playwright install`)
- k6 (optional, for load tests)

## Environment Variables
Create `tests/.env.tests` (gitignored) with:
```
API_BASE_URL=https://your-api.render.com
API_KEY=your-jwt-token-here
DB_CONN=postgres://user:pass@host:5432/dbname?sslmode=require
PGHOST=localhost
PGUSER=admin
PGPASSWORD=admin123
PGDATABASE=postgres
PGPORT=5432
PGSSLMODE=require
```

## Quick Start
```bash
# Install dependencies
npm install

# Run all tests
./tests/scripts/run-all.sh

# Run specific test types
npm run test:postman
npm run test:backend
npm run test:playwright
npm run test:load
```

## CI/CD
Tests run automatically on push via GitHub Actions. See `.github/workflows/tests-run.yml`.

## Reports
Results are generated in `tests/report/`:
- `index.html` - Summary dashboard
- `results.json` - Structured test results
- Individual test reports in subfolders