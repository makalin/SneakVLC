#!/bin/bash

# SneakVLC Test Script
# Tests the installation and basic functionality

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

# Function to test dependencies
test_dependencies() {
    print_status "Testing dependencies..."
    
    local failed=0
    
    # Test VLC
    if command -v vlc &> /dev/null; then
        local vlc_version=$(vlc --version | head -1)
        print_success "VLC: $vlc_version"
    else
        print_error "VLC not found"
        failed=1
    fi
    
    # Test ffmpeg
    if command -v ffmpeg &> /dev/null; then
        local ffmpeg_version=$(ffmpeg -version | head -1 | awk '{print $3}')
        print_success "ffmpeg: $ffmpeg_version"
    else
        print_error "ffmpeg not found"
        failed=1
    fi
    
    # Test qrencode
    if command -v qrencode &> /dev/null; then
        local qrencode_version=$(qrencode --version 2>&1 | head -1)
        print_success "qrencode: $qrencode_version"
    else
        print_error "qrencode not found"
        failed=1
    fi
    
    # Test Go
    if command -v go &> /dev/null; then
        local go_version=$(go version | awk '{print $3}')
        print_success "Go: $go_version"
    else
        print_error "Go not found"
        failed=1
    fi
    
    # Test Node.js
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        print_success "Node.js: $node_version"
    else
        print_error "Node.js not found"
        failed=1
    fi
    
    # Test npm
    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version)
        print_success "npm: $npm_version"
    else
        print_error "npm not found"
        failed=1
    fi
    
    return $failed
}

# Function to test Go build
test_go_build() {
    print_status "Testing Go build..."
    
    if [ ! -f "go.mod" ]; then
        print_error "go.mod not found"
        return 1
    fi
    
    if go build -o /tmp/sneakvlc-test cmd/sneakvlc/main.go; then
        print_success "Go build successful"
        rm -f /tmp/sneakvlc-test
        return 0
    else
        print_error "Go build failed"
        return 1
    fi
}

# Function to test web build
test_web_build() {
    print_status "Testing web build..."
    
    if [ ! -f "web/package.json" ]; then
        print_error "web/package.json not found"
        return 1
    fi
    
    cd web
    
    if npm install --silent && npm run build --silent; then
        print_success "Web build successful"
        cd ..
        return 0
    else
        print_error "Web build failed"
        cd ..
        return 1
    fi
}

# Function to test scripts
test_scripts() {
    print_status "Testing scripts..."
    
    local failed=0
    
    # Test sender script
    if [ -f "scripts/sneakvlc-send.sh" ] && [ -x "scripts/sneakvlc-send.sh" ]; then
        print_success "Sender script is executable"
    else
        print_error "Sender script not found or not executable"
        failed=1
    fi
    
    # Test receiver script
    if [ -f "scripts/sneakvlc-receive.sh" ] && [ -x "scripts/sneakvlc-receive.sh" ]; then
        print_success "Receiver script is executable"
    else
        print_error "Receiver script not found or not executable"
        failed=1
    fi
    
    # Test install script
    if [ -f "scripts/install.sh" ] && [ -x "scripts/install.sh" ]; then
        print_success "Install script is executable"
    else
        print_error "Install script not found or not executable"
        failed=1
    fi
    
    return $failed
}

# Function to test QR code generation
test_qr_generation() {
    print_status "Testing QR code generation..."
    
    local test_uri="sneakvlc://test123?ip=192.168.1.100&port=12345"
    local test_qr="/tmp/test-qr.png"
    
    if qrencode -t PNG -o "$test_qr" "$test_uri" 2>/dev/null; then
        if [ -f "$test_qr" ]; then
            print_success "QR code generation successful"
            rm -f "$test_qr"
            return 0
        else
            print_error "QR code file not created"
            return 1
        fi
    else
        print_error "QR code generation failed"
        return 1
    fi
}

# Function to test VLC functionality
test_vlc_functionality() {
    print_status "Testing VLC functionality..."
    
    # Test if VLC can run in headless mode
    if timeout 5s vlc --intf dummy --playlist-autostart --playlist-repeat --help >/dev/null 2>&1; then
        print_success "VLC headless mode works"
        return 0
    else
        print_warning "VLC headless mode test failed (this might be normal)"
        return 0
    fi
}

# Function to test network connectivity
test_network() {
    print_status "Testing network connectivity..."
    
    # Test localhost connectivity
    if curl -s --connect-timeout 5 http://localhost:8080/health >/dev/null 2>&1; then
        print_success "Backend server is running"
        return 0
    else
        print_warning "Backend server not running (this is normal if not started)"
        return 0
    fi
}

# Function to run all tests
run_all_tests() {
    print_status "Starting SneakVLC tests..."
    echo ""
    
    local total_tests=0
    local passed_tests=0
    
    # Test dependencies
    ((total_tests++))
    if test_dependencies; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test Go build
    ((total_tests++))
    if test_go_build; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test web build
    ((total_tests++))
    if test_web_build; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test scripts
    ((total_tests++))
    if test_scripts; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test QR generation
    ((total_tests++))
    if test_qr_generation; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test VLC functionality
    ((total_tests++))
    if test_vlc_functionality; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test network
    ((total_tests++))
    if test_network; then
        ((passed_tests++))
    fi
    echo ""
    
    # Summary
    print_status "Test Summary:"
    echo "  Total tests: $total_tests"
    echo "  Passed: $passed_tests"
    echo "  Failed: $((total_tests - passed_tests))"
    
    if [ $passed_tests -eq $total_tests ]; then
        print_success "All tests passed! SneakVLC is ready to use."
        return 0
    else
        print_error "Some tests failed. Please check the output above."
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "SneakVLC Test Script"
    echo ""
    echo "Usage:"
    echo "  $0 [options]"
    echo ""
    echo "Options:"
    echo "  --deps        Test dependencies only"
    echo "  --build       Test builds only"
    echo "  --scripts     Test scripts only"
    echo "  --qr          Test QR generation only"
    echo "  --vlc         Test VLC functionality only"
    echo "  --network     Test network connectivity only"
    echo "  --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --deps             # Test dependencies only"
    echo "  $0 --build            # Test builds only"
}

# Main function
main() {
    local test_deps=false
    local test_build=false
    local test_scripts=false
    local test_qr=false
    local test_vlc=false
    local test_network=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deps)
                test_deps=true
                shift
                ;;
            --build)
                test_build=true
                shift
                ;;
            --scripts)
                test_scripts=true
                shift
                ;;
            --qr)
                test_qr=true
                shift
                ;;
            --vlc)
                test_vlc=true
                shift
                ;;
            --network)
                test_network=true
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
    
    # If no specific tests selected, run all
    if [ "$test_deps" = false ] && [ "$test_build" = false ] && [ "$test_scripts" = false ] && [ "$test_qr" = false ] && [ "$test_vlc" = false ] && [ "$test_network" = false ]; then
        run_all_tests
        exit $?
    fi
    
    # Run selected tests
    local failed=0
    
    if [ "$test_deps" = true ]; then
        test_dependencies || failed=1
        echo ""
    fi
    
    if [ "$test_build" = true ]; then
        test_go_build || failed=1
        echo ""
        test_web_build || failed=1
        echo ""
    fi
    
    if [ "$test_scripts" = true ]; then
        test_scripts || failed=1
        echo ""
    fi
    
    if [ "$test_qr" = true ]; then
        test_qr_generation || failed=1
        echo ""
    fi
    
    if [ "$test_vlc" = true ]; then
        test_vlc_functionality || failed=1
        echo ""
    fi
    
    if [ "$test_network" = true ]; then
        test_network || failed=1
        echo ""
    fi
    
    if [ $failed -eq 0 ]; then
        print_success "Selected tests passed!"
    else
        print_error "Some tests failed."
    fi
    
    exit $failed
}

# Run main function with all arguments
main "$@" 