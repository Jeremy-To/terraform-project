#!/bin/bash
# Infrastructure teardown script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "3-Tier Infrastructure Teardown"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WARNING: This will destroy all infrastructure!${NC}"
echo "Are you sure you want to continue? (yes/no)"
read -r CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Teardown cancelled."
    exit 0
fi

cd "$PROJECT_ROOT/terraform"

echo -e "${RED}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo ""
echo "=========================================="
echo -e "${GREEN}Infrastructure destroyed successfully${NC}"
echo "=========================================="
echo ""
echo "Note: Packer images are NOT deleted. To delete them:"
echo "  gcloud compute images list --filter='name~web-server|app-server|db-server'"
echo "  gcloud compute images delete <IMAGE_NAME>"
echo "=========================================="
