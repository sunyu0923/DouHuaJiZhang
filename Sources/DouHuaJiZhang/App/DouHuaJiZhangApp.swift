import SwiftUI
import ComposableArchitecture

@main
struct DouHuaJiZhangApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
