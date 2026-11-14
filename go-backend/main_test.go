package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func setupTestServer(t *testing.T) *gin.Engine {
	t.Helper()
	gin.SetMode(gin.TestMode)
	var err error
	db, err = initDatabase(":memory:")
	if err != nil {
		t.Fatalf("failed to open in-memory sqlite: %v", err)
	}
	return setupRouter("")
}

func TestHealthAndOptionsCORS(t *testing.T) {
	r := setupTestServer(t)

	// GET /health
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 on /health, got %d", w.Code)
	}

	// OPTIONS preflight returns 204 No Content
	optReq := httptest.NewRequest(http.MethodOptions, "/scores", nil)
	optW := httptest.NewRecorder()
	r.ServeHTTP(optW, optReq)
	if optW.Code != http.StatusNoContent {
		t.Fatalf("expected 204 on OPTIONS preflight, got %d", optW.Code)
	}
}

func TestPlayerRegisterScoreHMACAndLiveLeaderboard(t *testing.T) {
	r := setupTestServer(t)

	// 1. Register player
	regBody := []byte(`{"username":"ValkyrieAce"}`)
	regReq := httptest.NewRequest(http.MethodPost, "/players", bytes.NewReader(regBody))
	regReq.Header.Set("Content-Type", "application/json")
	regW := httptest.NewRecorder()
	r.ServeHTTP(regW, regReq)
	if regW.Code != http.StatusCreated {
		t.Fatalf("expected 201 on /players, got %d (%s)", regW.Code, regW.Body.String())
	}

	var player Player
	if err := json.Unmarshal(regW.Body.Bytes(), &player); err != nil {
		t.Fatalf("failed to parse player json: %v", err)
	}

	// 2. Reject invalid HMAC signature
	badPayload := map[string]any{
		"player_id": player.ID,
		"scientist": "Lyra",
		"score":     9001,
		"level":     5,
		"mode":      "arcade",
		"signature": "forged-sig",
	}
	badBytes, _ := json.Marshal(badPayload)
	badReq := httptest.NewRequest(http.MethodPost, "/scores", bytes.NewReader(badBytes))
	badReq.Header.Set("Content-Type", "application/json")
	badW := httptest.NewRecorder()
	r.ServeHTTP(badW, badReq)
	if badW.Code != http.StatusForbidden {
		t.Fatalf("expected 403 on forged HMAC signature, got %d", badW.Code)
	}

	// 3. Accept valid HMAC signature
	sig := computeScoreSignature(player.ID, 9001, 5, "arcade", getSecretKey())
	goodPayload := map[string]any{
		"player_id": player.ID,
		"scientist": "Lyra",
		"score":     9001,
		"level":     5,
		"mode":      "arcade",
		"signature": sig,
	}
	goodBytes, _ := json.Marshal(goodPayload)
	goodReq := httptest.NewRequest(http.MethodPost, "/scores", bytes.NewReader(goodBytes))
	goodReq.Header.Set("Content-Type", "application/json")
	goodW := httptest.NewRecorder()
	r.ServeHTTP(goodW, goodReq)
	if goodW.Code != http.StatusCreated {
		t.Fatalf("expected 201 on valid score submission, got %d (%s)", goodW.Code, goodW.Body.String())
	}

	// 4. Query scores JSON
	listReq := httptest.NewRequest(http.MethodGet, "/scores?mode=arcade&limit=5", nil)
	listW := httptest.NewRecorder()
	r.ServeHTTP(listW, listReq)
	if listW.Code != http.StatusOK {
		t.Fatalf("expected 200 on GET /scores, got %d", listW.Code)
	}
	if !bytes.Contains(listW.Body.Bytes(), []byte("ValkyrieAce")) {
		t.Fatalf("expected ValkyrieAce in leaderboard response, got %s", listW.Body.String())
	}

	// 5. Verify modernized /live HTML page
	liveReq := httptest.NewRequest(http.MethodGet, "/live", nil)
	liveW := httptest.NewRecorder()
	r.ServeHTTP(liveW, liveReq)
	if liveW.Code != http.StatusOK {
		t.Fatalf("expected 200 on /live, got %d", liveW.Code)
	}
	body := liveW.Body.String()
	if !bytes.Contains([]byte(body), []byte("VOID PROTOCOL")) {
		t.Fatalf("expected VOID PROTOCOL branding on /live")
	}
	if bytes.Contains([]byte(body), []byte("FEIRA DE")) {
		t.Fatalf("legacy science fair text should not appear on /live")
	}
}
