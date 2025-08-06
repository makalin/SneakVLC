#!/bin/bash

# SneakVLC Sender Script
# Embeds files into H.264 streams using VLC and generates QR codes

set -e

# Configuration
VLC_PORT=12345
QR_DURATION=2
VLC_CACHE=0
X264_PRESET="ultrafast"
X264_TUNE="zerolatency"

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
        print_error "VLC is not installed. Please install VLC with x264 support."
        exit 1
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        print_warning "ffmpeg not found. Some features may be limited."
    fi
    
    if ! command -v qrencode &> /dev/null; then
        print_warning "qrencode not found. QR codes will not be generated."
    fi
    
    print_success "Dependencies check completed"
}

# Function to get local IP address
get_local_ip() {
    if command -v ip &> /dev/null; then
        ip route get 1.1.1.1 | awk '{print $7; exit}'
    elif command -v ifconfig &> /dev/null; then
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
    else
        print_error "Cannot determine local IP address"
        exit 1
    fi
}

# Function to generate file hash
generate_hash() {
    local file="$1"
    if command -v sha256sum &> /dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        print_error "No hash utility found (sha256sum or shasum)"
        exit 1
    fi
}

# Function to generate QR code
generate_qr() {
    local uri="$1"
    local qr_file="$2"
    
    if command -v qrencode &> /dev/null; then
        qrencode -t PNG -o "$qr_file" "$uri"
        print_success "QR code generated: $qr_file"
    else
        print_warning "qrencode not available, skipping QR generation"
    fi
}

# Function to create VLC playlist
create_vlc_playlist() {
    local file="$1"
    local hash="$2"
    local ip="$3"
    local port="$4"
    local playlist_file="$5"
    
    # Create magnet URI
    local magnet_uri="sneakvlc://${hash}?ip=${ip}&port=${port}"
    
    # Create VLC playlist with embedded file
    cat > "$playlist_file" << EOF
#EXTM3U
#EXTINF:-1,SneakVLC Stream
#EXTVLCOPT:network-caching=${VLC_CACHE}
#EXTVLCOPT:x264-preset=${X264_PRESET}
#EXTVLCOPT:x264-tune=${X264_TUNE}
#EXTVLCOPT:sub-file=${file}
#EXTVLCOPT:sub-text=${magnet_uri}
udp://@:${port}
EOF
    
    print_success "VLC playlist created: $playlist_file"
}

# Function to start VLC streaming
start_vlc_stream() {
    local playlist_file="$1"
    local port="$2"
    
    print_status "Starting VLC stream on port $port..."
    
    # Start VLC in headless mode
    vlc --intf dummy \
        --sout "#transcode{vcodec=h264,vb=1000,scale=1,acodec=none}:duplicate{dst=std{access=udp,mux=ts,dst=0.0.0.0:$port}}" \
        --network-caching=$VLC_CACHE \
        --x264-preset=$X264_PRESET \
        --x264-tune=$X264_TUNE \
        --sub-file="$playlist_file" \
        --playlist-autostart \
        --playlist-repeat \
        "$playlist_file" &
    
    local vlc_pid=$!
    echo $vlc_pid > /tmp/sneakvlc-vlc.pid
    
    print_success "VLC stream started (PID: $vlc_pid)"
    return $vlc_pid
}

# Function to display QR code
display_qr() {
    local qr_file="$1"
    local duration="$2"
    
    if [ -f "$qr_file" ] && command -v display &> /dev/null; then
        print_status "Displaying QR code for ${duration} seconds..."
        display -geometry +100+100 "$qr_file" &
        local display_pid=$!
        sleep "$duration"
        kill $display_pid 2>/dev/null || true
    elif [ -f "$qr_file" ]; then
        print_warning "ImageMagick 'display' not available. Please open $qr_file manually."
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Stop VLC if running
    if [ -f /tmp/sneakvlc-vlc.pid ]; then
        local vlc_pid=$(cat /tmp/sneakvlc-vlc.pid)
        if kill -0 $vlc_pid 2>/dev/null; then
            kill $vlc_pid
            print_success "VLC stream stopped"
        fi
        rm -f /tmp/sneakvlc-vlc.pid
    fi
    
    # Remove temporary files
    rm -f /tmp/sneakvlc-*.{m3u,png}
}

# Main function
main() {
    local file="$1"
    
    if [ -z "$file" ]; then
        print_error "Usage: $0 <file-to-send>"
        exit 1
    fi
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        exit 1
    fi
    
    # Setup cleanup on exit
    trap cleanup EXIT
    
    print_status "Starting SneakVLC sender..."
    print_status "File: $file"
    
    # Check dependencies
    check_dependencies
    
    # Get local IP
    local ip=$(get_local_ip)
    print_status "Local IP: $ip"
    
    # Generate file hash
    local hash=$(generate_hash "$file")
    print_status "File hash: $hash"
    
    # Create magnet URI
    local magnet_uri="sneakvlc://${hash}?ip=${ip}&port=${VLC_PORT}"
    print_status "Magnet URI: $magnet_uri"
    
    # Generate QR code
    local qr_file="/tmp/sneakvlc-qr.png"
    generate_qr "$magnet_uri" "$qr_file"
    
    # Create VLC playlist
    local playlist_file="/tmp/sneakvlc-playlist.m3u"
    create_vlc_playlist "$file" "$hash" "$ip" "$VLC_PORT" "$playlist_file"
    
    # Display QR code briefly
    display_qr "$qr_file" "$QR_DURATION"
    
    # Start VLC streaming
    start_vlc_stream "$playlist_file" "$VLC_PORT"
    
    print_success "SneakVLC sender is running!"
    print_status "Receivers can scan the QR code or use the magnet URI to connect"
    print_status "Press Ctrl+C to stop"
    
    # Keep running until interrupted
    while true; do
        sleep 1
    done
}

# Run main function with all arguments
main "$@" 