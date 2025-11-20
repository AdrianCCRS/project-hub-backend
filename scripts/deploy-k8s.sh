#!/bin/bash

# Deploy ProjectHub to Kubernetes
# Usage: ./deploy-k8s.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE="projecthub"
K8S_DIR="k8s"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deploying ProjectHub to Kubernetes${NC}"
echo -e "${BLUE}========================================${NC}"


# Check if cluster is accessible
echo -e "\n${GREEN}Checking Kubernetes cluster connection...${NC}"
if ! kuber cluster-info &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"

# Create namespace
echo -e "\n${GREEN}Step 1: Creating namespace...${NC}"
kuber apply -f ${K8S_DIR}/namespace.yaml
echo -e "${GREEN}✓ Namespace created/updated${NC}"

# Deploy MySQL
echo -e "\n${GREEN}Step 2: Deploying MySQL...${NC}"
kuber apply -f ${K8S_DIR}/mysql-configmap.yaml
kuber apply -f ${K8S_DIR}/mysql-secret.yaml
kuber apply -f ${K8S_DIR}/mysql-pvc.yaml
kuber apply -f ${K8S_DIR}/mysql-deployment.yaml
kuber apply -f ${K8S_DIR}/mysql-service.yaml
echo -e "${GREEN}✓ MySQL resources created/updated${NC}"

# Wait for MySQL to be ready
echo -e "\n${GREEN}Step 3: Waiting for MySQL to be ready...${NC}"
kuber wait --for=condition=ready pod -l app=mysql -n ${NAMESPACE} --timeout=300s
echo -e "${GREEN}✓ MySQL is ready${NC}"

# Deploy Application
echo -e "\n${GREEN}Step 4: Deploying ProjectHub application...${NC}"
kuber apply -f ${K8S_DIR}/app-configmap.yaml
kuber apply -f ${K8S_DIR}/app-secret.yaml
kuber apply -f ${K8S_DIR}/app-deployment.yaml
kuber apply -f ${K8S_DIR}/app-service.yaml
echo -e "${GREEN}✓ Application resources created/updated${NC}"

# Optional: Deploy Ingress
if [ -f "${K8S_DIR}/ingress.yaml" ]; then
    echo -e "\n${YELLOW}Deploy Ingress? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        kuber apply -f ${K8S_DIR}/ingress.yaml
        echo -e "${GREEN}✓ Ingress created/updated${NC}"
    fi
fi

# Wait for application to be ready
echo -e "\n${GREEN}Step 5: Waiting for application to be ready...${NC}"
kuber wait --for=condition=ready pod -l app=projecthub -n ${NAMESPACE} --timeout=300s
echo -e "${GREEN}✓ Application is ready${NC}"

# Display deployment status
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Deployment Summary:${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${GREEN}Pods:${NC}"
kuber get pods -n ${NAMESPACE}

echo -e "\n${GREEN}Services:${NC}"
kuber get services -n ${NAMESPACE}

echo -e "\n${GREEN}Deployments:${NC}"
kuber get deployments -n ${NAMESPACE}

# Get service URL
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Access Information:${NC}"
echo -e "${BLUE}========================================${NC}"

SERVICE_TYPE=$(kuber get service projecthub-service -n ${NAMESPACE} -o jsonpath='{.spec.type}')

if [ "$SERVICE_TYPE" == "LoadBalancer" ]; then
    echo -e "\n${YELLOW}Waiting for LoadBalancer IP...${NC}"
    sleep 5
    EXTERNAL_IP=$(kuber get service projecthub-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" == "null" ]; then
        EXTERNAL_IP=$(kuber get service projecthub-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    fi
    
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        echo -e "${GREEN}Application URL: http://${EXTERNAL_IP}${NC}"
    else
        echo -e "${YELLOW}LoadBalancer IP pending. Run this command to check:${NC}"
        echo -e "${BLUE}kuber get service projecthub-service -n ${NAMESPACE}${NC}"
    fi
elif [ "$SERVICE_TYPE" == "NodePort" ]; then
    NODE_PORT=$(kuber get service projecthub-service -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
    echo -e "${GREEN}Application accessible via NodePort: ${NODE_PORT}${NC}"
    echo -e "${BLUE}Use: http://<node-ip>:${NODE_PORT}${NC}"
fi

echo -e "\n${GREEN}✓ Deployment completed successfully!${NC}"

echo -e "\n${BLUE}Useful commands:${NC}"
echo -e "  View logs: ${GREEN}kuber logs -f -l app=projecthub -n ${NAMESPACE}${NC}"
echo -e "  Scale app: ${GREEN}kuber scale deployment projecthub-app --replicas=3 -n ${NAMESPACE}${NC}"
echo -e "  Delete all: ${GREEN}./scripts/cleanup-k8s.sh${NC}"
