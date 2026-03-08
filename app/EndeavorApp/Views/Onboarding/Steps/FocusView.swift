import SwiftUI

struct FocusView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        EmptyView()
    }
}

struct FocusView_Previews: PreviewProvider {
    static var previews: some View {
        FocusView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}
