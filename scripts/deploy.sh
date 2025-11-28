#!/bin/bash
# Complete deployment script for 3-tier infrastructure
# This script orchestrates Packer, Terraform, and Ansible

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "3-Tier Infrastructure Deployment"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

START_TIME=$(date +%s)

# Function to print step headers
print_step() {
    echo -e "${BLUE}===> $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Step 1: Build Packer Images
print_step "Step 1: Building Packer Images (Skip if already built)"
echo "Do you want to build Packer images? (y/n) [Default: n]"
read -r BUILD_IMAGES
if [[ "$BUILD_IMAGES" == "y" ]]; then
    cd "$PROJECT_ROOT/packer"
    
    print_step "Building Web Server Image..."
    packer build -var-file=variables.auto.pkrvars.hcl web-server.pkr.hcl
    print_success "Web server image built"
    
    print_step "Building App Server Image..."
    packer build -var-file=variables.auto.pkrvars.hcl app-server.pkr.hcl
    print_success "App server image built"
    
    print_step "Building Database Server Image..."
    packer build -var-file=variables.auto.pkrvars.hcl db-server.pkr.hcl
    print_success "Database server image built"
else
    echo "Skipping Packer image build..."
fi

# Step 2: Initialize and Apply Terraform
print_step "Step 2: Provisioning Infrastructure with Terraform"
cd "$PROJECT_ROOT/terraform"

print_step "Initializing Terraform..."
terraform init
print_success "Terraform initialized"

print_step "Validating Terraform configuration..."
terraform validate
print_success "Terraform configuration valid"

print_step "Planning Terraform deployment..."
terraform plan -out=tfplan
print_success "Terraform plan created"

print_step "Applying Terraform configuration..."
terraform apply tfplan
print_success "Infrastructure provisioned"

# Step 3: Generate Ansible Inventory
print_step "Step 3: Generating Ansible Inventory"
terraform output -raw ansible_inventory > "$PROJECT_ROOT/ansible/inventory/hosts"
print_success "Ansible inventory generated"

# Get load balancer IP for display
LB_IP=$(terraform output -raw load_balancer_ip)
print_success "Load Balancer IP: $LB_IP"

# Step 4: Wait for instances to be ready
print_step "Step 4: Waiting for instances to be ready..."
echo "Waiting 60 seconds for SSH to be available..."
sleep 60
print_success "Instances should be ready"

# Step 5: Run Ansible Deployment
print_step "Step 5: Deploying Application with Ansible"
cd "$PROJECT_ROOT/ansible"

print_step "Testing Ansible connectivity..."
ansible all -m ping -i inventory/hosts || {
    print_error "Ansible connectivity test failed. Waiting additional 30 seconds..."
    sleep 30
    ansible all -m ping -i inventory/hosts
}
print_success "Ansible connectivity established"

print_step "Running Ansible playbook..."
ansible-playbook -i inventory/hosts playbooks/deploy.yml
print_success "Application deployed"

# Calculate deployment time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "=========================================="
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo "=========================================="
echo "Total deployment time: ${MINUTES}m ${SECONDS}s"
echo ""
echo "Access your application at: http://$LB_IP"
echo ""
echo "SSH to load balancer: ssh ubuntu@$LB_IP"
echo ""
echo "To destroy infrastructure, run: ./scripts/destroy.sh"
echo "=========================================="
