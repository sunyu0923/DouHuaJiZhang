import Foundation
import ComposableArchitecture
import Security

/// Keychain 安全存储客户端
@DependencyClient
struct KeychainClient: Sendable {
    var saveToken: @Sendable (_ token: String) async throws -> Void
    var getToken: @Sendable () async throws -> String?
    var saveRefreshToken: @Sendable (_ token: String) async throws -> Void
    var getRefreshToken: @Sendable () async throws -> String?
    var saveUserId: @Sendable (_ userId: String) async throws -> Void
    var getUserId: @Sendable () async throws -> String?
    var deleteAll: @Sendable () async throws -> Void
}

extension KeychainClient: DependencyKey {
    static let liveValue: KeychainClient = {
        let service = "com.douhuajizhang.keychain"
        
        func save(key: String, value: String) throws {
            let data = Data(value.utf8)
            
            // 先删除旧的
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            // 添加新的
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            ]
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw KeychainError.saveFailed(status)
            }
        }
        
        func load(key: String) throws -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            switch status {
            case errSecSuccess:
                guard let data = result as? Data else { return nil }
                return String(data: data, encoding: .utf8)
            case errSecItemNotFound:
                return nil
            default:
                throw KeychainError.loadFailed(status)
            }
        }
        
        func deleteAll() throws {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.deleteFailed(status)
            }
        }
        
        return KeychainClient(
            saveToken: { token in try save(key: "access_token", value: token) },
            getToken: { try load(key: "access_token") },
            saveRefreshToken: { token in try save(key: "refresh_token", value: token) },
            getRefreshToken: { try load(key: "refresh_token") },
            saveUserId: { userId in try save(key: "user_id", value: userId) },
            getUserId: { try load(key: "user_id") },
            deleteAll: { try deleteAll() }
        )
    }()
    
    static let testValue = KeychainClient()
}

extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}

enum KeychainError: Error, Equatable {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
}
