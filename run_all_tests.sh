#!/bin/bash
# Master script to run all AgoraNet tests

set -e  # Exit on error

# Define color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}               AgoraNet Validation Tests                  ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Check for required tools
echo -e "\n${YELLOW}Checking required tools...${NC}"
MISSING_TOOLS=0

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is required but not installed.${NC}"
    MISSING_TOOLS=1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is required but not installed.${NC}"
    MISSING_TOOLS=1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}jq is required but not installed.${NC}"
    MISSING_TOOLS=1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}curl is required but not installed.${NC}"
    MISSING_TOOLS=1
fi

if [ $MISSING_TOOLS -eq 1 ]; then
    echo -e "${RED}Please install the missing tools to run these tests.${NC}"
    exit 1
fi

echo -e "${GREEN}All required tools are installed.${NC}"

# Make sure all scripts are executable
chmod +x test_agoranet.sh test_federation.sh test_runtime_events.sh

# Clean up any existing containers
echo -e "\n${YELLOW}Cleaning up any existing AgoraNet containers...${NC}"
docker-compose down -v 2>/dev/null || true
docker-compose -f docker-compose-federation.yml down -v 2>/dev/null || true
if [ -f docker-compose.runtime.yml ]; then
    docker-compose -f docker-compose.runtime.yml down -v 2>/dev/null || true
    rm -f docker-compose.runtime.yml
fi

# Build images first
echo -e "\n${YELLOW}Building Docker images...${NC}"
docker-compose build
docker-compose -f docker-compose-federation.yml build

# Run basic API integration tests
echo -e "\n${BLUE}=========================================================${NC}"
echo -e "${BLUE}         1. Running API Integration Tests                 ${NC}"
echo -e "${BLUE}=========================================================${NC}"
./test_agoranet.sh

# Clean up after basic tests
echo -e "\n${YELLOW}Cleaning up after API integration tests...${NC}"
docker-compose down -v

# Run federation tests
echo -e "\n${BLUE}=========================================================${NC}"
echo -e "${BLUE}         2. Running Federation Sync Tests                 ${NC}"
echo -e "${BLUE}=========================================================${NC}"
./test_federation.sh

# Clean up after federation tests
echo -e "\n${YELLOW}Cleaning up after federation tests...${NC}"
docker-compose -f docker-compose-federation.yml down -v

# Run runtime event consumption tests
echo -e "\n${BLUE}=========================================================${NC}"
echo -e "${BLUE}         3. Running Runtime Event Consumption Tests       ${NC}"
echo -e "${BLUE}=========================================================${NC}"
./test_runtime_events.sh

# Clean up after runtime tests
echo -e "\n${YELLOW}Cleaning up after runtime event tests...${NC}"
if [ -f docker-compose.runtime.yml ]; then
    docker-compose -f docker-compose.runtime.yml down -v
    rm -f docker-compose.runtime.yml
fi
docker-compose -f docker-compose-federation.yml down -v

echo -e "\n${BLUE}=========================================================${NC}"
echo -e "${GREEN}All AgoraNet validation tests have been completed!${NC}"
echo -e "${BLUE}=========================================================${NC}" 