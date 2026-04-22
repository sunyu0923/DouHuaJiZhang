import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class SettingsFeatureTests: XCTestCase {
    
    // MARK: - Load Profile
    
    func testLoadProfile_success() async {
        let user = User(phone: "13800138000", nickname: "豆花")
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchProfile = { user }
        }
        
        await store.send(.loadProfile) {
            $0.isLoading = true
        }
        
        await store.receive(\.profileLoaded) {
            $0.user = user
            $0.isLoading = false
        }
    }
    
    func testOnAppear_triggersLoadProfile() async {
        let user = User(phone: "13800138000", nickname: "豆花")
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchProfile = { user }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\.loadProfile) {
            $0.isLoading = true
        }
        
        await store.receive(\.profileLoaded) {
            $0.user = user
            $0.isLoading = false
        }
    }
    
    // MARK: - Badges
    
    func testShowBadges() async {
        let badges = [
            Badge(type: .firstTransaction, name: "初次记账", isUnlocked: true, unlockedAt: Date()),
            Badge(type: .streak7Days, name: "连续7天", isUnlocked: false),
        ]
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchBadges = { badges }
        }
        
        await store.send(.showBadges) {
            $0.badges = SettingsFeature.BadgesState()
        }
        
        await store.receive(\.badgesLoaded) {
            $0.badges?.badges = badges
        }
    }
    
    // MARK: - Settings Toggles (via binding)
    
    func testInitialState_defaults() {
        let state = SettingsFeature.State()
        
        XCTAssertNil(state.user)
        XCTAssertEqual(state.consecutiveDays, 0)
        XCTAssertEqual(state.totalDays, 0)
        XCTAssertEqual(state.totalTransactions, 0)
        XCTAssertEqual(state.totalBalance, 0)
        XCTAssertTrue(state.isReminderEnabled)
        XCTAssertFalse(state.isAmountHidden)
        XCTAssertFalse(state.isAppLockEnabled)
    }
    
    func testInitialState_withUser() {
        let user = User(phone: "13800138000", nickname: "豆花")
        let state = SettingsFeature.State(user: user)
        
        XCTAssertEqual(state.user, user)
    }
    
    // MARK: - Logout
    
    func testLogout_action() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        // Logout just returns .none (handled by parent AppFeature)
        await store.send(.logout)
    }
    
    // MARK: - Cache
    
    func testClearCache() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        await store.send(.clearCache)
        
        await store.receive(\.cacheCleared)
    }
}
