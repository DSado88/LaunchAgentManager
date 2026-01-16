import Foundation
import Combine

@MainActor
public class StatusPoller: ObservableObject {
    @Published public var interval: TimeInterval = 5.0 {
        didSet {
            if isRunning {
                stop()
                start()
            }
        }
    }

    @Published public private(set) var isRunning = false

    private var timer: Timer?
    private weak var service: LaunchAgentService?

    public init(service: LaunchAgentService) {
        self.service = service
    }

    public func start() {
        guard !isRunning else { return }

        isRunning = true
        scheduleTimer()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    public func setInterval(_ seconds: TimeInterval) {
        interval = seconds
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.service?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
