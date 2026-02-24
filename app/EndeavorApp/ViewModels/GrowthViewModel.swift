import Foundation
import Combine

class GrowthViewModel: ObservableObject {
    @Published var metrics: GrowthMetrics?
    @Published var isLoading = false
    @Published var appError: AppError?
    
    private let repository: GrowthRepositoryProtocol
    
    init(repository: GrowthRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchMetrics(userId: String) {
        guard !isLoading else { return }
        isLoading = true
        appError = nil
        
        repository.fetchGrowthMetrics(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    self?.metrics = data
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }
}
