package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/makalin/sneakvlc/internal/server"
	"github.com/makalin/sneakvlc/internal/punchtable"
	"github.com/sirupsen/logrus"
)

func main() {
	var (
		port = flag.String("port", "8080", "Server port")
		host = flag.String("host", "0.0.0.0", "Server host")
	)
	flag.Parse()

	// Configure logging
	logrus.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
	})
	logrus.SetLevel(logrus.InfoLevel)

	// Initialize NAT punch table
	punchTable := punchtable.NewPunchTable()
	go punchTable.Start()

	// Initialize server
	srv := server.NewServer(punchTable)
	
	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		logrus.Info("Shutting down server...")
		punchTable.Stop()
		os.Exit(0)
	}()

	// Start server
	addr := *host + ":" + *port
	logrus.Infof("Starting SneakVLC server on %s", addr)
	log.Fatal(http.ListenAndServe(addr, srv.Router()))
} 