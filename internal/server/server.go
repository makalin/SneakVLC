package server

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/makalin/sneakvlc/internal/punchtable"
	"github.com/sirupsen/logrus"
)

// Server handles HTTP and WebSocket connections
type Server struct {
	punchTable *punchtable.PunchTable
	upgrader   websocket.Upgrader
}

// NewServer creates a new server instance
func NewServer(pt *punchtable.PunchTable) *Server {
	return &Server{
		punchTable: pt,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins for P2P
			},
		},
	}
}

// Router returns the HTTP router with all routes
func (s *Server) Router() *mux.Router {
	r := mux.NewRouter()

	// API routes
	r.HandleFunc("/api/punch", s.handlePunch).Methods("POST")
	r.HandleFunc("/api/lookup/{hash}", s.handleLookup).Methods("GET")
	r.HandleFunc("/api/entries", s.handleGetEntries).Methods("GET")
	r.HandleFunc("/api/entries/{id}", s.handleRemoveEntry).Methods("DELETE")

	// WebSocket endpoint for real-time updates
	r.HandleFunc("/ws", s.handleWebSocket)

	// Health check
	r.HandleFunc("/health", s.handleHealth).Methods("GET")

	// Static files (for web interface)
	r.PathPrefix("/").Handler(http.FileServer(http.Dir("web/dist")))

	return r
}

// handlePunch handles new punch entry creation
func (s *Server) handlePunch(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Hash string `json:"hash"`
		IP   string `json:"ip"`
		Port int    `json:"port"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Hash == "" || req.IP == "" || req.Port == 0 {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	id := s.punchTable.Add(req.Hash, req.IP, req.Port)

	response := map[string]string{
		"id":     id,
		"status": "success",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleLookup handles punch entry lookup by hash
func (s *Server) handleLookup(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	hash := vars["hash"]

	if hash == "" {
		http.Error(w, "Hash parameter required", http.StatusBadRequest)
		return
	}

	entry := s.punchTable.Get(hash)
	if entry == nil {
		http.Error(w, "Entry not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entry)
}

// handleGetEntries returns all punch entries
func (s *Server) handleGetEntries(w http.ResponseWriter, r *http.Request) {
	entries := s.punchTable.GetAll()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entries)
}

// handleRemoveEntry removes a punch entry by ID
func (s *Server) handleRemoveEntry(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	if id == "" {
		http.Error(w, "ID parameter required", http.StatusBadRequest)
		return
	}

	if s.punchTable.Remove(id) {
		w.WriteHeader(http.StatusNoContent)
	} else {
		http.Error(w, "Entry not found", http.StatusNotFound)
	}
}

// handleWebSocket handles WebSocket connections for real-time updates
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logrus.Errorf("WebSocket upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	logrus.Infof("WebSocket connection established from %s", r.RemoteAddr)

	// Send initial entries
	entries := s.punchTable.GetAll()
	if err := conn.WriteJSON(entries); err != nil {
		logrus.Errorf("Failed to send initial entries: %v", err)
		return
	}

	// Keep connection alive and handle incoming messages
	for {
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			logrus.Debugf("WebSocket read error: %v", err)
			break
		}

		// Echo back for now (could be extended for real-time commands)
		if err := conn.WriteMessage(messageType, message); err != nil {
			logrus.Errorf("WebSocket write error: %v", err)
			break
		}
	}
}

// handleHealth returns server health status
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":  "healthy",
		"service": "sneakvlc",
		"version": "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
