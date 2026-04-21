package handler

import (
	"log"
	"net/http"
	"time"

	"github.com/douhuajizhang/server/internal/middleware"
	"github.com/douhuajizhang/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // TODO: restrict in production
	},
}

// HandleWebSocket 处理 WebSocket 连接
func HandleWebSocket(c *gin.Context, hub *service.WSHub) {
	ledgerIDStr := c.Query("ledger_id")
	ledgerID, err := uuid.Parse(ledgerIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid ledger_id"})
		return
	}

	userID := middleware.GetUserID(c)

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &wsClient{
		hub:      hub,
		conn:     conn,
		userID:   userID,
		ledgerID: ledgerID,
		send:     make(chan []byte, 256),
	}

	hub.Register(newWSClientWrapper(client))

	go client.writePump()
	go client.readPump()
}

type wsClient struct {
	hub      *service.WSHub
	conn     *websocket.Conn
	userID   uuid.UUID
	ledgerID uuid.UUID
	send     chan []byte
}

func newWSClientWrapper(c *wsClient) *service.WSClient {
	// Note: In production, WSClient should be an interface or the hub
	// should work with a different abstraction. This is simplified.
	return nil // Placeholder - needs proper integration
}

func (c *wsClient) readPump() {
	defer func() {
		c.conn.Close()
	}()
	c.conn.SetReadLimit(65536)
	c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			break
		}
		c.hub.Broadcast(&service.WSMessage{
			LedgerID: c.ledgerID,
			Data:     message,
			SenderID: c.userID,
		})
	}
}

func (c *wsClient) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
