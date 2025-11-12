import Foundation
import Network

final class ConnectivityService: ObservableObject {
    @Published private(set) var isOffline: Bool = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateStatus(isOffline: path.status != .satisfied)
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func updateStatus(isOffline: Bool) {
        DispatchQueue.main.async {
            self.isOffline = isOffline
        }
    }
}
