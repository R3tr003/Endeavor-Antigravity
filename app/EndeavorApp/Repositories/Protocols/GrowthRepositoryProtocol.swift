import Foundation

struct GrowthMetrics {
    var monthlyActivity: [Double]
    var monthlyLabels: [String]
    var growthTrajectory: [Double]
}

protocol GrowthRepositoryProtocol {
    /// Fetches growth metrics for the user's dashboard.
    func fetchGrowthMetrics(userId: String, completion: @escaping (Result<GrowthMetrics, Error>) -> Void)
}
