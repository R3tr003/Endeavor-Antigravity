import Foundation

struct MessageMetrics {
    var monthlyActivity: [Double]
    var monthlyLabels: [String]
    var growthTrajectory: [Double]
}

protocol MessagesRepositoryProtocol {
    /// Fetches mock message metrics for the user's dashboard.
    func fetchMessages(userId: String, completion: @escaping (Result<MessageMetrics, Error>) -> Void)
}
