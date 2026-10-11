import SwiftUI

@main
struct TEZVPNApp: App {
    @StateObject private var store = ShopStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
