package punchtable

import (
	"crypto/rand"
	"encoding/hex"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

// PunchEntry represents a NAT punch entry
type PunchEntry struct {
	ID        string    `json:"id"`
	Hash      string    `json:"hash"`
	IP        string    `json:"ip"`
	Port      int       `json:"port"`
	CreatedAt time.Time `json:"created_at"`
	LastSeen  time.Time `json:"last_seen"`
}

// PunchTable manages NAT punch entries with rotation
type PunchTable struct {
	entries map[string]*PunchEntry
	mutex   sync.RWMutex
	stop    chan struct{}
	maxSize int
}

// NewPunchTable creates a new punch table
func NewPunchTable() *PunchTable {
	return &PunchTable{
		entries: make(map[string]*PunchEntry),
		stop:    make(chan struct{}),
		maxSize: 10, // 10-line rotating table as mentioned in README
	}
}

// Start begins the punch table maintenance routine
func (pt *PunchTable) Start() {
	ticker := time.NewTicker(30 * time.Second) // Cleanup every 30 seconds
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			pt.cleanup()
		case <-pt.stop:
			return
		}
	}
}

// Stop stops the punch table maintenance
func (pt *PunchTable) Stop() {
	close(pt.stop)
}

// Add adds a new punch entry
func (pt *PunchTable) Add(hash, ip string, port int) string {
	pt.mutex.Lock()
	defer pt.mutex.Unlock()

	// Generate unique ID
	id := generateID()
	
	entry := &PunchEntry{
		ID:        id,
		Hash:      hash,
		IP:        ip,
		Port:      port,
		CreatedAt: time.Now(),
		LastSeen:  time.Now(),
	}

	// If table is full, remove oldest entry
	if len(pt.entries) >= pt.maxSize {
		pt.removeOldest()
	}

	pt.entries[id] = entry
	logrus.Infof("Added punch entry: %s -> %s:%d", hash, ip, port)
	
	return id
}

// Get retrieves a punch entry by hash
func (pt *PunchTable) Get(hash string) *PunchEntry {
	pt.mutex.RLock()
	defer pt.mutex.RUnlock()

	for _, entry := range pt.entries {
		if entry.Hash == hash {
			entry.LastSeen = time.Now()
			return entry
		}
	}
	return nil
}

// GetAll returns all punch entries
func (pt *PunchTable) GetAll() []*PunchEntry {
	pt.mutex.RLock()
	defer pt.mutex.RUnlock()

	entries := make([]*PunchEntry, 0, len(pt.entries))
	for _, entry := range pt.entries {
		entries = append(entries, entry)
	}
	return entries
}

// Remove removes a punch entry by ID
func (pt *PunchTable) Remove(id string) bool {
	pt.mutex.Lock()
	defer pt.mutex.Unlock()

	if _, exists := pt.entries[id]; exists {
		delete(pt.entries, id)
		logrus.Infof("Removed punch entry: %s", id)
		return true
	}
	return false
}

// cleanup removes old entries and maintains table size
func (pt *PunchTable) cleanup() {
	pt.mutex.Lock()
	defer pt.mutex.Unlock()

	now := time.Now()
	cutoff := now.Add(-5 * time.Minute) // Remove entries older than 5 minutes

	for id, entry := range pt.entries {
		if entry.LastSeen.Before(cutoff) {
			delete(pt.entries, id)
			logrus.Debugf("Cleaned up old punch entry: %s", id)
		}
	}
}

// removeOldest removes the oldest entry when table is full
func (pt *PunchTable) removeOldest() {
	var oldestID string
	var oldestTime time.Time

	for id, entry := range pt.entries {
		if oldestID == "" || entry.CreatedAt.Before(oldestTime) {
			oldestID = id
			oldestTime = entry.CreatedAt
		}
	}

	if oldestID != "" {
		delete(pt.entries, oldestID)
		logrus.Debugf("Removed oldest punch entry: %s", oldestID)
	}
}

// generateID generates a random 16-character ID
func generateID() string {
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
} 