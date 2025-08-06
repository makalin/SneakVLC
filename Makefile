# SneakVLC Makefile
# Build and manage the P2P file transfer system

.PHONY: help build clean test install deps web-build web-dev backend-run all

# Default target
help:
	@echo "SneakVLC - P2P File Transfer System"
	@echo ""
	@echo "Available targets:"
	@echo "  help        - Show this help message"
	@echo "  deps        - Install all dependencies"
	@echo "  build       - Build the entire project"
	@echo "  clean       - Clean build artifacts"
	@echo "  test        - Run tests"
	@echo "  install     - Install system dependencies"
	@echo "  web-build   - Build the web interface"
	@echo "  web-dev     - Start web development server"
	@echo "  backend-run - Run the Go backend server"
	@echo "  all         - Build and run everything"

# Install dependencies
deps:
	@echo "Installing Go dependencies..."
	@cd . && go mod tidy
	@echo "Installing web dependencies..."
	@cd web && npm install

# Build the entire project
build: deps
	@echo "Building SneakVLC..."
	@mkdir -p bin
	@go build -o bin/sneakvlc cmd/sneakvlc/main.go
	@echo "Building web interface..."
	@cd web && npm run build
	@echo "Build complete!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf bin/
	@rm -rf web/dist/
	@rm -rf web/node_modules/
	@go clean
	@echo "Clean complete!"

# Run tests
test:
	@echo "Running tests..."
	@go test ./...
	@cd web && npm test

# Install system dependencies
install:
	@echo "Installing system dependencies..."
	@echo "Please install the following packages:"
	@echo "  - VLC with x264 support"
	@echo "  - ffmpeg"
	@echo "  - qrencode"
	@echo "  - Go 1.21+"
	@echo "  - Node.js 18+"
	@echo ""
	@echo "On macOS: brew install vlc ffmpeg qrencode go node"
	@echo "On Ubuntu: sudo apt install vlc ffmpeg qrencode golang-go nodejs npm"
	@echo "On CentOS: sudo yum install vlc ffmpeg qrencode golang nodejs npm"

# Build web interface
web-build:
	@echo "Building web interface..."
	@cd web && npm run build

# Start web development server
web-dev:
	@echo "Starting web development server..."
	@cd web && npm run dev

# Run the Go backend server
backend-run:
	@echo "Starting SneakVLC backend server..."
	@go run cmd/sneakvlc/main.go

# Build and run everything
all: build
	@echo "Starting SneakVLC..."
	@echo "Backend: http://localhost:8080"
	@echo "Web UI: http://localhost:3000"
	@echo ""
	@echo "Press Ctrl+C to stop"
	@$(MAKE) -j2 backend-run web-dev

# Development helpers
dev-setup: deps
	@echo "Development setup complete!"
	@echo "Run 'make web-dev' for web development"
	@echo "Run 'make backend-run' for backend development"

# Docker targets (if needed)
docker-build:
	@echo "Building Docker image..."
	@docker build -t sneakvlc .

docker-run:
	@echo "Running SneakVLC in Docker..."
	@docker run -p 8080:8080 -p 3000:3000 sneakvlc

# Release targets
release: clean build
	@echo "Creating release..."
	@mkdir -p release
	@cp -r bin/ release/
	@cp -r web/dist/ release/web/
	@cp scripts/*.sh release/
	@cp README.md release/
	@cp LICENSE release/
	@echo "Release created in release/ directory"

# Quick start
quick-start: deps
	@echo "Quick start - running backend..."
	@go run cmd/sneakvlc/main.go 