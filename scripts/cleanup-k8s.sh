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

NAMESPACE_BACKEND="projecthub-backend"
NAMESPACE_DATABASE="projecthub-database"
NAMESPACE_FRONTEND="projecthub-frontend"
K8S_DIR="../k8s"

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

# Delete Ingress (if exists)
echo -e "\n${GREEN}Step 1: Deleting Ingress...${NC}"
if [ -f "${K8S_DIR}/ingress.yaml" ]; then
    microk8s kubectl delete -f ${K8S_DIR}/ingress.yaml --ignore-not-found=true
    echo -e "${GREEN}✓ Ingress deleted${NC}"
else
    echo -e "${BLUE}ℹ No ingress file found${NC}"
fi

# Delete application resources (backend namespace)
echo -e "\n${GREEN}Step 2: Deleting backend application resources...${NC}"
microk8s kubectl delete -f ${K8S_DIR}/app-service.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/app-deployment.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/app-secret.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/app-configmap.yaml --ignore-not-found=true
echo -e "${GREEN}✓ Backend resources deleted${NC}"

# Delete MySQL resources (database namespace)
echo -e "\n${GREEN}Step 3: Deleting MySQL resources...${NC}"
microk8s kubectl delete -f ${K8S_DIR}/mysql-service.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/mysql-deployment.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/mysql-initdb-configmap.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/mysql-secret.yaml --ignore-not-found=true
microk8s kubectl delete -f ${K8S_DIR}/mysql-configmap.yaml --ignore-not-found=true
echo -e "${GREEN}✓ MySQL resources deleted${NC}"

# Ask about PVC deletion
echo -e "\n${YELLOW}Delete MySQL Persistent Volume Claim (this will delete all data)? (yes/no)${NC}"
read -r pvc_response

if [[ "$pvc_response" =~ ^([yY][eE][sS])$ ]]; then
    microk8s kubectl delete -f ${K8S_DIR}/mysql-pvc.yaml --ignore-not-found=true
    echo -e "${GREEN}✓ PVC deleted (all database data removed)${NC}"
else
    echo -e "${BLUE}ℹ PVC retained (data preserved for next deployment)${NC}"
fi

# Ask about namespace deletion
echo -e "\n${YELLOW}Delete all ProjectHub namespaces? (yes/no)${NC}"
echo -e "${YELLOW}This will delete: ${NAMESPACE_BACKEND}, ${NAMESPACE_DATABASE}, ${NAMESPACE_FRONTEND}${NC}"
read -r ns_response

if [[ "$ns_response" =~ ^([yY][eE][sS])$ ]]; then
    microk8s kubectl delete -f ${K8S_DIR}/namespace.yaml --ignore-not-found=true
    echo -e "${GREEN}✓ All namespaces deleted${NC}"
else
    echo -e "${BLUE}ℹ Namespaces retained${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Cleanup completed!${NC}"
echo -e "${GREEN}========================================${NC}"

# Show remaining resources
echo -e "\n${BLUE}Remaining resources:${NC}"

echo -e "\n${BLUE}Backend namespace (${NAMESPACE_BACKEND}):${NC}"
microk8s kubectl get all -n ${NAMESPACE_BACKEND} 2>/dev/null || echo -e "${GREEN}  Namespace is empty or deleted${NC}"

echo -e "\n${BLUE}Database namespace (${NAMESPACE_DATABASE}):${NC}"
microk8s kubectl get all -n ${NAMESPACE_DATABASE} 2>/dev/null || echo -e "${GREEN}  Namespace is empty or deleted${NC}"

echo -e "\n${BLUE}Frontend namespace (${NAMESPACE_FRONTEND}):${NC}"
microk8s kubectl get all -n ${NAMESPACE_FRONTEND} 2>/dev/null || echo -e "${GREEN}  Namespace is empty or deleted${NC}"

echo -e "\n${BLUE}Persistent Volumes:${NC}"
microk8s kubectl get pvc -n ${NAMESPACE_DATABASE} 2>/dev/null || echo -e "${GREEN}  No PVCs found${NC}"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Cleanup summary:${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "  • Backend resources: ${GREEN}Deleted${NC}"
echo -e "  • Database resources: ${GREEN}Deleted${NC}"
if [[ "$pvc_response" =~ ^([yY][eE][sS])$ ]]; then
    echo -e "  • Database data (PVC): ${GREEN}Deleted${NC}"
else
    echo -e "  • Database data (PVC): ${YELLOW}Retained${NC}"
fi
if [[ "$ns_response" =~ ^([yY][eE][sS])$ ]]; then
    echo -e "  • Namespaces: ${GREEN}Deleted${NC}"
else
    echo -e "  • Namespaces: ${YELLOW}Retained${NC}"
fi
echo -e "${BLUE}========================================${NC}"

echo -e "\n${GREEN}To redeploy, run: ${BLUE}./scripts/deploy-k8s.sh${NC}"
