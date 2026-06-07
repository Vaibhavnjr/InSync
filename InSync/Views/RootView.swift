import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            Color.insyncBackground.ignoresSafeArea()
            DrawingView()

            Text(Constants.appName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "#2B1F1B"))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 4)
                .ignoresSafeArea(.container, edges: .top)
                .allowsHitTesting(false)
        }
        .foregroundStyle(Color.insyncInk)
    }
}
