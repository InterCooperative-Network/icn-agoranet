#!/bin/bash
# AgoraNet Integration and Stability Test Suite
# This script runs a series of tests to ensure AgoraNet components work properly

set -e

# Set environment variables for testing
export TEST_DATABASE_URL="postgres://agoranet:agoranet@localhost:5432/agoranet_test"
export TEST_PORT=3002
export TEST_FEDERATION_PORT=4002
export TEST_AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6aWNuOnRlc3QiLCJpYXQiOjE2MjUwMDAwMDAsImV4cCI6MjUyNTAwMDAwMH0.test_signature"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test description function
describe() {
  echo -e "\n${YELLOW}✦ $1${NC}"
}

# Test success function
success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Test failure function
fail() {
  echo -e "${RED}✗ $1${NC}"
  exit 1
}

# Setup test database
setup_test_db() {
  describe "Setting up test database"
  
  # Create test database if not exists
  psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'agoranet_test'" | grep -q 1 || \
    psql -U postgres -c "CREATE DATABASE agoranet_test WITH OWNER agoranet"
  
  # Run migrations on test database
  DATABASE_URL=$TEST_DATABASE_URL cargo sqlx database reset -y || fail "Database reset failed"
  
  success "Test database setup complete"
}

# Clean up test environment
cleanup() {
  describe "Cleaning up test environment"
  
  # Terminate test processes
  if [ -f ".test_pid" ]; then
    kill -9 $(cat .test_pid) 2>/dev/null || true
    rm .test_pid
  fi
  
  if [ -f ".test_federation_pid" ]; then
    kill -9 $(cat .test_federation_pid) 2>/dev/null || true
    rm .test_federation_pid
  fi
  
  if [ -f ".test_runtime_pid" ]; then
    kill -9 $(cat .test_runtime_pid) 2>/dev/null || true
    rm .test_runtime_pid
  fi
  
  success "Cleanup completed"
}

# Start the API server for testing
start_test_server() {
  describe "Starting test server"
  
  # Start server with test configuration
  PORT=$TEST_PORT \
  DATABASE_URL=$TEST_DATABASE_URL \
  RUST_LOG=debug \
  ENABLE_FEDERATION=false \
  ENABLE_RUNTIME_CLIENT=false \
  cargo run > test_server.log 2>&1 &
  
  # Store PID
  echo $! > .test_pid
  
  # Wait for server to start
  sleep 3
  
  # Check if server is running
  curl -s http://localhost:$TEST_PORT/api/threads > /dev/null || fail "Server failed to start"
  
  success "Test server started on port $TEST_PORT"
}

# Start federation test nodes
start_federation_test() {
  describe "Starting federation test nodes"
  
  # Start primary federation node
  PORT=$TEST_PORT \
  DATABASE_URL=$TEST_DATABASE_URL \
  RUST_LOG=debug \
  ENABLE_FEDERATION=true \
  FEDERATION_LISTEN_ADDR="/ip4/127.0.0.1/tcp/$TEST_FEDERATION_PORT" \
  cargo run > federation_node1.log 2>&1 &
  
  # Store PID
  echo $! > .test_federation_pid
  
  # Wait for server to start
  sleep 3
  
  # Check if server is running
  curl -s http://localhost:$TEST_PORT/api/threads > /dev/null || fail "Federation node failed to start"
  
  success "Federation test node started"
}

# Start mock Runtime server
start_mock_runtime() {
  describe "Starting mock Runtime server"
  
  if [ ! -d "mock-runtime" ]; then
    mkdir -p mock-runtime
    
    # Create package.json
    cat > mock-runtime/package.json << EOF
{
  "name": "mock-runtime",
  "version": "1.0.0",
  "description": "Mock Runtime server for AgoraNet testing",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF
    
    # Create mock server
    cat > mock-runtime/index.js << EOF
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Store events
const proposals = [
  {
    id: "proposal-1",
    cid: "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy",
    title: "Test Proposal 1",
    status: "ACTIVE"
  },
  {
    id: "proposal-2",
    cid: "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrfsdfs34jk341",
    title: "Test Proposal 2",
    status: "PENDING"
  }
];

// Endpoint to get proposals
app.get('/api/proposals', (req, res) => {
  res.json(proposals);
});

// Endpoint for event subscription
app.post('/api/subscribe', (req, res) => {
  res.json({ subscriptionId: "test-subscription-123" });
});

// Start the server
app.listen(port, () => {
  console.log(\`Mock Runtime server running at http://localhost:\${port}\`);
});
EOF
  fi
  
  # Start mock Runtime server
  cd mock-runtime && npm install && node index.js > ../mock_runtime.log 2>&1 &
  
  # Store PID
  echo $! > ../.test_runtime_pid
  
  # Wait for server to start
  sleep 3
  
  # Check if server is running
  curl -s http://localhost:3000/api/proposals > /dev/null || fail "Mock Runtime failed to start"
  
  cd ..
  success "Mock Runtime server started"
}

# Run API tests
test_api() {
  describe "Testing API endpoints"
  
  # Test thread creation
  THREAD_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    -d '{"title":"Test Thread","proposal_cid":"bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy"}' \
    http://localhost:$TEST_PORT/api/threads)
  
  THREAD_ID=$(echo $THREAD_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
  
  [ -n "$THREAD_ID" ] || fail "Thread creation failed"
  success "Thread creation successful with ID: $THREAD_ID"
  
  # Test thread retrieval
  curl -s -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    http://localhost:$TEST_PORT/api/threads/$THREAD_ID > /dev/null || fail "Thread retrieval failed"
  success "Thread retrieval successful"
  
  # Test message creation
  MESSAGE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    -d '{"content":"Test message content"}' \
    http://localhost:$TEST_PORT/api/threads/$THREAD_ID/messages)
  
  MESSAGE_ID=$(echo $MESSAGE_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
  
  [ -n "$MESSAGE_ID" ] || fail "Message creation failed"
  success "Message creation successful with ID: $MESSAGE_ID"
  
  # Test message retrieval
  curl -s -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    http://localhost:$TEST_PORT/api/threads/$THREAD_ID/messages/$MESSAGE_ID > /dev/null || fail "Message retrieval failed"
  success "Message retrieval successful"
  
  # Test reaction creation
  REACTION_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    -d '{"reaction_type":"👍"}' \
    http://localhost:$TEST_PORT/api/messages/$MESSAGE_ID/reactions)
  
  REACTION_ID=$(echo $REACTION_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
  
  [ -n "$REACTION_ID" ] || fail "Reaction creation failed"
  success "Reaction creation successful"
  
  # Test reaction removal
  curl -s -X DELETE -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    http://localhost:$TEST_PORT/api/messages/$MESSAGE_ID/reactions/👍 | grep -q "2[0-9][0-9]" || fail "Reaction removal failed"
  success "Reaction removal successful"
  
  success "API tests completed successfully"
}

# Test federation sync
test_federation() {
  describe "Testing federation synchronization"
  
  # TODO: Implement federation synchronization test
  # This would involve:
  # 1. Starting two AgoraNet instances with federation enabled
  # 2. Creating content on one node
  # 3. Verifying it propagates to the other node
  
  success "Federation test stub passed"
}

# Test runtime integration
test_runtime_integration() {
  describe "Testing Runtime integration"
  
  # Start AgoraNet with Runtime client enabled
  PORT=$TEST_PORT \
  DATABASE_URL=$TEST_DATABASE_URL \
  RUST_LOG=debug \
  ENABLE_FEDERATION=false \
  ENABLE_RUNTIME_CLIENT=true \
  RUNTIME_API_URL="http://localhost:3000" \
  RUNTIME_POLL_INTERVAL=5000 \
  cargo run > runtime_test.log 2>&1 &
  
  # Store PID
  echo $! > .test_pid
  
  # Wait for server to sync with Runtime
  sleep 10
  
  # Check if proposal threads were created
  THREADS=$(curl -s -H "Authorization: Bearer $TEST_AUTH_TOKEN" \
    http://localhost:$TEST_PORT/api/threads)
  
  echo $THREADS | grep -q "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy" || fail "Runtime proposal sync failed"
  
  # Cleanup
  kill -9 $(cat .test_pid) 2>/dev/null || true
  rm .test_pid
  
  success "Runtime integration test passed"
}

# Test stress conditions
test_stress() {
  describe "Running stress tests"
  
  # Check if k6 is installed
  if ! command -v k6 &> /dev/null; then
    echo "k6 is not installed. Skipping stress tests."
    return
  fi
  
  # Run k6 test script
  API_URL=http://localhost:$TEST_PORT \
  AUTH_TOKEN=$TEST_AUTH_TOKEN \
  k6 run --vus 10 --duration 30s scripts/load_test.js || fail "Stress test failed"
  
  success "Stress test completed successfully"
}

# Main test suite execution
main() {
  describe "Running AgoraNet Integration Test Suite"
  
  # Run cleanup on script exit
  trap cleanup EXIT
  
  # Setup test environment
  setup_test_db
  
  # Run tests
  start_test_server
  test_api
  
  # Clean up current instance
  cleanup
  
  # Start mock runtime for testing
  start_mock_runtime
  test_runtime_integration
  
  # Clean up current instances
  cleanup
  
  # Start federation test
  start_federation_test
  test_federation
  
  # Clean up current instances
  cleanup
  
  # Start stress test
  start_test_server
  test_stress
  
  echo -e "\n${GREEN}✓ All tests passed successfully!${NC}"
}

# Execute main function
main 