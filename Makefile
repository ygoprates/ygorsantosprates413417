.PHONY: help build test run docker-build docker-up docker-down clean logs

help:
	@echo "Artists & Albums API - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build         - Build the project with Maven"
	@echo "  make test          - Run unit tests"
	@echo "  make run           - Run the application locally"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-up     - Start services with Docker Compose"
	@echo "  make docker-down   - Stop Docker Compose services"
	@echo "  make logs          - View Docker Compose logs"
	@echo "  make clean         - Clean Maven build artifacts"
	@echo "  make format        - Format code"
	@echo "  make help          - Show this help message"

build:
	mvn clean package -DskipTests

test:
	mvn test

run: build
	java -jar target/artists-api-1.0.0.jar

docker-build:
	docker build -t artists-api:1.0.0 .

docker-up: docker-build
	docker-compose up -d
	@echo ""
	@echo "Services started!"
	@echo "API: http://localhost:8080/api"
	@echo "Swagger: http://localhost:8080/api/swagger-ui.html"
	@echo "MinIO: http://localhost:9001"

docker-down:
	docker-compose down

logs:
	docker-compose logs -f api

clean:
	mvn clean
	docker-compose down -v

format:
	mvn com.spotify.fmt:fmt-maven-plugin:format

install-dependencies:
	mvn install

all: clean build test docker-build docker-up

.DEFAULT_GOAL := help
