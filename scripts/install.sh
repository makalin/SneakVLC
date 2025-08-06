#!/bin/bash

# SneakVLC Installation Script
# Installs dependencies and sets up the system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "ubuntu"
        elif command -v yum &> /dev/null; then
            echo "centos"
        elif command -v pacman &> /dev/null; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to install dependencies on Ubuntu/Debian
install_ubuntu() {
    print_status "Installing dependencies on Ubuntu/Debian..."
    
    sudo apt-get update
    sudo apt-get install -y \
        vlc \
        ffmpeg \
        qrencode \
        golang-go \
        nodejs \
        npm \
        git \
        curl \
        wget
    
    print_success "Ubuntu/Debian dependencies installed"
}

# Function to install dependencies on CentOS/RHEL
install_centos() {
    print_status "Installing dependencies on CentOS/RHEL..."
    
    sudo yum update -y
    sudo yum install -y \
        vlc \
        ffmpeg \
        qrencode \
        golang \
        nodejs \
        npm \
        git \
        curl \
        wget
    
    print_success "CentOS/RHEL dependencies installed"
}

# Function to install dependencies on Arch Linux
install_arch() {
    print_status "Installing dependencies on Arch Linux..."
    
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm \
        vlc \
        ffmpeg \
        qrencode \
        go \
        nodejs \
        npm \
        git \
        curl \
        wget
    
    print_success "Arch Linux dependencies installed"
}

# Function to install dependencies on macOS
install_macos() {
    print_status "Installing dependencies on macOS..."
    
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is required. Please install it first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    brew update
    brew install \
        vlc \
        ffmpeg \
        qrencode \
        go \
        node \
        git
    
    print_success "macOS dependencies installed"
}

# Function to verify installations
verify_installations() {
    print_status "Verifying installations..."
    
    local missing_deps=()
    
    # Check VLC
    if ! command -v vlc &> /dev/null; then
        missing_deps+=("vlc")
    fi
    
    # Check ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        missing_deps+=("ffmpeg")
    fi
    
    # Check qrencode
    if ! command -v qrencode &> /dev/null; then
        missing_deps+=("qrencode")
    fi
    
    # Check Go
    if ! command -v go &> /dev/null; then
        missing_deps+=("go")
    else
        local go_version=$(go version | awk '{print $3}')
        print_status "Go version: $go_version"
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    else
        local node_version=$(node --version)
        print_status "Node.js version: $node_version"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    else
        local npm_version=$(npm --version)
        print_status "npm version: $npm_version"
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "All dependencies are installed!"
        return 0
    else
        print_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Function to setup project
setup_project() {
    print_status "Setting up SneakVLC project..."
    
    # Install Go dependencies
    if [ -f "go.mod" ]; then
        print_status "Installing Go dependencies..."
        go mod tidy
        print_success "Go dependencies installed"
    fi
    
    # Install web dependencies
    if [ -d "web" ] && [ -f "web/package.json" ]; then
        print_status "Installing web dependencies..."
        cd web && npm install && cd ..
        print_success "Web dependencies installed"
    fi
    
    # Make scripts executable
    if [ -d "scripts" ]; then
        print_status "Making scripts executable..."
        chmod +x scripts/*.sh
        print_success "Scripts made executable"
    fi
    
    # Create necessary directories
    print_status "Creating directories..."
    mkdir -p received tmp/sneakvlc
    print_success "Directories created"
}

# Function to show usage
show_usage() {
    echo "SneakVLC Installation Script"
    echo ""
    echo "Usage:"
    echo "  $0 [options]"
    echo ""
    echo "Options:"
    echo "  --os <os>     Specify OS (ubuntu, centos, arch, macos)"
    echo "  --verify      Only verify installations"
    echo "  --setup       Only setup project (skip dependency installation)"
    echo "  --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Auto-detect OS and install"
    echo "  $0 --os ubuntu        # Install on Ubuntu"
    echo "  $0 --verify           # Only verify installations"
    echo "  $0 --setup            # Only setup project"
}

# Main function
main() {
    local os=""
    local verify_only=false
    local setup_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --os)
                os="$2"
                shift 2
                ;;
            --verify)
                verify_only=true
                shift
                ;;
            --setup)
                setup_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "Starting SneakVLC installation..."
    
    if [ "$verify_only" = true ]; then
        verify_installations
        exit $?
    fi
    
    if [ "$setup_only" = true ]; then
        setup_project
        exit 0
    fi
    
    # Detect OS if not specified
    if [ -z "$os" ]; then
        os=$(detect_os)
        print_status "Detected OS: $os"
    fi
    
    # Install dependencies based on OS
    case $os in
        ubuntu|debian)
            install_ubuntu
            ;;
        centos|rhel|fedora)
            install_centos
            ;;
        arch)
            install_arch
            ;;
        macos)
            install_macos
            ;;
        *)
            print_error "Unsupported OS: $os"
            print_error "Please install dependencies manually:"
            echo "  - VLC with x264 support"
            echo "  - ffmpeg"
            echo "  - qrencode"
            echo "  - Go 1.21+"
            echo "  - Node.js 18+"
            exit 1
            ;;
    esac
    
    # Verify installations
    if verify_installations; then
        # Setup project
        setup_project
        
        print_success "SneakVLC installation completed!"
        echo ""
        echo "Next steps:"
        echo "  1. Run 'make build' to build the project"
        echo "  2. Run 'make all' to start the application"
        echo "  3. Open http://localhost:3000 in your browser"
        echo ""
        echo "For more information, see README.md"
    else
        print_error "Installation failed. Please install missing dependencies manually."
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 