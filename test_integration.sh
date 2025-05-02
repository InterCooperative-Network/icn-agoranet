#!/bin/bash
# AgoraNet Integration Test Script

set -e

# Configuration
COMPOSE_FILE="docker-compose.integration.yml"
AGORANET_URL="http://localhost:3001"
MAX_RETRIES=10
RETRY_INTERVAL=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_service() {
    local url=$1
    local retries=$MAX_RETRIES
    local endpoint=$2
    
    log_info "Waiting for service at ${url}${endpoint}..."
    
    while [ $retries -gt 0 ]; do
        if curl -s -f "${url}${endpoint}" > /dev/null 2>&1; then
            log_success "Service is available!"
            return 0
        fi
        
        log_info "Service not ready yet. Retrying in ${RETRY_INTERVAL}s... ($retries retries left)"
        sleep $RETRY_INTERVAL
        retries=$((retries - 1))
    done
    
    log_error "Service did not become available in time"
    return 1
}

# 1. Start the services
log_info "Starting AgoraNet services using ${COMPOSE_FILE}..."
docker-compose -f $COMPOSE_FILE up -d

# 2. Wait for AgoraNet to be ready
wait_for_service $AGORANET_URL "/health"

# 3. Run basic API tests
log_info "Testing AgoraNet API health..."
health_response=$(curl -s "${AGORANET_URL}/health")
health_status=$(echo $health_response | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

if [ "$health_status" != "ok" ]; then
    log_error "Health check failed: $health_response"
    docker-compose -f $COMPOSE_FILE logs agoranet
    docker-compose -f $COMPOSE_FILE down
    exit 1
fi

log_success "Health check passed: $health_status"

# 4. Test thread creation and retrieval
log_info "Testing thread creation..."
thread_result=$(curl -s -X POST "${AGORANET_URL}/api/threads" \
    -H "Content-Type: application/json" \
    -d '{"title": "Integration Test Thread", "creator_did": "did:icn:test:integration"}')

thread_id=$(echo $thread_result | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$thread_id" ]; then
    log_error "Failed to create thread: $thread_result"
    docker-compose -f $COMPOSE_FILE logs agoranet
    docker-compose -f $COMPOSE_FILE down
    exit 1
fi

log_success "Thread created with ID: $thread_id"

# 5. Verify thread can be retrieved
log_info "Testing thread retrieval..."
thread_get=$(curl -s "${AGORANET_URL}/api/threads/${thread_id}")
retrieved_id=$(echo $thread_get | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ "$retrieved_id" != "$thread_id" ]; then
    log_error "Thread retrieval failed: $thread_get"
    docker-compose -f $COMPOSE_FILE logs agoranet
    docker-compose -f $COMPOSE_FILE down
    exit 1
fi

log_success "Thread retrieval successful"

# 6. Reset the database for next test run
log_info "Resetting database for next test run..."
DOCKER_ENV=1 ./scripts/reset_test_db.sh

# 7. Clean up
log_info "Cleaning up containers..."
docker-compose -f $COMPOSE_FILE down

log_success "Integration tests completed successfully!"
exit 0 