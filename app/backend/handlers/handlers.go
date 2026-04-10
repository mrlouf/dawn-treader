package handlers

import (
	"encoding/json"
	"net/http"
	"fmt"
	"os"
	"log"

	"backend/utils"
)

type DeezerResponse struct {
	Total int `json:"nb_tracks"`
}

type SpotifyResponse struct {
	Tracks struct {
		Total int `json:"total"`
	} `json:"tracks"`
}

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `<span class="status-value">✅ Running</span>`)
}

func GetTrackNumberFromBothPlaylistsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Fetch from Deezer
	nbTracksDeezer := getTrackNumberFromDeezer(w)

	// Fetch from Spotify
	nbTracksSpotify := getTrackNumberFromSpotify(w)

	result := map[string]interface{}{
		"status":				"success",
		"nb_tracks_Deezer":   	nbTracksDeezer.Total,
		"nb_tracks_Spotify":    nbTracksSpotify.Tracks.Total,
	}

	json.NewEncoder(w).Encode(result)
	return
}


func LoginSpotifyHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Simulate login process
	result := map[string]interface{}{
		"status":  "success",
		"message": "Spotify login simulated successfully",
	}

	json.NewEncoder(w).Encode(result)
}

func getTrackNumberFromDeezer(w http.ResponseWriter) DeezerResponse {
	deezerPlaylistID := os.Getenv("DEEZER_PLAYLIST_ID")
	if deezerPlaylistID == "" {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "error",
			"message": "DEEZER_PLAYLIST_ID not set in environment",
		})
		return DeezerResponse{}
	}

	url := fmt.Sprintf("https://api.deezer.com/playlist/%s", deezerPlaylistID)

	resp, err := http.Get(url)
	if err != nil {
		log.Fatal(err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "error",
			"message": "Failed to fetch playlist from Deezer",
		})
		return DeezerResponse{}
	}
	defer resp.Body.Close()

	var nbTracksDeezer DeezerResponse
	json.NewDecoder(resp.Body).Decode(&nbTracksDeezer)

	return nbTracksDeezer
}

func getTrackNumberFromSpotify(w http.ResponseWriter) SpotifyResponse {

	spotifyPlaylistID := os.Getenv("SPOTIFY_PLAYLIST_ID")
	if spotifyPlaylistID == "" {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "error",
			"message": "SPOTIFY_PLAYLIST_ID not set in environment",
		})
		return SpotifyResponse{}
	}
	url := fmt.Sprintf("https://api.spotify.com/v1/playlists/%s", spotifyPlaylistID)

	req, err := http.NewRequest("GET", url, nil)
	token := utils.GenerateSpotifyToken()
	fmt.Println("Generated Spotify Token:", token)
	req.Header.Set("Authorization", "Bearer " + token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "error",
			"message": "Failed to fetch playlist from Spotify",
		})
		return SpotifyResponse{}
	}
	defer resp.Body.Close()

	var nbTracksSpotify SpotifyResponse
	json.NewDecoder(resp.Body).Decode(&nbTracksSpotify)

	return nbTracksSpotify
}