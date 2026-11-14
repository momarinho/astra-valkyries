package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"html"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

var db *gorm.DB

func getEnv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func getSecretKey() string {
	return getEnv("API_SECRET_KEY", "asteroids-secret-token-key-2026")
}

func initDatabase(dsn string) (*gorm.DB, error) {
	database, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	if err := database.AutoMigrate(&Player{}, &Score{}); err != nil {
		return nil, err
	}
	return database, nil
}

func setupRouter(webDir string) *gin.Engine {
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery(), CORSMiddleware())

	// API routes
	r.GET("/health", handleHealth)
	r.POST("/players", handleRegisterPlayer)
	r.POST("/scores", handleSubmitScore)
	r.GET("/scores", handleGetScores)
	r.GET("/live", handleLiveLeaderboard)
	r.GET("/ranking", handleLiveLeaderboard)

	// Optional static Flutter Web serving (useful for self-contained bundles)
	if webDir != "" {
		r.Static("/assets", webDir+"/assets")
		r.Static("/canvaskit", webDir+"/canvaskit")
		r.Static("/icons", webDir+"/icons")
		r.StaticFile("/favicon.png", webDir+"/favicon.png")
		r.StaticFile("/flutter.js", webDir+"/flutter.js")
		r.StaticFile("/flutter_bootstrap.js", webDir+"/flutter_bootstrap.js")
		r.StaticFile("/flutter_service_worker.js", webDir+"/flutter_service_worker.js")
		r.StaticFile("/main.dart.js", webDir+"/main.dart.js")
		r.StaticFile("/manifest.json", webDir+"/manifest.json")
		r.StaticFile("/version.json", webDir+"/version.json")
		r.StaticFile("/", webDir+"/index.html")
	}

	return r
}

func main() {
	dbPath := getEnv("DB_PATH", "asteroids.db")
	var err error
	db, err = initDatabase(dbPath)
	if err != nil {
		log.Fatalf("Failed to initialize database (%s): %v", dbPath, err)
	}

	if getEnv("GIN_MODE", "release") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	webDir := ""
	if _, err := os.Stat("../build/web/index.html"); err == nil {
		webDir = "../build/web"
	} else if _, err := os.Stat("build/web/index.html"); err == nil {
		webDir = "build/web"
	}

	r := setupRouter(webDir)

	port := getEnv("PORT", "8080")
	log.Printf("Void Protocol backend listening on :%s (db=%s)", port, dbPath)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}

func CORSMiddleware() gin.HandlerFunc {
	allowedOrigin := getEnv("ALLOWED_ORIGINS", "*")
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
		if allowedOrigin != "*" {
			c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		}
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, X-Signature")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

func handleHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "void-protocol-api",
	})
}

type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=2,max=20"`
}

func handleRegisterPlayer(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid callsign (must be 2-20 characters)"})
		return
	}

	player := Player{
		ID:       uuid.New().String(),
		Username: strings.TrimSpace(req.Username),
	}

	if len(player.Username) < 2 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid callsign (must be at least 2 non-space characters)"})
		return
	}

	if err := db.Create(&player).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create player profile"})
		return
	}

	c.JSON(http.StatusCreated, player)
}

type SubmitScoreRequest struct {
	PlayerID  string `json:"player_id" binding:"required"`
	Scientist string `json:"scientist"`
	Score     int    `json:"score"`
	Level     int    `json:"level"`
	Mode      string `json:"mode" binding:"required"`
	Signature string `json:"signature" binding:"required"`
}

func computeScoreSignature(playerID string, score, level int, mode, secret string) string {
	payload := fmt.Sprintf("%s:%d:%d:%s", playerID, score, level, mode)
	h := hmac.New(sha256.New, []byte(secret))
	h.Write([]byte(payload))
	return hex.EncodeToString(h.Sum(nil))
}

func handleSubmitScore(c *gin.Context) {
	var req SubmitScoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Score < 0 || req.Level < 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid score or level"})
		return
	}

	var player Player
	if err := db.First(&player, "id = ?", req.PlayerID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Player profile not found"})
		return
	}

	expectedSignature := computeScoreSignature(req.PlayerID, req.Score, req.Level, req.Mode, getSecretKey())
	if !hmac.Equal([]byte(req.Signature), []byte(expectedSignature)) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Score submission rejected: integrity signature mismatch (anti-cheat)"})
		return
	}

	scoreRecord := Score{
		PlayerID:  req.PlayerID,
		Scientist: strings.TrimSpace(req.Scientist),
		Score:     req.Score,
		Level:     req.Level,
		Mode:      strings.TrimSpace(req.Mode),
	}

	if err := db.Create(&scoreRecord).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save score record"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Score submitted successfully!",
		"score":   scoreRecord.Score,
	})
}

func handleGetScores(c *gin.Context) {
	mode := c.DefaultQuery("mode", "arcade")
	period := c.DefaultQuery("period", "all")
	limitStr := c.DefaultQuery("limit", "10")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 || limit > 100 {
		limit = 10
	}

	var scores []Score
	query := db.Preload("Player").Where("mode = ?", mode)
	if period == "today" {
		now := time.Now().UTC()
		startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
		query = query.Where("created_at >= ?", startOfDay)
	}

	if err := query.Order("score desc").Limit(limit).Find(&scores).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve highscores"})
		return
	}

	type LeaderboardEntry struct {
		Username  string `json:"username"`
		Scientist string `json:"scientist"`
		Score     int    `json:"score"`
		Level     int    `json:"level"`
		CreatedAt string `json:"created_at"`
	}

	results := make([]LeaderboardEntry, len(scores))
	for i, s := range scores {
		pilot := s.Scientist
		if pilot == "" {
			pilot = "Valkyrie"
		}
		results[i] = LeaderboardEntry{
			Username:  s.Player.Username,
			Scientist: pilot,
			Score:     s.Score,
			Level:     s.Level,
			CreatedAt: s.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	c.JSON(http.StatusOK, results)
}

func handleLiveLeaderboard(c *gin.Context) {
	var scores []Score
	db.Preload("Player").
		Where("mode = ?", "arcade").
		Order("score desc").
		Limit(15).
		Find(&scores)

	var sb strings.Builder
	sb.WriteString(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="5">
<title>Void Protocol // Live Global Leaderboard</title>
<style>
  body { background: #070b14; color: #f1f5f9; font-family: 'Courier New', monospace; margin: 0; padding: 24px; display: flex; flex-direction: column; align-items: center; }
  h1 { color: #00e5ff; letter-spacing: 3px; margin-bottom: 4px; text-shadow: 0 0 12px #00e5ff88; text-align: center; }
  p.subtitle { color: #94a3b8; margin-top: 0; font-size: 13px; letter-spacing: 1.5px; text-align: center; }
  table { width: 92%; max-width: 820px; border-collapse: collapse; margin-top: 20px; background: rgba(255,255,255,0.03); border: 1px solid rgba(0,229,255,0.3); border-radius: 12px; overflow: hidden; }
  th { background: rgba(0,229,255,0.14); color: #00e5ff; padding: 14px; text-align: left; font-size: 13px; letter-spacing: 1.4px; }
  td { padding: 12px 14px; border-bottom: 1px solid rgba(255,255,255,0.06); font-size: 14px; }
  tr:nth-child(1) td { color: #ffd700; font-weight: bold; font-size: 16px; }
  tr:nth-child(2) td { color: #e2e8f0; font-weight: bold; }
  tr:nth-child(3) td { color: #fdba74; font-weight: bold; }
  .badge { background: rgba(0,229,255,0.15); color: #67e8f9; padding: 3px 8px; border-radius: 6px; font-size: 12px; border: 1px solid rgba(0,229,255,0.35); }
  .refresh-hint { margin-top: 16px; color: #64748b; font-size: 12px; }
</style>
</head>
<body>
  <h1>VOID PROTOCOL</h1>
  <p class="subtitle">LIVE GLOBAL LEADERBOARD • TOP SORTIE PILOTS</p>
  <table>
    <thead>
      <tr><th>RANK</th><th>CALLSIGN</th><th>PILOT</th><th style="text-align:right">SCORE</th></tr>
    </thead>
    <tbody>`)

	if len(scores) == 0 {
		sb.WriteString(`<tr><td colspan="4" style="text-align:center; padding: 24px; color: #64748b;">No cloud sorties recorded yet.</td></tr>`)
	} else {
		for i, s := range scores {
			pilot := s.Scientist
			if pilot == "" {
				pilot = "Vanguard"
			}
			sb.WriteString(fmt.Sprintf(
				`<tr><td>#%d</td><td><strong>%s</strong></td><td><span class="badge">%s</span></td><td style="text-align:right; font-weight:bold;">%d</td></tr>`,
				i+1,
				html.EscapeString(s.Player.Username),
				html.EscapeString(pilot),
				s.Score,
			))
		}
	}

	sb.WriteString(`</tbody></table>
  <p class="refresh-hint">Auto-refreshes every 5s • Void Protocol Telemetry API</p>
</body>
</html>`)

	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(sb.String()))
}
