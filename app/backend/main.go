package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"backend/handlers"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	_, cancel := context.WithCancel(context.Background())
	defer cancel()

	http.HandleFunc("/health", handlers.HealthHandler)
	http.HandleFunc("/playlist/deezer", handlers.GetTrackNumberFromBothPlaylistsHandler)
	http.HandleFunc("/login/spotify", handlers.LoginSpotifyHandler)

	server := &http.Server{
		Addr: ":" + port,
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("Backend server starting on port %s", port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	<-stop
	log.Println("Shutting down server...")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
