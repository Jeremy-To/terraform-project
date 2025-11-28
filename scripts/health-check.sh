#!/bin/bash
# Health check script to validate deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "3-Tier Infrastructure Health Check"
echo "=========================================="
echo ""

cd "$PROJECT_ROOT/terraform"

# Get IPs from Terraform
LB_IP=$(terraform output -raw load_balancer_ip 2>/dev/null || echo "")

if [ -z "$LB_IP" ]; then
    echo -e "${RED}✗ Could not retrieve load balancer IP${NC}"
    exit 1
fi

echo -e "${BLUE}Load Balancer IP: $LB_IP${NC}"
echo ""

# Test 1: Load Balancer HTTP
echo -n "Testing Load Balancer HTTP response... "
if curl -s -o /dev/null -w "%{http_code}" "http://$LB_IP" | grep -q "200"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test 2: Load Balancer Health Endpoint
echo -n "Testing Load Balancer health endpoint... "
if curl -s "http://$LB_IP/health" | grep -q "healthy"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test 3: API Health
echo -n "Testing API health endpoint... "
if curl -s "http://$LB_IP/api/health" | grep -q "healthy"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test 4: Database Connectivity (via API)
echo -n "Testing database connectivity via API... "
RESPONSE=$(curl -s "http://$LB_IP/api/health")
if echo "$RESPONSE" | grep -q "connected"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test 5: Check replication status
echo -n "Testing database replication status... "
if echo "$RESPONSE" | grep -q "replication"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL (may not be configured)${NC}"
fi

# Test 6: API Data endpoint
echo -n "Testing API data endpoint... "
if curl -s "http://$LB_IP/api/data" | grep -q "success"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test 7: SSH connectivity
echo -n "Testing SSH connectivity to load balancer... "
if timeout 5 ssh -o StrictHostKeyChecking=no -o BatchMode=yes ubuntu@$LB_IP "echo connected" 2>/dev/null | grep -q "connected"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL (SSH key may not be configured)${NC}"
fi

echo ""
echo "=========================================="
echo "Health Check Complete"
echo "=========================================="
echo ""
echo "Access the application at: http://$LB_IP"
echo ""

# Display summary from Ansible if available
cd "$PROJECT_ROOT/ansible"
if [ -f "inventory/hosts" ]; then
    echo "Infrastructure Summary:"
    echo "----------------------"
    grep -E "^\[|^[a-z].*ansible_host=" inventory/hosts | head -20
fi
