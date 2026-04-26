import SwiftUI
import ComposableArchitecture

/// App root view used by the host target.
struct DouHuaJiZhangRootView: View {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some View {
        AppView(store: store)
    }
}
