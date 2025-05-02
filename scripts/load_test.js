import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
import { Trend, Rate, Counter } from 'k6/metrics';

// Custom metrics
const threadListTrend = new Trend('thread_list_request_duration');
const threadGetTrend = new Trend('thread_get_request_duration');
const threadCreateTrend = new Trend('thread_create_request_duration');
const messageListTrend = new Trend('message_list_request_duration');
const messageCreateTrend = new Trend('message_create_request_duration');
const errorRate = new Rate('error_rate');
const successRate = new Rate('success_rate');
const requestCount = new Counter('requests');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 5 }, // Ramp up to 5 users over 30 seconds
    { duration: '1m', target: 10 }, // Ramp up to 10 users over 1 minute
    { duration: '2m', target: 20 }, // Ramp up to 20 users over 2 minutes
    { duration: '1m', target: 0 },  // Ramp down to 0 users over 1 minute
  ],
  thresholds: {
    thread_list_request_duration: ['p95<500', 'p99<1000'],
    thread_get_request_duration: ['p95<300', 'p99<600'],
    thread_create_request_duration: ['p95<800', 'p99<1500'],
    message_list_request_duration: ['p95<500', 'p99<1000'],
    message_create_request_duration: ['p95<800', 'p99<1500'],
    error_rate: ['rate<0.1'], // Error rate should be less than 10%
    http_req_duration: ['p95<500'], // 95% of requests should be below 500ms
  },
};

// Shared variables
const BASE_URL = __ENV.API_URL || 'http://localhost:3001';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6aWNuOnRlc3QiLCJpYXQiOjE2MjUwMDAwMDAsImV4cCI6MjUyNTAwMDAwMH0.test_signature';
const THREAD_IDS = [];

// Common headers
const HEADERS = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${AUTH_TOKEN}`,
};

// HTTP request wrapper with tracking
function trackRequest(name, trend, requestFn) {
  const startTime = new Date();
  const response = requestFn();
  const duration = new Date() - startTime;
  trend.add(duration);
  requestCount.add(1);
  
  const success = response.status >= 200 && response.status < 300;
  successRate.add(success);
  errorRate.add(!success);

  if (!success) {
    console.log(`Request ${name} failed with status ${response.status}: ${response.body}`);
  }
  
  return response;
}

// Helper to create thread and store ID
function createThreadAndStore() {
  const title = `Load Test Thread ${randomString(8)}`;
  const payload = JSON.stringify({
    title: title,
    proposal_cid: null
  });
  
  const response = trackRequest('Create Thread', threadCreateTrend, () => 
    http.post(`${BASE_URL}/api/threads`, payload, { headers: HEADERS }));
  
  if (response.status === 200 || response.status === 201) {
    try {
      const data = JSON.parse(response.body);
      THREAD_IDS.push(data.id);
      return data.id;
    } catch (e) {
      console.error(`Failed to parse response: ${e.message}`);
    }
  }
  return null;
}

// List threads test
function listThreads() {
  trackRequest('List Threads', threadListTrend, () => 
    http.get(`${BASE_URL}/api/threads?limit=10&offset=0`, { headers: HEADERS }));
}

// Get single thread test
function getThread(threadId) {
  if (!threadId) return;
  
  trackRequest('Get Thread', threadGetTrend, () => 
    http.get(`${BASE_URL}/api/threads/${threadId}`, { headers: HEADERS }));
}

// List messages in thread test
function listMessages(threadId) {
  if (!threadId) return;
  
  trackRequest('List Messages', messageListTrend, () => 
    http.get(`${BASE_URL}/api/threads/${threadId}/messages?limit=20`, { headers: HEADERS }));
}

// Create message in thread test
function createMessage(threadId) {
  if (!threadId) return;
  
  const content = `This is a load test message ${randomString(12)}`;
  const payload = JSON.stringify({
    content: content
  });
  
  trackRequest('Create Message', messageCreateTrend, () => 
    http.post(`${BASE_URL}/api/threads/${threadId}/messages`, payload, { headers: HEADERS }));
}

// Main test function
export default function() {
  // First create some threads if we don't have enough
  if (THREAD_IDS.length < 5) {
    const threadId = createThreadAndStore();
    sleep(1);
    return;
  }
  
  // Pick a random thread ID from existing ones
  const randomIndex = Math.floor(Math.random() * THREAD_IDS.length);
  const threadId = THREAD_IDS[randomIndex];
  
  // Randomly choose what operation to perform
  const choice = Math.random();
  
  if (choice < 0.35) {
    // 35% of the time, list threads
    listThreads();
  } else if (choice < 0.60) {
    // 25% of the time, get a specific thread
    getThread(threadId);
  } else if (choice < 0.80) {
    // 20% of the time, list messages in a thread
    listMessages(threadId);
  } else {
    // 20% of the time, create a message in a thread
    createMessage(threadId);
  }
  
  // Add some randomized sleep between requests
  sleep(Math.random() * 3 + 1);
} 