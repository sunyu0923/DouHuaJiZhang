import Foundation
import ComposableArchitecture

/// API 错误类型
enum APIError: Error, Equatable, Sendable, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validationError(String)
    case serverError(Int)
    case networkError(String)
    case decodingError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "登录已过期，请重新登录"
        case .forbidden: return "没有访问权限"
        case .notFound: return "资源不存在"
        case .conflict: return "数据冲突，请刷新后重试"
        case .validationError(let msg): return msg
        case .serverError(let code): return "服务器错误(\(code))"
        case .networkError(let msg): return "网络错误: \(msg)"
        case .decodingError(let msg): return "数据解析错误: \(msg)"
        case .unknown(let msg): return msg
        }
    }
}

/// API 响应包装
struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    let code: Int
    let message: String
    let data: T?
}

/// 分页响应
struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    
    var hasNextPage: Bool {
        page * pageSize < total
    }
}

/// 登录请求
struct LoginRequest: Codable, Sendable {
    let phone: String
    let password: String?
    let verificationCode: String?
}

/// 注册请求
struct RegisterRequest: Codable, Sendable {
    let phone: String
    let password: String
    let verificationCode: String
}

/// 认证响应
struct AuthResponse: Codable, Sendable {
    let token: String
    let refreshToken: String
    let user: User
}

/// 创建账本请求
struct CreateLedgerRequest: Codable, Sendable {
    let name: String
    let type: LedgerType
    let currency: String
}

/// 创建交易请求
struct CreateTransactionRequest: Codable, Sendable {
    let operationId: UUID
    let amount: Decimal
    let type: TransactionType
    let category: TransactionCategory
    let note: String
    let date: Date
}

/// 统计数据
struct StatisticsData: Codable, Equatable, Sendable {
    let totalExpense: Decimal
    let totalIncome: Decimal
    let balance: Decimal
    let categoryBreakdown: [CategoryAmount]
    let dailyTrend: [DailyAmount]
}

struct CategoryAmount: Codable, Equatable, Sendable, Identifiable {
    var id: String { category.rawValue }
    let category: TransactionCategory
    let amount: Decimal
    let percentage: Double
}

struct DailyAmount: Codable, Equatable, Sendable, Identifiable {
    var id: String { date }
    let date: String      // "2026-04-21"
    let expense: Decimal
    let income: Decimal
}

/// 日历数据
struct CalendarDayData: Codable, Equatable, Sendable, Identifiable {
    var id: String { date }
    let date: String
    let expense: Decimal
    let income: Decimal
}

// MARK: - APIClient

@DependencyClient
struct APIClient: Sendable {
    // Auth
    var login: @Sendable (_ request: LoginRequest) async throws -> AuthResponse
    var register: @Sendable (_ request: RegisterRequest) async throws -> AuthResponse
    var sendVerificationCode: @Sendable (_ phone: String) async throws -> Void
    var loginWithWechat: @Sendable (_ code: String) async throws -> AuthResponse
    var refreshToken: @Sendable (_ refreshToken: String) async throws -> AuthResponse
    var logout: @Sendable () async throws -> Void
    
    // User
    var fetchProfile: @Sendable () async throws -> User
    var updateProfile: @Sendable (_ user: User) async throws -> User
    var fetchBadges: @Sendable () async throws -> [Badge]
    
    // Ledger
    var fetchLedgers: @Sendable () async throws -> [Ledger]
    var createLedger: @Sendable (_ request: CreateLedgerRequest) async throws -> Ledger
    var updateLedger: @Sendable (_ ledger: Ledger) async throws -> Ledger
    var deleteLedger: @Sendable (_ id: UUID) async throws -> Void
    
    // Transaction
    var fetchTransactions: @Sendable (_ ledgerId: UUID, _ page: Int, _ pageSize: Int) async throws -> PaginatedResponse<Transaction>
    var createTransaction: @Sendable (_ ledgerId: UUID, _ request: CreateTransactionRequest) async throws -> Transaction
    var updateTransaction: @Sendable (_ transaction: Transaction) async throws -> Transaction
    var deleteTransaction: @Sendable (_ id: UUID) async throws -> Void
    
    // Statistics
    var fetchStatistics: @Sendable (_ ledgerId: UUID, _ month: Int, _ year: Int) async throws -> StatisticsData
    var fetchCalendar: @Sendable (_ ledgerId: UUID, _ month: Int, _ year: Int) async throws -> [CalendarDayData]
    
    // Family Group
    var fetchFamilyGroup: @Sendable (_ ledgerId: UUID) async throws -> Ledger
    var inviteMember: @Sendable (_ ledgerId: UUID, _ phone: String) async throws -> Void
    var removeMember: @Sendable (_ ledgerId: UUID, _ userId: UUID) async throws -> Void
    var updateMemberRole: @Sendable (_ ledgerId: UUID, _ userId: UUID, _ role: MemberRole) async throws -> Void
    
    // Savings
    var fetchSavingsPlans: @Sendable (_ year: Int) async throws -> [SavingsPlan]
    var createSavingsPlan: @Sendable (_ plan: SavingsPlan) async throws -> SavingsPlan
    var updateSavingsPlan: @Sendable (_ plan: SavingsPlan) async throws -> SavingsPlan
    var fetchSavingsProgress: @Sendable (_ planId: UUID) async throws -> SavingsProgress
    
    // Investment
    var fetchInvestments: @Sendable () async throws -> [Investment]
    var createInvestment: @Sendable (_ investment: Investment) async throws -> Investment
    var updateInvestment: @Sendable (_ investment: Investment) async throws -> Investment
    var deleteInvestment: @Sendable (_ id: UUID) async throws -> Void
    var fetchMarketQuotes: @Sendable (_ category: MarketCategory?) async throws -> [MarketQuote]
    
    // Health Records
    var fetchPoopRecords: @Sendable (_ userId: UUID, _ month: Int, _ year: Int) async throws -> [PoopRecord]
    var createPoopRecord: @Sendable (_ record: PoopRecord) async throws -> PoopRecord
    var deletePoopRecord: @Sendable (_ id: UUID) async throws -> Void
    var fetchMenstrualRecords: @Sendable (_ userId: UUID) async throws -> [MenstrualRecord]
    var createMenstrualRecord: @Sendable (_ record: MenstrualRecord) async throws -> MenstrualRecord
    var updateMenstrualRecord: @Sendable (_ record: MenstrualRecord) async throws -> MenstrualRecord
    var deleteMenstrualRecord: @Sendable (_ id: UUID) async throws -> Void
    var fetchMenstrualPrediction: @Sendable (_ userId: UUID) async throws -> MenstrualPrediction
    
    // Backup
    var backupData: @Sendable () async throws -> URL
    var restoreData: @Sendable (_ backupURL: URL) async throws -> Void
}

// MARK: - Dependency Registration

extension APIClient: DependencyKey {
    static let liveValue: APIClient = {
        let baseURL = URL(string: "https://api.douhuajizhang.com")!
        let session = URLSession.shared
        let decoder: JSONDecoder = {
            let d = JSONDecoder()
            d.dateDecodingStrategy = .iso8601
            d.keyDecodingStrategy = .convertFromSnakeCase
            return d
        }()
        let encoder: JSONEncoder = {
            let e = JSONEncoder()
            e.dateEncodingStrategy = .iso8601
            e.keyEncodingStrategy = .convertToSnakeCase
            return e
        }()
        
        @Dependency(\.keychainClient) var keychain
        let keychainClient = keychain
        
        func makeRequest(_ path: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> URLRequest {
            var request = URLRequest(url: baseURL.appendingPathComponent(path))
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = try? await keychainClient.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if let body {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            }
            
            return request
        }
        
        func perform<T: Codable & Sendable>(_ request: URLRequest) async throws -> T {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
                guard let result = apiResponse.data else {
                    throw APIError.unknown(apiResponse.message)
                }
                return result
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 409:
                throw APIError.conflict
            case 422:
                let apiResponse = try? decoder.decode(APIResponse<String>.self, from: data)
                throw APIError.validationError(apiResponse?.message ?? "验证错误")
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        }
        
        return APIClient(
            login: { request in
                let req = try await makeRequest("/api/auth/login", method: "POST", body: request)
                return try await perform(req)
            },
            register: { request in
                let req = try await makeRequest("/api/auth/register", method: "POST", body: request)
                return try await perform(req)
            },
            sendVerificationCode: { phone in
                let req = try await makeRequest("/api/auth/send-code", method: "POST", body: ["phone": phone])
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            loginWithWechat: { code in
                let req = try await makeRequest("/api/auth/wechat", method: "POST", body: ["code": code])
                return try await perform(req)
            },
            refreshToken: { refreshToken in
                let req = try await makeRequest("/api/auth/refresh", method: "POST", body: ["refresh_token": refreshToken])
                return try await perform(req)
            },
            logout: {
                let req = try await makeRequest("/api/auth/logout", method: "POST")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchProfile: {
                let req = try await makeRequest("/api/user/profile")
                return try await perform(req)
            },
            updateProfile: { user in
                let req = try await makeRequest("/api/user/profile", method: "PUT", body: user)
                return try await perform(req)
            },
            fetchBadges: {
                let req = try await makeRequest("/api/user/badges")
                return try await perform(req)
            },
            fetchLedgers: {
                let req = try await makeRequest("/api/ledgers")
                return try await perform(req)
            },
            createLedger: { request in
                let req = try await makeRequest("/api/ledgers", method: "POST", body: request)
                return try await perform(req)
            },
            updateLedger: { ledger in
                let req = try await makeRequest("/api/ledgers/\(ledger.id)", method: "PUT", body: ledger)
                return try await perform(req)
            },
            deleteLedger: { id in
                let req = try await makeRequest("/api/ledgers/\(id)", method: "DELETE")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchTransactions: { ledgerId, page, pageSize in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/transactions?page=\(page)&page_size=\(pageSize)")
                return try await perform(req)
            },
            createTransaction: { ledgerId, request in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/transactions", method: "POST", body: request)
                return try await perform(req)
            },
            updateTransaction: { transaction in
                let req = try await makeRequest("/api/ledgers/\(transaction.ledgerId)/transactions/\(transaction.id)", method: "PUT", body: transaction)
                return try await perform(req)
            },
            deleteTransaction: { id in
                let req = try await makeRequest("/api/transactions/\(id)", method: "DELETE")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchStatistics: { ledgerId, month, year in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/statistics?month=\(month)&year=\(year)")
                return try await perform(req)
            },
            fetchCalendar: { ledgerId, month, year in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/calendar?month=\(month)&year=\(year)")
                return try await perform(req)
            },
            fetchFamilyGroup: { ledgerId in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/family")
                return try await perform(req)
            },
            inviteMember: { ledgerId, phone in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/invite", method: "POST", body: ["phone": phone])
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            removeMember: { ledgerId, userId in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/members/\(userId)", method: "DELETE")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            updateMemberRole: { ledgerId, userId, role in
                let req = try await makeRequest("/api/ledgers/\(ledgerId)/members/\(userId)/role", method: "PUT", body: ["role": role.rawValue])
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchSavingsPlans: { year in
                let req = try await makeRequest("/api/savings-plans?year=\(year)")
                return try await perform(req)
            },
            createSavingsPlan: { plan in
                let req = try await makeRequest("/api/savings-plans", method: "POST", body: plan)
                return try await perform(req)
            },
            updateSavingsPlan: { plan in
                let req = try await makeRequest("/api/savings-plans/\(plan.id)", method: "PUT", body: plan)
                return try await perform(req)
            },
            fetchSavingsProgress: { planId in
                let req = try await makeRequest("/api/savings-plans/\(planId)/progress")
                return try await perform(req)
            },
            fetchInvestments: {
                let req = try await makeRequest("/api/investments")
                return try await perform(req)
            },
            createInvestment: { investment in
                let req = try await makeRequest("/api/investments", method: "POST", body: investment)
                return try await perform(req)
            },
            updateInvestment: { investment in
                let req = try await makeRequest("/api/investments/\(investment.id)", method: "PUT", body: investment)
                return try await perform(req)
            },
            deleteInvestment: { id in
                let req = try await makeRequest("/api/investments/\(id)", method: "DELETE")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchMarketQuotes: { category in
                var path = "/api/market/quotes"
                if let category { path += "?category=\(category.rawValue)" }
                let req = try await makeRequest(path)
                return try await perform(req)
            },
            fetchPoopRecords: { userId, month, year in
                let req = try await makeRequest("/api/health/poop?user_id=\(userId)&month=\(month)&year=\(year)")
                return try await perform(req)
            },
            createPoopRecord: { record in
                let req = try await makeRequest("/api/health/poop", method: "POST", body: record)
                return try await perform(req)
            },
            deletePoopRecord: { id in
                let req = try await makeRequest("/api/health/poop/\(id)", method: "DELETE")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchMenstrualRecords: { userId in
                let req = try await makeRequest("/api/health/menstrual?user_id=\(userId)")
                return try await perform(req)
            },
            createMenstrualRecord: { record in
                let req = try await makeRequest("/api/health/menstrual", method: "POST", body: record)
                return try await perform(req)
            },
            updateMenstrualRecord: { record in
                let req = try await makeRequest("/api/health/menstrual/\(record.id)", method: "PUT", body: record)
                return try await perform(req)
            },
            deleteMenstrualRecord: { id in
                let req = try await makeRequest("/api/health/menstrual/\(id)", method: "DELETE")
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            },
            fetchMenstrualPrediction: { userId in
                let req = try await makeRequest("/api/health/menstrual/prediction?user_id=\(userId)")
                return try await perform(req)
            },
            backupData: {
                let req = try await makeRequest("/api/backup", method: "POST")
                let (data, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
                let result = try JSONDecoder().decode(APIResponse<String>.self, from: data)
                guard let urlString = result.data, let url = URL(string: urlString) else {
                    throw APIError.unknown("Invalid backup URL")
                }
                return url
            },
            restoreData: { backupURL in
                let req = try await makeRequest("/api/restore", method: "POST", body: ["backup_url": backupURL.absoluteString])
                let (_, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.serverError(0)
                }
            }
        )
    }()
    
    static let testValue = APIClient()
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: - Helper for type-erased Encodable

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init(_ wrapped: any Encodable) {
        _encode = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
