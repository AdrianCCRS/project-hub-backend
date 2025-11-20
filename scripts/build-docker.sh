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

# Import to MicroK8s if available
if command -v microk8s &> /dev/null; then
    echo -e "\n${GREEN}Step 4: Importing image to MicroK8s...${NC}"
    
    # Save Docker image to tar
    TEMP_TAR="/tmp/${IMAGE_NAME}-${VERSION}.tar"
    docker save ${IMAGE_NAME}:${VERSION} > ${TEMP_TAR}
    
    # Import to MicroK8s
    microk8s ctr image import ${TEMP_TAR}
    
    # Clean up tar file
    rm ${TEMP_TAR}
    
    echo -e "${GREEN}✓ Image imported to MicroK8s${NC}"
    
    # Verify image is available
    echo -e "\n${BLUE}Verifying image in MicroK8s:${NC}"
    microk8s ctr images ls | grep ${IMAGE_NAME} || echo -e "${RED}Warning: Image not found in MicroK8s${NC}"
else
    echo -e "\n${BLUE}ℹ MicroK8s not detected, skipping import${NC}"
fi

# Display image info
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Build Summary:${NC}"
echo -e "  Image: ${IMAGE_NAME}:${VERSION}"
echo -e "  Size: $(docker images ${IMAGE_NAME}:${VERSION} --format "{{.Size}}")"
if [ -n "$REGISTRY" ]; then
    echo -e "  Registry: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
fi
if command -v microk8s &> /dev/null; then
    echo -e "  MicroK8s: ✓ Imported"
fi
echo -e "${BLUE}========================================${NC}"

echo -e "\n${GREEN}✓ Build completed successfully!${NC}"
echo -e "\nTo test locally with Docker Compose:"
echo -e "  ${BLUE}docker-compose up -d${NC}"
echo -e "\nTo deploy to Kubernetes:"
echo -e "  ${BLUE}./scripts/deploy-k8s.sh${NC}"
