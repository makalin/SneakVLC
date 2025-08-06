#!/bin/bash

# SneakVLC Receiver Script
# Connects to VLC streams and extracts embedded files

set -e

# Configuration
DEFAULT_PORT=12345
OUTPUT_DIR="./received"
VLC_CACHE=0

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

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v vlc &> /dev/null; then
        print_error "VLC is not installed. Please install VLC with libVLC support."
        exit 1
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        print_error "ffmpeg is required for stream processing."
        exit 1
    fi
    
    print_success "Dependencies check completed"
}

# Function to parse magnet URI
parse_magnet_uri() {
    local uri="$1"
    
    # Extract hash from sneakvlc://<hash>?ip=<ip>&port=<port>
    local hash=$(echo "$uri" | sed -n 's/sneakvlc:\/\/\([^?]*\).*/\1/p')
    local ip=$(echo "$uri" | sed -n 's/.*ip=\([^&]*\).*/\1/p')
    local port=$(echo "$uri" | sed -n 's/.*port=\([^&]*\).*/\1/p')
    
    if [ -z "$hash" ] || [ -z "$ip" ] || [ -z "$port" ]; then
        print_error "Invalid magnet URI format: $uri"
        return 1
    fi
    
    echo "$hash|$ip|$port"
}

# Function to create output directory
create_output_dir() {
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
        print_success "Created output directory: $OUTPUT_DIR"
    fi
}

# Function to start VLC receiver
start_vlc_receiver() {
    local ip="$1"
    local port="$2"
    local output_file="$3"
    
    print_status "Starting VLC receiver for $ip:$port..."
    
    # Create VLC command for receiving
    local vlc_cmd="vlc --intf dummy \
        --network-caching=$VLC_CACHE \
        --sout \"#demux{demux=ts}:file{dst=$output_file}\" \
        udp://@$ip:$port"
    
    print_status "VLC command: $vlc_cmd"
    
    # Start VLC receiver
    eval $vlc_cmd &
    local vlc_pid=$!
    echo $vlc_pid > /tmp/sneakvlc-receiver.pid
    
    print_success "VLC receiver started (PID: $vlc_pid)"
    return $vlc_pid
}

# Function to extract embedded file
extract_embedded_file() {
    local stream_file="$1"
    local output_file="$2"
    
    print_status "Extracting embedded file from stream..."
    
    # Use ffmpeg to extract embedded data
    ffmpeg -i "$stream_file" \
        -map 0:d:0 \
        -c copy \
        "$output_file" \
        -y 2>/dev/null || {
        print_warning "Failed to extract with ffmpeg, trying alternative method..."
        
        # Alternative: try to extract subtitle data
        ffmpeg -i "$stream_file" \
            -map 0:s:0 \
            -c:s copy \
            "$output_file" \
            -y 2>/dev/null || {
            print_error "Failed to extract embedded file"
            return 1
        }
    }
    
    print_success "File extracted: $output_file"
}

# Function to verify file integrity
verify_file() {
    local file="$1"
    local expected_hash="$2"
    
    if [ -z "$expected_hash" ]; then
        print_warning "No hash provided for verification"
        return 0
    fi
    
    print_status "Verifying file integrity..."
    
    local actual_hash=""
    if command -v sha256sum &> /dev/null; then
        actual_hash=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum &> /dev/null; then
        actual_hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        print_warning "No hash utility found, skipping verification"
        return 0
    fi
    
    if [ "$actual_hash" = "$expected_hash" ]; then
        print_success "File integrity verified!"
        return 0
    else
        print_error "File integrity check failed!"
        print_error "Expected: $expected_hash"
        print_error "Actual:   $actual_hash"
        return 1
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Stop VLC receiver if running
    if [ -f /tmp/sneakvlc-receiver.pid ]; then
        local vlc_pid=$(cat /tmp/sneakvlc-receiver.pid)
        if kill -0 $vlc_pid 2>/dev/null; then
            kill $vlc_pid
            print_success "VLC receiver stopped"
        fi
        rm -f /tmp/sneakvlc-receiver.pid
    fi
    
    # Remove temporary stream files
    rm -f /tmp/sneakvlc-stream-*.ts
}

# Function to receive from magnet URI
receive_from_magnet() {
    local magnet_uri="$1"
    
    print_status "Processing magnet URI: $magnet_uri"
    
    # Parse magnet URI
    local parsed=$(parse_magnet_uri "$magnet_uri")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local hash=$(echo "$parsed" | cut -d'|' -f1)
    local ip=$(echo "$parsed" | cut -d'|' -f2)
    local port=$(echo "$parsed" | cut -d'|' -f3)
    
    print_status "Hash: $hash"
    print_status "IP: $ip"
    print_status "Port: $port"
    
    # Create output directory
    create_output_dir
    
    # Generate output filenames
    local stream_file="/tmp/sneakvlc-stream-${hash}.ts"
    local output_file="${OUTPUT_DIR}/received-${hash}"
    
    # Start VLC receiver
    start_vlc_receiver "$ip" "$port" "$stream_file"
    local vlc_pid=$!
    
    # Wait for stream to start
    print_status "Waiting for stream to start..."
    sleep 3
    
    # Check if stream is receiving data
    if [ ! -f "$stream_file" ] || [ ! -s "$stream_file" ]; then
        print_error "No stream data received"
        cleanup
        return 1
    fi
    
    print_success "Stream connection established!"
    print_status "Receiving data... Press Ctrl+C to stop"
    
    # Keep receiving until interrupted
    trap cleanup EXIT
    
    while true; do
        if [ -f "$stream_file" ] && [ -s "$stream_file" ]; then
            sleep 1
        else
            print_warning "Stream ended"
            break
        fi
    done
    
    # Extract embedded file
    if [ -f "$stream_file" ] && [ -s "$stream_file" ]; then
        extract_embedded_file "$stream_file" "$output_file"
        verify_file "$output_file" "$hash"
    fi
}

# Function to receive from manual input
receive_manual() {
    print_status "Manual connection mode"
    
    read -p "Enter sender IP: " ip
    read -p "Enter sender port [${DEFAULT_PORT}]: " port
    port=${port:-$DEFAULT_PORT}
    
    if [ -z "$ip" ]; then
        print_error "IP address is required"
        return 1
    fi
    
    # Create output directory
    create_output_dir
    
    # Generate temporary filenames
    local timestamp=$(date +%s)
    local stream_file="/tmp/sneakvlc-stream-${timestamp}.ts"
    local output_file="${OUTPUT_DIR}/received-${timestamp}"
    
    # Start VLC receiver
    start_vlc_receiver "$ip" "$port" "$stream_file"
    local vlc_pid=$!
    
    # Wait for stream to start
    print_status "Waiting for stream to start..."
    sleep 3
    
    # Check if stream is receiving data
    if [ ! -f "$stream_file" ] || [ ! -s "$stream_file" ]; then
        print_error "No stream data received"
        cleanup
        return 1
    fi
    
    print_success "Stream connection established!"
    print_status "Receiving data... Press Ctrl+C to stop"
    
    # Keep receiving until interrupted
    trap cleanup EXIT
    
    while true; do
        if [ -f "$stream_file" ] && [ -s "$stream_file" ]; then
            sleep 1
        else
            print_warning "Stream ended"
            break
        fi
    done
    
    # Extract embedded file
    if [ -f "$stream_file" ] && [ -s "$stream_file" ]; then
        extract_embedded_file "$stream_file" "$output_file"
        print_success "File received: $output_file"
    fi
}

# Function to show usage
show_usage() {
    echo "SneakVLC Receiver"
    echo ""
    echo "Usage:"
    echo "  $0 <magnet-uri>     - Receive from magnet URI"
    echo "  $0 --manual         - Manual connection mode"
    echo "  $0 --help           - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 'sneakvlc://3a8b...cf7f?ip=192.168.0.12&port=12345'"
    echo "  $0 --manual"
}

# Main function
main() {
    local arg="$1"
    
    if [ -z "$arg" ] || [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
        show_usage
        exit 0
    fi
    
    # Check dependencies
    check_dependencies
    
    # Setup cleanup on exit
    trap cleanup EXIT
    
    if [ "$arg" = "--manual" ]; then
        receive_manual
    else
        receive_from_magnet "$arg"
    fi
}

# Run main function with all arguments
main "$@" 