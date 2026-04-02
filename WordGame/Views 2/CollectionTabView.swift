import SwiftUI

struct CollectionTabView: View {
    @State private var selectedTab = 0
    @State private var showInstructions = false
    @State private var showProfile = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TopNavBar(
                    onInstructions: { showInstructions = true },
                    onProfile: { showProfile = true }
                )

                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("My Won Words").tag(0)
                    Text("Community").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Tab content (not paged, so outer swipe works)
                Group {
                    if selectedTab == 0 {
                        WonWordsView()
                    } else {
                        CommunityView()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInstructions) {
            HowToPlayView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}
