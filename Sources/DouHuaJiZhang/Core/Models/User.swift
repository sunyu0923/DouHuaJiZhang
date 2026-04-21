import Foundation

/// 用户模型
struct User: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var phone: String
    var nickname: String
    var avatarURL: URL?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        phone: String,
        nickname: String,
        avatarURL: URL? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.phone = phone
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}
