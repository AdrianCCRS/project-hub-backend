#!/bin/bash

# Build Docker image for ProjectHub application
# Usage: ./build-docker.sh [version]

set -e

# Configuration
IMAGE_NAME="projecthub"
VERSION="${1:-latest}"
REGISTRY="${DOCKER_REGISTRY:-}"  # Set DOCKER_REGISTRY env var to push to a registry

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building Docker Image for ProjectHub${NC}"
echo -e "${BLUE}========================================${NC}"

# Build the Docker image
echo -e "\n${GREEN}Step 1: Building Docker image...${NC}"
docker build -t ${IMAGE_NAME}:${VERSION} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker image built successfully: ${IMAGE_NAME}:${VERSION}${NC}"
else
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi

# Tag as latest if version is specified
if [ "$VERSION" != "latest" ]; then
    echo -e "\n${GREEN}Step 2: Tagging as latest...${NC}"
    docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
    echo -e "${GREEN}✓ Tagged as ${IMAGE_NAME}:latest${NC}"
fi

# Push to registry if DOCKER_REGISTRY is set
if [ -n "$REGISTRY" ]; then
    echo -e "\n${GREEN}Step 3: Pushing to registry...${NC}"
    docker tag ${IMAGE_NAME}:${VERSION} ${REGISTRY}/${IMAGE_NAME}:${VERSION}
    docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}
    
    if [ "$VERSION" != "latest" ]; then
        docker tag ${IMAGE_NAME}:${VERSION} ${REGISTRY}/${IMAGE_NAME}:latest
        docker push ${REGISTRY}/${IMAGE_NAME}:latest
    fi
    
    echo -e "${GREEN}✓ Pushed to registry: ${REGISTRY}/${IMAGE_NAME}:${VERSION}${NC}"
else
    echo -e "\n${BLUE}ℹ DOCKER_REGISTRY not set, skipping push to registry${NC}"
fi

# Display image info
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Build Summary:${NC}"
echo -e "  Image: ${IMAGE_NAME}:${VERSION}"
echo -e "  Size: $(docker images ${IMAGE_NAME}:${VERSION} --format "{{.Size}}")"
if [ -n "$REGISTRY" ]; then
    echo -e "  Registry: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
fi
echo -e "${BLUE}========================================${NC}"

echo -e "\n${GREEN}✓ Build completed successfully!${NC}"
echo -e "\nTo test locally with Docker Compose:"
echo -e "  ${BLUE}docker-compose up -d${NC}"
echo -e "\nTo deploy to Kubernetes:"
echo -e "  ${BLUE}./scripts/deploy-k8s.sh${NC}"
