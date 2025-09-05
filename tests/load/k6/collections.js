import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 100 },  // Stay at 100 users (300 collections/min)
    { duration: '2m', target: 200 },  // Ramp up to 200 users
    { duration: '3m', target: 200 },  // Stay at 200 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests under 2s
    http_req_failed: ['rate<0.1'],     // Error rate under 10%
    errors: ['rate<0.1'],
  },
};

// Environment variables
const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:8081';
const API_KEY = __ENV.API_KEY || '';

export function setup() {
  // Login and get token if needed
  if (!API_KEY) {
    const loginRes = http.post(`${API_BASE_URL}/api/auth/login`, JSON.stringify({
      username: 'admin',
      password: 'admin123'
    }), {
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (loginRes.status === 200) {
      const token = loginRes.json('token');
      return { token };
    }
  }
  
  return { token: API_KEY };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
  };
  
  if (data.token) {
    headers['Authorization'] = `Bearer ${data.token}`;
  }

  // Generate random collection data
  const collection = {
    farmerId: Math.floor(Math.random() * 100) + 1,
    shiftId: Math.floor(Math.random() * 2) + 1,
    date: new Date().toISOString().split('T')[0],
    weightKg: Math.round((Math.random() * 40 + 10) * 10) / 10, // 10-50 kg
    fat: Math.round((Math.random() * 3 + 3) * 10) / 10,        // 3-6%
    snf: Math.round((Math.random() * 2 + 8) * 10) / 10,        // 8-10%
    rate: 52.50
  };

  // Create collection
  const response = http.post(`${API_BASE_URL}/api/collections`, JSON.stringify(collection), {
    headers,
    timeout: '30s',
  });

  // Validate response
  const success = check(response, {
    'status is 201': (r) => r.status === 201,
    'response time < 2s': (r) => r.timings.duration < 2000,
    'has collection id': (r) => r.json('id') !== undefined,
  });

  if (!success) {
    errorRate.add(1);
  }

  // Test get collections endpoint
  const getResponse = http.get(`${API_BASE_URL}/api/collections?limit=10`, { headers });
  
  check(getResponse, {
    'get collections status is 200': (r) => r.status === 200,
    'get collections response time < 1s': (r) => r.timings.duration < 1000,
  });

  // Simulate realistic user behavior
  sleep(Math.random() * 2 + 1); // 1-3 seconds between requests
}

export function teardown(data) {
  console.log('Load test completed');
}