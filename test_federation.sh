#!/bin/bash
# AgoraNet Federation Test Script

set -e  # Exit on error

echo "Starting AgoraNet Federation Tests..."

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

# Start federated services
echo "Starting federated Docker services..."
docker-compose -f docker-compose-federation.yml up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Define URLs and tokens
API_URL_1="http://localhost:3001"
API_URL_2="http://localhost:3002"
VALID_TOKEN="testuser.9999999999.testsignature"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Please install it to run this script."
    exit 1
fi

echo -e "\n${YELLOW}=== 1. Federation Initial State Check ===${NC}"

# Test 1: Check initial state of both instances
echo "Checking initial state of AgoraNet 1..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/threads1.json $API_URL_1/api/threads)
HTTP_CODE=${RESP: -3}
if [ $HTTP_CODE -eq 200 ]; then
  THREADS_1=$(cat /tmp/threads1.json | jq length)
  echo -e "${GREEN}PASS${NC}: AgoraNet 1 returned $THREADS_1 threads initially"
else
  echo -e "${RED}FAIL${NC}: AgoraNet 1 returned HTTP $HTTP_CODE"
fi

echo "Checking initial state of AgoraNet 2..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/threads2.json $API_URL_2/api/threads)
HTTP_CODE=${RESP: -3}
if [ $HTTP_CODE -eq 200 ]; then
  THREADS_2=$(cat /tmp/threads2.json | jq length)
  echo -e "${GREEN}PASS${NC}: AgoraNet 2 returned $THREADS_2 threads initially"
else
  echo -e "${RED}FAIL${NC}: AgoraNet 2 returned HTTP $HTTP_CODE"
fi

echo -e "\n${YELLOW}=== 2. Federation Thread Synchronization ===${NC}"

# Test 2: Create a thread on AgoraNet 1
echo "Creating thread on AgoraNet 1..."
RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Federation Test Thread","proposal_cid":"bafyfederation1"}' \
  -o /tmp/create_thread1.json $API_URL_1/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Thread creation on AgoraNet 1" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  THREAD_ID=$(cat /tmp/create_thread1.json | jq -r '.id')
  echo "Created thread ID on AgoraNet 1: $THREAD_ID"
fi

# Test 3: Wait for federation sync to occur
echo "Waiting for federation sync (15 seconds)..."
sleep 15

# Test 4: Check if thread appears on AgoraNet 2
echo "Checking if thread appears on AgoraNet 2..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/threads2_after.json $API_URL_2/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Get threads from AgoraNet 2 after sync" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  # Try to find the thread with the same title
  FOUND=$(cat /tmp/threads2_after.json | jq --arg title "Federation Test Thread" '[.[] | select(.title == $title)] | length')
  
  check_result $([ $FOUND -gt 0 ] && echo 0 || echo 1) \
    "Thread 'Federation Test Thread' should be synchronized to AgoraNet 2" \
    "Found $FOUND matching threads, expected at least 1"
    
  if [ $FOUND -gt 0 ]; then
    # Get the thread ID on instance 2
    THREAD_ID_2=$(cat /tmp/threads2_after.json | jq -r --arg title "Federation Test Thread" '.[] | select(.title == $title) | .id')
    echo "Found thread ID on AgoraNet 2: $THREAD_ID_2"
  fi
fi

echo -e "\n${YELLOW}=== 3. Federation Credential Link Synchronization ===${NC}"

# Test 5: Create credential link on AgoraNet 2
if [ -n "$THREAD_ID_2" ]; then
  echo "Creating credential link on AgoraNet 2..."
  RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"thread_id\":\"$THREAD_ID_2\",\"credential_cid\":\"bafycredfedtest\",\"signer_did\":\"did:icn:federation\"}" \
    -o /tmp/create_link2.json $API_URL_2/api/threads/credential-link)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "Credential link creation on AgoraNet 2" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    LINK_ID=$(cat /tmp/create_link2.json | jq -r '.id')
    echo "Created credential link ID on AgoraNet 2: $LINK_ID"
  fi
  
  # Test 6: Wait for federation sync to occur again
  echo "Waiting for federation sync (15 seconds)..."
  sleep 15
  
  # Test 7: Check if credential link appears on AgoraNet 1
  echo "Checking if credential link appears on AgoraNet 1..."
  RESP=$(curl -s -w "%{http_code}" -o /tmp/links1_after.json $API_URL_1/api/threads/credential-links)
  HTTP_CODE=${RESP: -3}
  check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
    "Get credential links from AgoraNet 1 after sync" \
    "HTTP code: $HTTP_CODE"
  
  if [ $HTTP_CODE -eq 200 ]; then
    # Try to find the credential link with the same credential_cid
    FOUND=$(cat /tmp/links1_after.json | jq --arg cid "bafycredfedtest" '[.[] | select(.credential_cid == $cid)] | length')
    
    check_result $([ $FOUND -gt 0 ] && echo 0 || echo 1) \
      "Credential link with CID 'bafycredfedtest' should be synchronized to AgoraNet 1" \
      "Found $FOUND matching links, expected at least 1"
  fi
fi

echo -e "\n${YELLOW}=== 4. Federation Resilience Test ===${NC}"

# Test 8: Restart AgoraNet 2 and test federation recovery
echo "Restarting AgoraNet 2 to test federation resilience..."
docker-compose -f docker-compose-federation.yml restart agoranet2
sleep 15  # Wait for restart

# Test 9: Create another thread on AgoraNet 1
echo "Creating another thread on AgoraNet 1 after AgoraNet 2 restart..."
RESP=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $VALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Federation Resilience Test","proposal_cid":"bafyfederationresilience"}' \
  -o /tmp/create_thread_resilience.json $API_URL_1/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Thread creation on AgoraNet 1 after restart" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  RESILIENCE_THREAD_ID=$(cat /tmp/create_thread_resilience.json | jq -r '.id')
  echo "Created resilience test thread ID on AgoraNet 1: $RESILIENCE_THREAD_ID"
fi

# Test 10: Wait for federation sync to occur after restart
echo "Waiting for federation sync after restart (20 seconds)..."
sleep 20

# Test 11: Check if the new thread appears on AgoraNet 2 after restart
echo "Checking if new thread appears on AgoraNet 2 after restart..."
RESP=$(curl -s -w "%{http_code}" -o /tmp/threads2_resilience.json $API_URL_2/api/threads)
HTTP_CODE=${RESP: -3}
check_result $([ $HTTP_CODE -eq 200 ] && echo 0 || echo 1) \
  "Get threads from AgoraNet 2 after restart and sync" \
  "HTTP code: $HTTP_CODE"

if [ $HTTP_CODE -eq 200 ]; then
  # Try to find the thread with the new title
  FOUND=$(cat /tmp/threads2_resilience.json | jq --arg title "Federation Resilience Test" '[.[] | select(.title == $title)] | length')
  
  check_result $([ $FOUND -gt 0 ] && echo 0 || echo 1) \
    "Thread 'Federation Resilience Test' should be synchronized to AgoraNet 2 after restart" \
    "Found $FOUND matching threads, expected at least 1"
fi

# Cleanup temp files
rm -f /tmp/threads1.json /tmp/threads2.json /tmp/create_thread1.json \
  /tmp/threads2_after.json /tmp/create_link2.json /tmp/links1_after.json \
  /tmp/create_thread_resilience.json /tmp/threads2_resilience.json

# Uncomment to stop services after testing
# echo "Stopping Docker services..."
# docker-compose -f docker-compose-federation.yml down

echo -e "\n${GREEN}All federation tests completed.${NC}" 