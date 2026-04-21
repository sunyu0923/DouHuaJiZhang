import ComposableArchitecture
import Foundation

/// 生理健康记录 Feature — 拉屎 + 月经
@Reducer
struct HealthRecordFeature {
    
    enum RecordType: String, Equatable, Sendable {
        case poop = "poop"
        case menstrual = "menstrual"
        
        var displayName: String {
            switch self {
            case .poop: return "拉屎记录"
            case .menstrual: return "月经记录"
            }
        }
    }
    
    enum StatsPeriod: String, Equatable, Sendable, CaseIterable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .day: return "日"
            case .week: return "周"
            case .month: return "月"
            case .year: return "年"
            }
        }
    }
    
    @ObservableState
    struct State: Equatable {
        var recordType: RecordType = .poop
        var selectedUserId: UUID?
        var familyMembers: [LedgerMember] = []
        var statsPeriod: StatsPeriod = .month
        
        // Poop records
        var poopRecords: [PoopRecord] = []
        var todayPoopCount: Int = 0
        var lastPoopTime: Date?
        
        // Menstrual records
        var menstrualRecords: [MenstrualRecord] = []
        var prediction: MenstrualPrediction?
        var currentMonth: Int = Calendar.current.component(.month, from: Date())
        var currentYear: Int = Calendar.current.component(.year, from: Date())
        
        var isLoading: Bool = false
        var errorMessage: String?
        var douhuaQuote: String = DouhuaQuoteManager.randomQuote(for: .poopRecord)
        
        @Presents var addPoopRecord: AddPoopRecordState?
        @Presents var addMenstrualRecord: AddMenstrualRecordState?
    }
    
    struct AddPoopRecordState: Equatable, Identifiable {
        let id = UUID()
        var date: Date = Date()
        var time: Date = Date()
        var note: String = ""
    }
    
    struct AddMenstrualRecordState: Equatable, Identifiable {
        let id = UUID()
        var startDate: Date = Date()
        var endDate: Date? = nil
        var note: String = ""
    }
    
    enum Action {
        case onAppear
        case switchRecordType(RecordType)
        case switchUser(UUID)
        case setStatsPeriod(StatsPeriod)
        
        // Poop
        case loadPoopRecords
        case poopRecordsLoaded([PoopRecord])
        case showAddPoopRecord
        case addPoopRecord(PresentationAction<AddPoopRecordAction>)
        case savePoopRecord(PoopRecord)
        case poopRecordSaved(PoopRecord)
        case deletePoopRecord(UUID)
        case poopRecordDeleted(UUID)
        
        // Menstrual
        case loadMenstrualRecords
        case menstrualRecordsLoaded([MenstrualRecord])
        case predictionLoaded(MenstrualPrediction)
        case showAddMenstrualRecord
        case addMenstrualRecord(PresentationAction<AddMenstrualRecordAction>)
        case saveMenstrualRecord(MenstrualRecord)
        case menstrualRecordSaved(MenstrualRecord)
        case deleteMenstrualRecord(UUID)
        case menstrualRecordDeleted(UUID)
        
        case loadFailed(String)
    }
    
    enum AddPoopRecordAction { case dismiss }
    enum AddMenstrualRecordAction { case dismiss }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadPoopRecords)
                
            case .switchRecordType(let type):
                state.recordType = type
                state.douhuaQuote = type == .poop
                    ? DouhuaQuoteManager.randomQuote(for: .poopRecord)
                    : DouhuaQuoteManager.randomQuote(for: .menstrualRecord)
                return type == .poop ? .send(.loadPoopRecords) : .send(.loadMenstrualRecords)
                
            case .switchUser(let userId):
                state.selectedUserId = userId
                return state.recordType == .poop ? .send(.loadPoopRecords) : .send(.loadMenstrualRecords)
                
            case .setStatsPeriod(let period):
                state.statsPeriod = period
                return .none
                
            // MARK: - Poop
                
            case .loadPoopRecords:
                state.isLoading = true
                let userId = state.selectedUserId ?? UUID()
                let month = state.currentMonth
                let year = state.currentYear
                return .run { send in
                    do {
                        let records = try await apiClient.fetchPoopRecords(userId, month, year)
                        await send(.poopRecordsLoaded(records))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .poopRecordsLoaded(let records):
                state.poopRecords = records
                state.isLoading = false
                let today = Calendar.current.startOfDay(for: Date())
                let todayRecords = records.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: today)
                }
                state.todayPoopCount = todayRecords.count
                state.lastPoopTime = todayRecords.sorted(by: { $0.time > $1.time }).first?.time
                return .none
                
            case .showAddPoopRecord:
                state.addPoopRecord = AddPoopRecordState()
                return .none
                
            case .savePoopRecord(let record):
                return .run { send in
                    let saved = try await apiClient.createPoopRecord(record)
                    await send(.poopRecordSaved(saved))
                }
                
            case .poopRecordSaved(let record):
                state.poopRecords.append(record)
                state.addPoopRecord = nil
                state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .poopRecordSuccess)
                return .send(.loadPoopRecords)
                
            case .deletePoopRecord(let id):
                return .run { send in
                    try await apiClient.deletePoopRecord(id)
                    await send(.poopRecordDeleted(id))
                }
                
            case .poopRecordDeleted(let id):
                state.poopRecords.removeAll { $0.id == id }
                return .none
                
            // MARK: - Menstrual
                
            case .loadMenstrualRecords:
                state.isLoading = true
                let userId = state.selectedUserId ?? UUID()
                return .run { send in
                    do {
                        let records = try await apiClient.fetchMenstrualRecords(userId)
                        await send(.menstrualRecordsLoaded(records))
                        let prediction = try await apiClient.fetchMenstrualPrediction(userId)
                        await send(.predictionLoaded(prediction))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .menstrualRecordsLoaded(let records):
                state.menstrualRecords = records
                state.isLoading = false
                return .none
                
            case .predictionLoaded(let prediction):
                state.prediction = prediction
                return .none
                
            case .showAddMenstrualRecord:
                state.addMenstrualRecord = AddMenstrualRecordState()
                return .none
                
            case .saveMenstrualRecord(let record):
                return .run { send in
                    let saved = try await apiClient.createMenstrualRecord(record)
                    await send(.menstrualRecordSaved(saved))
                }
                
            case .menstrualRecordSaved(let record):
                state.menstrualRecords.append(record)
                state.addMenstrualRecord = nil
                state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .menstrualRecordSuccess)
                return .send(.loadMenstrualRecords)
                
            case .deleteMenstrualRecord(let id):
                return .run { send in
                    try await apiClient.deleteMenstrualRecord(id)
                    await send(.menstrualRecordDeleted(id))
                }
                
            case .menstrualRecordDeleted(let id):
                state.menstrualRecords.removeAll { $0.id == id }
                return .none
                
            case .addPoopRecord, .addMenstrualRecord:
                return .none
                
            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
        .ifLet(\.$addPoopRecord, action: \.addPoopRecord) {
            EmptyReducer()
        }
        .ifLet(\.$addMenstrualRecord, action: \.addMenstrualRecord) {
            EmptyReducer()
        }
    }
}
