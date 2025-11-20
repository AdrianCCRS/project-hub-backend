#!/bin/bash

# Cleanup ProjectHub Kubernetes resources
# Usage: ./cleanup-k8s.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE="projecthub"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Cleaning up ProjectHub from Kubernetes${NC}"
echo -e "${YELLOW}========================================${NC}"

# Confirm deletion
echo -e "\n${RED}WARNING: This will delete all ProjectHub resources including data!${NC}"
echo -e "${YELLOW}Are you sure you want to continue? (yes/no)${NC}"
read -r response

if [[ ! "$response" =~ ^([yY][eE][sS])$ ]]; then
    echo -e "${BLUE}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "\n${GREEN}Starting cleanup...${NC}"

# Delete application resources
echo -e "\n${GREEN}Deleting application resources...${NC}"
kubectl delete -f k8s/app-service.yaml --ignore-not-found=true
kubectl delete -f k8s/app-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/app-secret.yaml --ignore-not-found=true
kubectl delete -f k8s/app-configmap.yaml --ignore-not-found=true

# Delete ingress if exists
if [ -f "k8s/ingress.yaml" ]; then
    kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
fi

# Delete MySQL resources
echo -e "\n${GREEN}Deleting MySQL resources...${NC}"
kubectl delete -f k8s/mysql-service.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql-secret.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql-configmap.yaml --ignore-not-found=true

# Ask about PVC deletion
echo -e "\n${YELLOW}Delete MySQL Persistent Volume Claim (this will delete all data)? (yes/no)${NC}"
read -r pvc_response

if [[ "$pvc_response" =~ ^([yY][eE][sS])$ ]]; then
    kubectl delete -f k8s/mysql-pvc.yaml --ignore-not-found=true
    echo -e "${GREEN}✓ PVC deleted${NC}"
else
    echo -e "${BLUE}ℹ PVC retained (data preserved)${NC}"
fi

# Ask about namespace deletion
echo -e "\n${YELLOW}Delete namespace '${NAMESPACE}'? (yes/no)${NC}"
read -r ns_response

if [[ "$ns_response" =~ ^([yY][eE][sS])$ ]]; then
    kubectl delete namespace ${NAMESPACE} --ignore-not-found=true
    echo -e "${GREEN}✓ Namespace deleted${NC}"
else
    echo -e "${BLUE}ℹ Namespace retained${NC}"
fi

echo -e "\n${GREEN}✓ Cleanup completed!${NC}"

# Show remaining resources
echo -e "\n${BLUE}Remaining resources in namespace '${NAMESPACE}':${NC}"
kubectl get all -n ${NAMESPACE} 2>/dev/null || echo -e "${GREEN}Namespace is empty or deleted${NC}"
