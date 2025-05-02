#!/bin/bash
# AgoraNet Runtime Event Consumption Test Script

set -e  # Exit on error

echo "Starting AgoraNet Runtime Event Consumption Tests..."

# Define color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check test results
check_result() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}: $2"
  else
    echo -e "${RED}FAIL${NC}: $2"
    if [ -n "$3" ]; then
      echo -e "${YELLOW}Error: $3${NC}"
    fi
  fi
}

# Start services with mock runtime
echo "Starting mock Runtime and AgoraNet services..."

# Start only the mock runtime first
docker-compose -f docker-compose-federation.yml up -d mock_runtime

# Wait for mock runtime to be ready
echo "Waiting for mock Runtime to be ready..."
sleep 5

# Check if mock runtime is running
echo "Checking mock Runtime health..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/runtime_health.json http://localhost:3000/api/health)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Mock Runtime health check" \
  "HTTP code: $HTTP_CODE"

# Start AgoraNet with runtime client enabled
# Create a temporary docker-compose override
cat > docker-compose.runtime.yml << EOL
version: '3'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: agoranet
      POSTGRES_PASSWORD: agoranet_password
      POSTGRES_DB: agoranet
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U agoranet"]
      interval: 5s
      timeout: 5s
      retries: 5

  agoranet:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: "postgres://agoranet:agoranet_password@postgres:5432/agoranet"
      PORT: "3001"
      RUST_LOG: "info,icn_agoranet=debug"
      RUN_MIGRATIONS: "true"
      ENABLE_FEDERATION: "false"
      ENABLE_RUNTIME_CLIENT: "true"
      RUNTIME_API_ENDPOINT: "http://localhost:3000"
    ports:
      - "3001:3001"
    depends_on:
      postgres:
        condition: service_healthy
    network_mode: "host"
    restart: unless-stopped

volumes:
  postgres_data:
EOL

docker-compose -f docker-compose.runtime.yml up -d

# Wait for AgoraNet to be ready
echo "Waiting for AgoraNet with Runtime client to be ready..."
sleep 20

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Please install it to run this script."
    exit 1
fi

# Define API URL
API_URL="http://localhost:3001"

echo -e "\n${YELLOW}=== 1. Thread Creation from Runtime Events ===${NC}"

# Test 1: Check if threads were created from Runtime events
echo "Checking if threads were created from Runtime events..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/runtime_threads.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Get threads from AgoraNet" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  # Try to find the thread with the proposal CID from the mock Runtime events
  FOUND=$(cat /tmp/runtime_threads.json | jq --arg cid "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi" '[.[] | select(.proposal_cid == $cid)] | length')
  
  check_result $([ $FOUND -gt 0 ] && echo 0 || echo 1) \
    "Thread with proposal CID from Runtime event should be created" \
    "Found $FOUND matching threads, expected at least 1"
    
  if [ $FOUND -gt 0 ]; then
    # Get the thread ID and title
    THREAD_TITLE=$(cat /tmp/runtime_threads.json | jq -r --arg cid "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi" '.[] | select(.proposal_cid == $cid) | .title')
    THREAD_ID=$(cat /tmp/runtime_threads.json | jq -r --arg cid "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi" '.[] | select(.proposal_cid == $cid) | .id')
    
    echo "Found thread: ID=$THREAD_ID, Title='$THREAD_TITLE'"
    
    # Test if title includes APPROVED status (if proposal finalization event was processed)
    HAS_APPROVED=$(echo "$THREAD_TITLE" | grep -c "APPROVED" || true)
    
    check_result $([ $HAS_APPROVED -gt 0 ] && echo 0 || echo 1) \
      "Thread title should contain 'APPROVED' status from ProposalFinalized event" \
      "Title: '$THREAD_TITLE'"
  fi
fi

# Test 2: Modify the mock Runtime events to add a new proposal
echo "Modifying mock Runtime events to add a new proposal..."
cat > mock_runtime/events.json << EOL
[
  {
    "type": "ProposalCreated",
    "proposal_cid": "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi",
    "title": "Test Proposal",
    "created_by": "did:icn:test123",
    "timestamp": 1646200800
  },
  {
    "type": "CredentialIssued",
    "credential_cid": "bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku",
    "issuer_did": "did:icn:issuer",
    "subject_did": "did:icn:subject",
    "credential_type": "VoteCredential",
    "timestamp": 1646230800
  },
  {
    "type": "ProposalFinalized",
    "proposal_cid": "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi",
    "approved": true,
    "timestamp": 1646287200
  },
  {
    "type": "ProposalCreated",
    "proposal_cid": "bafyneweventtest123456789abcdef",
    "title": "New Test Proposal",
    "created_by": "did:icn:testuser",
    "timestamp": 1646300000
  }
]
EOL

# Wait for event polling to occur
echo "Waiting for Runtime event polling (30 seconds)..."
sleep 30

# Test 3: Check if new thread was created from modified Runtime events
echo "Checking if new thread was created from modified Runtime events..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/runtime_threads_new.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Get threads from AgoraNet after adding new event" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  # Try to find the thread with the new proposal CID
  FOUND=$(cat /tmp/runtime_threads_new.json | jq --arg cid "bafyneweventtest123456789abcdef" '[.[] | select(.proposal_cid == $cid)] | length')
  
  check_result $([ $FOUND -gt 0 ] && echo 0 || echo 1) \
    "Thread with new proposal CID should be created" \
    "Found $FOUND matching threads, expected at least 1"
    
  if [ $FOUND -gt 0 ]; then
    NEW_THREAD_TITLE=$(cat /tmp/runtime_threads_new.json | jq -r --arg cid "bafyneweventtest123456789abcdef" '.[] | select(.proposal_cid == $cid) | .title')
    echo "Found new thread with title: '$NEW_THREAD_TITLE'"
  fi
fi

echo -e "\n${YELLOW}=== 2. Thread Update from Finalization Events ===${NC}"

# Test 4: Add finalization event for the new proposal
echo "Adding finalization event for the new proposal..."
cat > mock_runtime/events.json << EOL
[
  {
    "type": "ProposalCreated",
    "proposal_cid": "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi",
    "title": "Test Proposal",
    "created_by": "did:icn:test123",
    "timestamp": 1646200800
  },
  {
    "type": "CredentialIssued",
    "credential_cid": "bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku",
    "issuer_did": "did:icn:issuer",
    "subject_did": "did:icn:subject",
    "credential_type": "VoteCredential",
    "timestamp": 1646230800
  },
  {
    "type": "ProposalFinalized",
    "proposal_cid": "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi",
    "approved": true,
    "timestamp": 1646287200
  },
  {
    "type": "ProposalCreated",
    "proposal_cid": "bafyneweventtest123456789abcdef",
    "title": "New Test Proposal",
    "created_by": "did:icn:testuser",
    "timestamp": 1646300000
  },
  {
    "type": "ProposalFinalized",
    "proposal_cid": "bafyneweventtest123456789abcdef",
    "approved": false,
    "timestamp": 1646400000
  }
]
EOL

# Wait for event polling to occur
echo "Waiting for Runtime event polling (30 seconds)..."
sleep 30

# Test 5: Check if thread was updated from finalization event
echo "Checking if thread was updated from finalization event..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/runtime_threads_final.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Get threads from AgoraNet after adding finalization event" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  # Try to find the thread with the proposal CID
  FINAL_THREAD_TITLE=$(cat /tmp/runtime_threads_final.json | jq -r --arg cid "bafyneweventtest123456789abcdef" '.[] | select(.proposal_cid == $cid) | .title')
  
  # Check if title includes REJECTED status (since approved=false in the event)
  HAS_REJECTED=$(echo "$FINAL_THREAD_TITLE" | grep -c "REJECTED" || true)
  
  check_result $([ $HAS_REJECTED -gt 0 ] && echo 0 || echo 1) \
    "Thread title should contain 'REJECTED' status from ProposalFinalized event" \
    "Title: '$FINAL_THREAD_TITLE'"
    
  echo "Updated thread title: '$FINAL_THREAD_TITLE'"
fi

# Cleanup temp files
rm -f /tmp/runtime_health.json /tmp/runtime_threads.json \
  /tmp/runtime_threads_new.json /tmp/runtime_threads_final.json

# Uncomment to stop services after testing
# echo "Stopping Docker services..."
# docker-compose -f docker-compose.runtime.yml down
# docker-compose -f docker-compose-federation.yml stop mock_runtime
# rm docker-compose.runtime.yml

echo -e "\n${GREEN}All Runtime event consumption tests completed.${NC}" 