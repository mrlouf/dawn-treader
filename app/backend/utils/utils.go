package	utils

import (
	"os"
	"net/http"
	"log"
	"encoding/json"
)

func GenerateSpotifyToken() string {
	userId := os.Getenv("SPOTIFY_CLIENT_ID")
	clientSecret := os.Getenv("SPOTIFY_CLIENT_SECRET")

	httpClient := &http.Client{}
	req, err := http.NewRequest("POST", "https://accounts.spotify.com/api/token", nil)
	if err != nil {
		log.Fatal(err)
	}
	req.SetBasicAuth(userId, clientSecret)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	q := req.URL.Query()
	q.Add("grant_type", "client_credentials")
	req.URL.RawQuery = q.Encode()

	resp, err := httpClient.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	type TokenResponse struct {
		AccessToken string `json:"access_token"`
	}
	var tokenResp TokenResponse
	json.NewDecoder(resp.Body).Decode(&tokenResp)

	return tokenResp.AccessToken
}