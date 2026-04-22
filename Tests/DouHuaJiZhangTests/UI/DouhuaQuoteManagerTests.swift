import XCTest
@testable import DouHuaJiZhang

final class DouhuaQuoteManagerTests: XCTestCase {
    
    // MARK: - All Scenes Have Quotes
    
    func testAllScenes_returnNonEmptyQuotes() {
        let allScenes: [DouhuaQuoteManager.Scene] = [
            .welcome, .login, .loginFailed, .loginSuccess,
            .register, .registerSuccess,
            .ledgerHome, .recording, .recordSuccess, .deleteConfirm, .editSuccess,
            .ledgerSwitch, .ledgerCreate, .statistics,
            .savingsSetup, .savingsProgress, .savingsExceeded, .savingsWarning,
            .financeMarket, .stockUp, .stockDown, .investmentAdd, .investmentMaturity,
            .poopRecord, .poopRecordSuccess, .menstrualRecord, .menstrualPrediction, .menstrualRecordSuccess,
            .profile, .streakCelebration, .badgeUnlocked,
            .familyGroup, .memberJoined, .settings, .reminder,
            .evening, .morning,
        ]
        
        for scene in allScenes {
            let quotes = DouhuaQuoteManager.quotes(for: scene)
            XCTAssertFalse(quotes.isEmpty, "Scene \(scene.rawValue) should have at least one quote")
            
            // Also test randomQuote doesn't crash
            let random = DouhuaQuoteManager.randomQuote(for: scene)
            XCTAssertFalse(random.isEmpty, "randomQuote for \(scene.rawValue) should not be empty")
        }
    }
    
    func testRandomQuote_returnsQuoteFromPool() {
        let scene = DouhuaQuoteManager.Scene.welcome
        let allQuotes = DouhuaQuoteManager.quotes(for: scene)
        
        // Run multiple times to verify it always returns from the pool
        for _ in 0..<10 {
            let quote = DouhuaQuoteManager.randomQuote(for: scene)
            XCTAssertTrue(allQuotes.contains(quote), "Random quote should be from the scene's quote pool")
        }
    }
    
    func testGreetingQuote_returnsNonEmpty() {
        let greeting = DouhuaQuoteManager.greetingQuote()
        XCTAssertFalse(greeting.isEmpty)
    }
    
    // MARK: - Scene raw values
    
    func testScene_rawValues() {
        XCTAssertEqual(DouhuaQuoteManager.Scene.welcome.rawValue, "welcome")
        XCTAssertEqual(DouhuaQuoteManager.Scene.poopRecord.rawValue, "poopRecord")
        XCTAssertEqual(DouhuaQuoteManager.Scene.menstrualRecord.rawValue, "menstrualRecord")
    }
    
    // MARK: - Quote content verification
    
    func testWelcomeQuotes_containSignatureElements() {
        let quotes = DouhuaQuoteManager.quotes(for: .welcome)
        XCTAssertTrue(quotes.count >= 3)
        
        // At least one mention of 豆花
        let hasMascot = quotes.contains { $0.contains("豆花") }
        XCTAssertTrue(hasMascot, "Welcome quotes should mention 豆花")
    }
    
    func testSavingsQuotes_areEncouraging() {
        let exceeded = DouhuaQuoteManager.quotes(for: .savingsExceeded)
        XCTAssertFalse(exceeded.isEmpty)
        
        let warning = DouhuaQuoteManager.quotes(for: .savingsWarning)
        XCTAssertFalse(warning.isEmpty)
    }
}
