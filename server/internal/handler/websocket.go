package handler

import (
	"log"
	"net/http"
	"time"

	"github.com/douhuajizhang/server/internal/middleware"
	"github.com/douhuajizhang/server/internal/model"
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
func HandleWebSocket(c *gin.Context, hub *service.WSHub, ledgerSvc *service.LedgerService) {
	ledgerIDStr := c.Query("ledger_id")
	ledgerID, err := uuid.Parse(ledgerIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid ledger_id"})
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	if err := ledgerSvc.IsMember(c.Request.Context(), ledgerID, userID); err != nil {
		status := http.StatusInternalServerError
		if err == service.ErrForbidden {
			status = http.StatusForbidden
		} else {
			log.Printf("WebSocket ledger membership check failed: %v", err)
		}
		c.JSON(status, model.Error(status, "没有权限"))
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := service.NewWSClient(hub, conn, userID, ledgerID)
	hub.Register(client)

	go writePump(client)
	go readPump(client, hub)
}

func readPump(client *service.WSClient, hub *service.WSHub) {
	defer func() {
		hub.Unregister(client)
		client.Conn.Close()
	}()
	client.Conn.SetReadLimit(65536)
	client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	client.Conn.SetPongHandler(func(string) error {
		client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := client.Conn.ReadMessage()
		if err != nil {
			break
		}
		hub.Broadcast(&service.WSMessage{
			LedgerID: client.LedgerID(),
			Data:     message,
			SenderID: client.UserID(),
		})
	}
}

func writePump(client *service.WSClient) {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		client.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-client.Send():
			client.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				client.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := client.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			client.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := client.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
