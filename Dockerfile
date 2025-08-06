# Multi-stage build for SneakVLC
FROM golang:1.21-alpine AS backend-builder

# Install build dependencies
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the backend
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o sneakvlc cmd/sneakvlc/main.go

# Build web interface
FROM node:18-alpine AS frontend-builder

WORKDIR /app/web

# Copy package files
COPY web/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY web/ ./

# Build the frontend
RUN npm run build

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    vlc \
    ffmpeg \
    qrencode \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Create app user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy binary from backend builder
COPY --from=backend-builder /app/sneakvlc .

# Copy web assets from frontend builder
COPY --from=frontend-builder /app/web/dist ./web/dist

# Copy scripts
COPY scripts/ ./scripts/

# Make scripts executable
RUN chmod +x scripts/*.sh

# Create necessary directories
RUN mkdir -p /tmp/sneakvlc /app/received

# Change ownership
RUN chown -R appuser:appgroup /app /tmp/sneakvlc /app/received

# Switch to non-root user
USER appuser

# Expose ports
EXPOSE 8080 12345

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Default command
CMD ["./sneakvlc"] 