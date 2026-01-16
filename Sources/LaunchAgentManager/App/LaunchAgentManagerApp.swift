import SwiftUI

@main
struct LaunchAgentManagerApp: App {
    @StateObject private var service = LaunchAgentService()
    @StateObject private var poller: StatusPoller

    init() {
        let service = LaunchAgentService()
        _service = StateObject(wrappedValue: service)
        _poller = StateObject(wrappedValue: StatusPoller(service: service))
    }

    var body: some Scene {
        MenuBarExtra("LaunchAgent Manager", systemImage: "gearshape.2") {
            MenuBarView(service: service, poller: poller)
        }
        .menuBarExtraStyle(.window)
    }
}
