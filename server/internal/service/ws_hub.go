package service

import (
	"log"
	"sync"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

// WSHub WebSocket 连接管理
type WSHub struct {
	clients    map[*WSClient]bool
	ledgers    map[uuid.UUID]map[*WSClient]bool
	broadcast  chan *WSMessage
	register   chan *WSClient
	unregister chan *WSClient
	rdb        *redis.Client
	mu         sync.RWMutex
}

// WSClient 单个客户端连接
type WSClient struct {
	hub      *WSHub
	Conn     *websocket.Conn
	userID   uuid.UUID
	ledgerID uuid.UUID
	send     chan []byte
}

// NewWSClient 创建新的 WebSocket 客户端
func NewWSClient(hub *WSHub, conn *websocket.Conn, userID, ledgerID uuid.UUID) *WSClient {
	return &WSClient{
		hub:      hub,
		Conn:     conn,
		userID:   userID,
		ledgerID: ledgerID,
		send:     make(chan []byte, 256),
	}
}

// Send 返回发送通道
func (c *WSClient) Send() chan []byte {
	return c.send
}

// UserID 返回用户ID
func (c *WSClient) UserID() uuid.UUID {
	return c.userID
}

// LedgerID 返回账本ID
func (c *WSClient) LedgerID() uuid.UUID {
	return c.ledgerID
}

// WSMessage WebSocket 消息
type WSMessage struct {
	LedgerID uuid.UUID
	Data     []byte
	SenderID uuid.UUID
}

func NewWSHub(rdb *redis.Client) *WSHub {
	return &WSHub{
		clients:    make(map[*WSClient]bool),
		ledgers:    make(map[uuid.UUID]map[*WSClient]bool),
		broadcast:  make(chan *WSMessage, 256),
		register:   make(chan *WSClient),
		unregister: make(chan *WSClient),
		rdb:        rdb,
	}
}

func (h *WSHub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			if h.ledgers[client.ledgerID] == nil {
				h.ledgers[client.ledgerID] = make(map[*WSClient]bool)
			}
			h.ledgers[client.ledgerID][client] = true
			h.mu.Unlock()
			log.Printf("Client connected: user=%s ledger=%s", client.userID, client.ledgerID)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				if h.ledgers[client.ledgerID] != nil {
					delete(h.ledgers[client.ledgerID], client)
				}
				close(client.send)
			}
			h.mu.Unlock()
			log.Printf("Client disconnected: user=%s", client.userID)

		case message := <-h.broadcast:
			h.mu.Lock()
			if clients, ok := h.ledgers[message.LedgerID]; ok {
				for client := range clients {
					if client.userID == message.SenderID {
						continue
					}
					select {
					case client.send <- message.Data:
					default:
						close(client.send)
						delete(h.clients, client)
						delete(clients, client)
					}
				}
			}
			h.mu.Unlock()
		}
	}
}

func (h *WSHub) Register(client *WSClient) {
	h.register <- client
}

func (h *WSHub) Unregister(client *WSClient) {
	h.unregister <- client
}

func (h *WSHub) Broadcast(msg *WSMessage) {
	h.broadcast <- msg
}
