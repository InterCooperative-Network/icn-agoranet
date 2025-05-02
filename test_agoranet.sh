#!/bin/bash
# AgoraNet Integration Test Script

set -e  # Exit on error

echo "Starting AgoraNet Integration Tests..."

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

# Start services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 15

# Define URLs and tokens
API_URL="http://localhost:3001"
VALID_TOKEN="testuser.9999999999.testsignature"
EXPIRED_TOKEN="testuser.1000000000.testsignature"
MALFORMED_TOKEN="testuser"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Please install it to run this script."
    exit 1
fi

echo -e "\n${YELLOW}=== 1. API Integration Tests ===${NC}"

# Test 1: Get threads (initial state)
echo "Testing GET /api/threads..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/threads.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
if [ $HTTP_CODE -eq 200 ]; then
  THREADS=$(cat /tmp/threads.json | jq length)
  echo -e "${GREEN}PASS${NC}: GET /api/threads returned $THREADS threads"
else
  echo -e "${RED}FAIL${NC}: GET /api/threads returned HTTP $HTTP_CODE"
  cat /tmp/threads.json
fi

# Test 2: Create a thread (authenticated)
echo "Testing POST /api/threads (authenticated)..."
RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Integration Test Thread","proposal_cid":"bafytest123"}' \
  -o /tmp/create_thread.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "POST /api/threads (authenticated)" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  THREAD_ID=$(cat /tmp/create_thread.json | jq -r '.id')
  echo "Created thread ID: $THREAD_ID"
fi

# Test 3: Create a thread (unauthenticated)
echo "Testing POST /api/threads (unauthenticated)..."
RESP=$(curl -s -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Unauthenticated Thread","proposal_cid":"bafytest456"}' \
  -o /tmp/unauth_thread.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 401 ] && echo 0 || echo 1) \
  "POST /api/threads (unauthenticated) should be rejected" \
  "HTTP code: $HTTP_CODE, expected 401"

# Test 4: Get specific thread
if [ -n "$THREAD_ID" ]; then
  echo "Testing GET /api/threads/:id..."
  RESP=$(curl -s -w "%{http_code}" -o /tmp/thread_detail.json $API_URL/api/threads/$THREAD_ID)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "GET /api/threads/$THREAD_ID" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    TITLE=$(cat /tmp/thread_detail.json | jq -r '.title')
    echo "Thread title: $TITLE"
  fi
fi

# Test 5: Get non-existent thread
echo "Testing GET /api/threads/:id (non-existent)..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/nonexistent.json $API_URL/api/threads/00000000-0000-0000-0000-000000000000)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 404 ] && echo 0 || echo 1) \
  "GET /api/threads/00000000-0000-0000-0000-000000000000 (non-existent)" \
  "HTTP code: $HTTP_CODE, expected 404"

echo -e "\n${YELLOW}=== 2. DID Authentication Tests ===${NC}"

# Test 6: Create thread with expired token
echo "Testing POST /api/threads with expired token..."
RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $EXPIRED_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Expired Token Thread","proposal_cid":"bafytest789"}' \
  -o /tmp/expired_token.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 401 ] && echo 0 || echo 1) \
  "POST /api/threads with expired token should be rejected" \
  "HTTP code: $HTTP_CODE, expected 401"

# Test 7: Create thread with malformed token
echo "Testing POST /api/threads with malformed token..."
RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $MALFORMED_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Malformed Token Thread","proposal_cid":"bafytest999"}' \
  -o /tmp/malformed_token.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 401 ] && echo 0 || echo 1) \
  "POST /api/threads with malformed token should be rejected" \
  "HTTP code: $HTTP_CODE, expected 401"

echo -e "\n${YELLOW}=== 3. Credential Link Tests ===${NC}"

if [ -n "$THREAD_ID" ]; then
  # Test 8: Create a credential link
  echo "Testing POST /api/threads/credential-link..."
  RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"thread_id\":\"$THREAD_ID\",\"credential_cid\":\"bafycredtest123\",\"signer_did\":\"did:icn:testuser\"}" \
    -o /tmp/create_link.json $API_URL/api/threads/credential-link)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "POST /api/threads/credential-link" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    LINK_ID=$(cat /tmp/create_link.json | jq -r '.id')
    echo "Created credential link ID: $LINK_ID"
  fi

  # Test 9: Get all credential links
  echo "Testing GET /api/threads/credential-links..."
  RESP=$(curl -s -w "%{http_code}" -o /tmp/all_links.json $API_URL/api/threads/credential-links)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "GET /api/threads/credential-links" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    LINKS_COUNT=$(cat /tmp/all_links.json | jq length)
    echo "Found $LINKS_COUNT credential links"
  fi

  # Test 10: Get thread-specific credential links
  echo "Testing GET /api/threads/:id/credential-links..."
  RESP=$(curl -s -w "%{http_code}" -o /tmp/thread_links.json $API_URL/api/threads/$THREAD_ID/credential-links)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "GET /api/threads/$THREAD_ID/credential-links" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    THREAD_LINKS_COUNT=$(cat /tmp/thread_links.json | jq length)
    echo "Found $THREAD_LINKS_COUNT credential links for thread $THREAD_ID"
  fi
fi

echo -e "\n${YELLOW}=== 4. Persistence Tests ===${NC}"

# Test 11: Restart AgoraNet and check if data persists
if [ -n "$THREAD_ID" ]; then
  echo "Restarting AgoraNet service..."
  docker-compose restart agoranet
  sleep 10  # Wait for restart
  
  echo "Testing data persistence after restart..."
  RESP=$(curl -s -w "%{http_code}" -o /tmp/thread_after_restart.json $API_URL/api/threads/$THREAD_ID)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "Thread persists after restart" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    TITLE=$(cat /tmp/thread_after_restart.json | jq -r '.title')
    echo "Thread title after restart: $TITLE"
  fi
  
  # Check credential links persistence
  RESP=$(curl -s -w "%{http_code}" -o /tmp/links_after_restart.json $API_URL/api/threads/$THREAD_ID/credential-links)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "Credential links persist after restart" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    LINKS_COUNT=$(cat /tmp/links_after_restart.json | jq length)
    check_result $([ $LINKS_COUNT -gt 0 ] && echo 0 || echo 1) \
      "Credential links count should be greater than 0" \
      "Found $LINKS_COUNT links"
  fi
fi

echo -e "\n${YELLOW}=== 5. Data Model Alignment Tests ===${NC}"

# Test 12: Create thread with specific CID format
echo "Testing thread creation with specific CID format..."
RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"CID Format Test","proposal_cid":"bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi"}' \
  -o /tmp/cid_format_thread.json $API_URL/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Thread creation with specific CID format" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  CID_THREAD_ID=$(cat /tmp/cid_format_thread.json | jq -r '.id')
  CID_FORMAT=$(cat /tmp/cid_format_thread.json | jq -r '.proposal_cid')
  
  check_result $([ "$CID_FORMAT" == "bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi" ] && echo 0 || echo 1) \
    "CID format is preserved" \
    "Expected: bafybeihykld6nqwmzul5pswm7jgj4qmyarm4sfsfwihhzne6vmuob6itdi, Got: $CID_FORMAT"
    
  # Create credential link with specific formats
  echo "Testing credential link with specific formats..."
  RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"thread_id\":\"$CID_THREAD_ID\",\"credential_cid\":\"bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku\",\"signer_did\":\"did:icn:test123\"}" \
    -o /tmp/cid_format_link.json $API_URL/api/threads/credential-link)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "Credential link with specific formats" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    CRED_CID=$(cat /tmp/cid_format_link.json | jq -r '.credential_cid')
    DID_FORMAT=$(cat /tmp/cid_format_link.json | jq -r '.linked_by')
    
    check_result $([ "$CRED_CID" == "bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku" ] && echo 0 || echo 1) \
      "Credential CID format is preserved" \
      "Expected: bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku, Got: $CRED_CID"
      
    check_result $([ "$DID_FORMAT" == "did:icn:test123" ] && echo 0 || echo 1) \
      "DID format is preserved" \
      "Expected: did:icn:test123, Got: $DID_FORMAT"
  fi
fi

# Cleanup temp files
rm -f /tmp/threads.json /tmp/create_thread.json /tmp/unauth_thread.json \
  /tmp/thread_detail.json /tmp/nonexistent.json /tmp/expired_token.json \
  /tmp/malformed_token.json /tmp/create_link.json /tmp/all_links.json \
  /tmp/thread_links.json /tmp/thread_after_restart.json /tmp/links_after_restart.json \
  /tmp/cid_format_thread.json /tmp/cid_format_link.json

# Uncomment to stop services after testing
# echo "Stopping Docker services..."
# docker-compose down

echo -e "\n${GREEN}All integration tests completed.${NC}" 