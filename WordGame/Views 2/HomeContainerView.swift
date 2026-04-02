import SwiftUI

/// Root swipeable container: Page 0 = Home (StartView), Page 1 = Won Words & Community.
struct HomeContainerView: View {
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                StartView()
                    .tag(0)
                CollectionTabView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
