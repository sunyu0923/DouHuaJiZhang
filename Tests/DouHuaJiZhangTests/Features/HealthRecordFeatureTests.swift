import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class HealthRecordFeatureTests: XCTestCase {
    
    let userId = UUID()
    
    // MARK: - Record Type Switch
    
    func testSwitchRecordType_toPoop() async {
        let store = TestStore(
            initialState: {
                var state = HealthRecordFeature.State()
                state.recordType = .menstrual
                state.selectedUserId = self.userId
                return state
            }()
        ) {
            HealthRecordFeature()
        } withDependencies: {
            $0.apiClient.fetchPoopRecords = { _, _, _ in [] }
        }
        
        await store.send(.switchRecordType(.poop)) {
            $0.recordType = .poop
            // douhuaQuote updated
        }
        
        await store.receive(\.loadPoopRecords) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    func testSwitchRecordType_toMenstrual() async {
        let store = TestStore(
            initialState: {
                var state = HealthRecordFeature.State()
                state.recordType = .poop
                state.selectedUserId = self.userId
                return state
            }()
        ) {
            HealthRecordFeature()
        } withDependencies: {
            $0.apiClient.fetchMenstrualRecords = { _ in [] }
            $0.apiClient.fetchMenstrualPrediction = { _ in
                MenstrualPrediction(nextStartDate: Date(), nextEndDate: Date(), averageCycleLength: 28, averageDuration: 5)
            }
        }
        
        await store.send(.switchRecordType(.menstrual)) {
            $0.recordType = .menstrual
        }
        
        await store.receive(\.loadMenstrualRecords) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    // MARK: - Poop Records
    
    func testPoopRecordsLoaded() async {
        let today = Date()
        let record1 = PoopRecord(userId: userId, date: today, time: today, note: "")
        let record2 = PoopRecord(userId: userId, date: today, time: today, note: "正常")
        
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.poopRecordsLoaded([record1, record2])) {
            $0.poopRecords = [record1, record2]
            $0.isLoading = false
            $0.todayPoopCount = 2
        }
    }
    
    func testShowAddPoopRecord() async {
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.showAddPoopRecord) {
            $0.addPoopRecord = HealthRecordFeature.AddPoopRecordState()
        }
    }
    
    func testSavePoopRecord() async {
        let record = PoopRecord(userId: userId, note: "正常")
        
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        } withDependencies: {
            $0.apiClient.createPoopRecord = { _ in record }
            $0.apiClient.fetchPoopRecords = { _, _, _ in [record] }
        }
        
        await store.send(.savePoopRecord(record))
        
        await store.receive(\.poopRecordSaved) {
            $0.poopRecords = [record]
            $0.addPoopRecord = nil
        }
        
        // Triggers reload
        await store.receive(\.loadPoopRecords) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    func testDeletePoopRecord() async {
        let record = PoopRecord(userId: userId, note: "测试")
        
        let store = TestStore(
            initialState: {
                var state = HealthRecordFeature.State()
                state.poopRecords = [record]
                return state
            }()
        ) {
            HealthRecordFeature()
        } withDependencies: {
            $0.apiClient.deletePoopRecord = { _ in }
        }
        
        await store.send(.deletePoopRecord(record.id))
        
        await store.receive(\.poopRecordDeleted) {
            $0.poopRecords = []
        }
    }
    
    // MARK: - Menstrual Records
    
    func testMenstrualRecordsLoaded() async {
        let record = MenstrualRecord(userId: userId, startDate: Date(), cycleLength: 28)
        
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.menstrualRecordsLoaded([record])) {
            $0.menstrualRecords = [record]
            $0.isLoading = false
        }
    }
    
    func testPredictionLoaded() async {
        let prediction = MenstrualPrediction(
            nextStartDate: Date(),
            nextEndDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            averageCycleLength: 28,
            averageDuration: 5
        )
        
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.predictionLoaded(prediction)) {
            $0.prediction = prediction
        }
    }
    
    func testShowAddMenstrualRecord() async {
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.showAddMenstrualRecord) {
            $0.addMenstrualRecord = HealthRecordFeature.AddMenstrualRecordState()
        }
    }
    
    func testDeleteMenstrualRecord() async {
        let record = MenstrualRecord(userId: userId, startDate: Date(), cycleLength: 28)
        
        let store = TestStore(
            initialState: {
                var state = HealthRecordFeature.State()
                state.menstrualRecords = [record]
                return state
            }()
        ) {
            HealthRecordFeature()
        } withDependencies: {
            $0.apiClient.deleteMenstrualRecord = { _ in }
        }
        
        await store.send(.deleteMenstrualRecord(record.id))
        
        await store.receive(\.menstrualRecordDeleted) {
            $0.menstrualRecords = []
        }
    }
    
    // MARK: - Stats Period
    
    func testSetStatsPeriod() async {
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.setStatsPeriod(.week)) {
            $0.statsPeriod = .week
        }
    }
    
    // MARK: - RecordType enum
    
    func testRecordType_displayNames() {
        XCTAssertEqual(HealthRecordFeature.RecordType.poop.displayName, "拉屎记录")
        XCTAssertEqual(HealthRecordFeature.RecordType.menstrual.displayName, "月经记录")
    }
    
    func testStatsPeriod_allCases() {
        XCTAssertEqual(HealthRecordFeature.StatsPeriod.allCases.count, 4)
    }
    
    func testStatsPeriod_displayNames() {
        XCTAssertEqual(HealthRecordFeature.StatsPeriod.day.displayName, "日")
        XCTAssertEqual(HealthRecordFeature.StatsPeriod.week.displayName, "周")
        XCTAssertEqual(HealthRecordFeature.StatsPeriod.month.displayName, "月")
        XCTAssertEqual(HealthRecordFeature.StatsPeriod.year.displayName, "年")
    }
    
    // MARK: - Error
    
    func testLoadFailed() async {
        let store = TestStore(initialState: HealthRecordFeature.State()) {
            HealthRecordFeature()
        }
        
        await store.send(.loadFailed("服务器错误")) {
            $0.isLoading = false
            $0.errorMessage = "服务器错误"
        }
    }
}
