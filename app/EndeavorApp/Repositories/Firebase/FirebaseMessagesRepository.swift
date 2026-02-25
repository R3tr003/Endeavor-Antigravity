import Foundation

class FirebaseMessagesRepository: MessagesRepositoryProtocol {
    init() {}
    
    func fetchMessages(userId: String, completion: @escaping (Result<MessageMetrics, Error>) -> Void) {
        // Pseudo-implementation simulating a network request returning the hardcoded values.
        // In a real app, this would query a 'messages' or similar Firestore collection.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let mockMetrics = MessageMetrics(
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
