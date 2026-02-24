import Foundation

class FirebaseGrowthRepository: GrowthRepositoryProtocol {
    init() {}
    
    func fetchGrowthMetrics(userId: String, completion: @escaping (Result<GrowthMetrics, Error>) -> Void) {
        // Pseudo-implementation simulating a network request returning the hardcoded values.
        // In a real app, this would query a 'growth_metrics' or similar Firestore collection.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let mockMetrics = GrowthMetrics(
                monthlyActivity: [4, 7, 5, 8, 6, 12],
                monthlyLabels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
                growthTrajectory: [7.2, 7.8, 8.1, 8.7]
            )
            DispatchQueue.main.async {
                completion(.success(mockMetrics))
            }
        }
    }
}
