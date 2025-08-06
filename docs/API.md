# SneakVLC API Documentation

## Overview

The SneakVLC API provides endpoints for managing P2P file transfers, NAT punch entries, and real-time communication via WebSocket.

## Base URL

```
http://localhost:8080
```

## Authentication

Currently, no authentication is required. All endpoints are publicly accessible for P2P functionality.

## Endpoints

### Health Check

#### GET /health

Check if the server is running.

**Response:**
```json
{
  "status": "healthy",
  "service": "sneakvlc",
  "version": "1.0.0"
}
```

### NAT Punch Management

#### POST /api/punch

Create a new NAT punch entry.

**Request Body:**
```json
{
  "hash": "3a8b...cf7f",
  "ip": "192.168.1.100",
  "port": 12345
}
```

**Response:**
```json
{
  "id": "a1b2c3d4e5f6",
  "status": "success"
}
```

#### GET /api/lookup/{hash}

Look up a punch entry by file hash.

**Response:**
```json
{
  "id": "a1b2c3d4e5f6",
  "hash": "3a8b...cf7f",
  "ip": "192.168.1.100",
  "port": 12345,
  "created_at": "2024-01-01T12:00:00Z",
  "last_seen": "2024-01-01T12:05:00Z"
}
```

#### GET /api/entries

Get all punch entries.

**Response:**
```json
[
  {
    "id": "a1b2c3d4e5f6",
    "hash": "3a8b...cf7f",
    "ip": "192.168.1.100",
    "port": 12345,
    "created_at": "2024-01-01T12:00:00Z",
    "last_seen": "2024-01-01T12:05:00Z"
  }
]
```

#### DELETE /api/entries/{id}

Remove a punch entry by ID.

**Response:** 204 No Content

### WebSocket

#### WebSocket /ws

Real-time communication endpoint for receiving updates about punch entries.

**Connection:**
```javascript
const ws = new WebSocket('ws://localhost:8080/ws');
```

**Messages:**
- Initial connection sends all current entries
- Echo back for testing (can be extended for commands)

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request body"
}
```

### 404 Not Found
```json
{
  "error": "Entry not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Data Models

### PunchEntry

```typescript
interface PunchEntry {
  id: string;           // Unique identifier
  hash: string;         // File hash (SHA-256)
  ip: string;          // IP address
  port: number;        // Port number
  created_at: string;  // ISO 8601 timestamp
  last_seen: string;   // ISO 8601 timestamp
}
```

## Rate Limiting

Currently, no rate limiting is implemented. The system uses a rotating table with a maximum of 10 entries.

## WebSocket Events

### Connection Events

- `open`: Connection established
- `message`: Data received
- `close`: Connection closed
- `error`: Connection error

### Message Format

All WebSocket messages are JSON strings.

## Examples

### JavaScript Client

```javascript
// Create a punch entry
const response = await fetch('/api/punch', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    hash: '3a8b...cf7f',
    ip: '192.168.1.100',
    port: 12345
  })
});

const result = await response.json();
console.log(result.id);

// WebSocket connection
const ws = new WebSocket('ws://localhost:8080/ws');

ws.onopen = () => {
  console.log('Connected to SneakVLC');
};

ws.onmessage = (event) => {
  const entries = JSON.parse(event.data);
  console.log('Received entries:', entries);
};
```

### cURL Examples

```bash
# Health check
curl http://localhost:8080/health

# Create punch entry
curl -X POST http://localhost:8080/api/punch \
  -H "Content-Type: application/json" \
  -d '{"hash":"3a8b...cf7f","ip":"192.168.1.100","port":12345}'

# Get all entries
curl http://localhost:8080/api/entries

# Look up by hash
curl http://localhost:8080/api/lookup/3a8b...cf7f

# Remove entry
curl -X DELETE http://localhost:8080/api/entries/a1b2c3d4e5f6
```

## Configuration

The server can be configured with the following environment variables:

- `SERVER_PORT`: HTTP server port (default: 8080)
- `SERVER_HOST`: HTTP server host (default: 0.0.0.0)
- `MAX_TABLE_SIZE`: Maximum punch entries (default: 10)
- `CLEANUP_INTERVAL`: Cleanup interval in seconds (default: 30)

## Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created
- `204 No Content`: Request successful, no content
- `400 Bad Request`: Invalid request
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error 