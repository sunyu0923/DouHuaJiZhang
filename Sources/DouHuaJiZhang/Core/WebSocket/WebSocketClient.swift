import Foundation
import ComposableArchitecture

/// WebSocket 消息类型
enum WSMessage: Codable, Equatable, Sendable {
    case syncOperation(SyncOperation)
    case heartbeat
    case connected
    case disconnected(String)
    
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "sync":
            let op = try container.decode(SyncOperation.self, forKey: .payload)
            self = .syncOperation(op)
        case "heartbeat":
            self = .heartbeat
        case "connected":
            self = .connected
        default:
            self = .disconnected("Unknown message type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .syncOperation(let op):
            try container.encode("sync", forKey: .type)
            try container.encode(op, forKey: .payload)
        case .heartbeat:
            try container.encode("heartbeat", forKey: .type)
        case .connected:
            try container.encode("connected", forKey: .type)
        case .disconnected(let reason):
            try container.encode("disconnected", forKey: .type)
            try container.encode(reason, forKey: .payload)
        }
    }
}

/// WebSocket 连接状态
enum WSConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
}

/// WebSocket 客户端
@DependencyClient
struct WebSocketClient: Sendable {
    var connect: @Sendable (_ ledgerId: UUID, _ token: String) async throws -> Void
    var disconnect: @Sendable () async throws -> Void
    var send: @Sendable (_ message: WSMessage) async throws -> Void
    var receive: @Sendable () async throws -> AsyncStream<WSMessage>
    var connectionState: @Sendable () async -> WSConnectionState = { .disconnected }
}

extension WebSocketClient: DependencyKey {
    static let liveValue: WebSocketClient = {
        let baseURL = "wss://api.douhuajizhang.com/ws/sync"
        
        actor WebSocketActor {
            private var task: URLSessionWebSocketTask?
            private var session: URLSession?
            private var state: WSConnectionState = .disconnected
            private var continuation: AsyncStream<WSMessage>.Continuation?
            
            func connect(ledgerId: UUID, token: String) async throws {
                state = .connecting
                
                guard var components = URLComponents(string: baseURL) else {
                    throw APIError.unknown("Invalid WebSocket URL")
                }
                components.queryItems = [
                    URLQueryItem(name: "ledger_id", value: ledgerId.uuidString),
                    URLQueryItem(name: "token", value: token),
                ]
                
                guard let url = components.url else {
                    throw APIError.unknown("Invalid WebSocket URL")
                }
                
                let session = URLSession(configuration: .default)
                self.session = session
                
                let task = session.webSocketTask(with: url)
                self.task = task
                task.resume()
                
                state = .connected
            }
            
            func disconnect() {
                task?.cancel(with: .goingAway, reason: nil)
                task = nil
                session?.invalidateAndCancel()
                session = nil
                state = .disconnected
                continuation?.finish()
                continuation = nil
            }
            
            func send(_ message: WSMessage) async throws {
                let data = try JSONEncoder().encode(message)
                guard let string = String(data: data, encoding: .utf8) else {
                    throw APIError.unknown("Failed to encode message")
                }
                try await task?.send(.string(string))
            }
            
            func receive() -> AsyncStream<WSMessage> {
                AsyncStream { continuation in
                    self.continuation = continuation
                    
                    Task { [weak self] in
                        guard let self else { return }
                        while let task = await self.getTask() {
                            do {
                                let message = try await task.receive()
                                switch message {
                                case .string(let text):
                                    if let data = text.data(using: .utf8),
                                       let wsMessage = try? JSONDecoder().decode(WSMessage.self, from: data) {
                                        continuation.yield(wsMessage)
                                    }
                                case .data(let data):
                                    if let wsMessage = try? JSONDecoder().decode(WSMessage.self, from: data) {
                                        continuation.yield(wsMessage)
                                    }
                                @unknown default:
                                    break
                                }
                            } catch {
                                continuation.yield(.disconnected(error.localizedDescription))
                                continuation.finish()
                                break
                            }
                        }
                    }
                }
            }
            
            func getTask() -> URLSessionWebSocketTask? { task }
            func getState() -> WSConnectionState { state }
        }
        
        let actor = WebSocketActor()
        
        return WebSocketClient(
            connect: { ledgerId, token in
                try await actor.connect(ledgerId: ledgerId, token: token)
            },
            disconnect: {
                await actor.disconnect()
            },
            send: { message in
                try await actor.send(message)
            },
            receive: {
                await actor.receive()
            },
            connectionState: {
                await actor.getState()
            }
        )
    }()
    
    static let testValue = WebSocketClient()
}

extension DependencyValues {
    var webSocketClient: WebSocketClient {
        get { self[WebSocketClient.self] }
        set { self[WebSocketClient.self] = newValue }
    }
}
