#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Artists & Albums API - Build and Deployment Script${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    print_error "Maven not found. Please install Maven first."
    exit 1
fi

print_status "Maven found"

# Build the project
echo ""
echo -e "${YELLOW}Building project...${NC}"
mvn clean package -DskipTests

if [ $? -eq 0 ]; then
    print_status "Build successful"
else
    print_error "Build failed"
    exit 1
fi

# Build Docker image
if command -v docker &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Building Docker image...${NC}"
    docker build -t artists-api:1.0.0 .
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully"
    else
        print_error "Docker build failed"
        exit 1
    fi
fi

# Docker Compose up
if command -v docker-compose &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Starting services with Docker Compose...${NC}"
    docker-compose up -d
    if [ $? -eq 0 ]; then
        print_status "Services started successfully"
        echo ""
        echo -e "${YELLOW}Service URLs:${NC}"
        echo "  - API: http://localhost:8080/api"
        echo "  - Swagger UI: http://localhost:8080/api/swagger-ui.html"
        echo "  - MinIO Console: http://localhost:9001"
        echo ""
        echo -e "${YELLOW}Default Credentials:${NC}"
        echo "  - API: admin:admin"
        echo "  - MinIO: minioadmin:minioadmin"
    else
        print_error "Failed to start services"
        exit 1
    fi
fi

print_status "Build and deployment completed!"
