import SwiftUI

struct ShowOffMenuView: View {
    let wonWord: WonWord
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var communityStore: CommunityStore
    @Environment(\.dismiss) private var dismiss

    @State private var isPublishing = false
    @State private var published = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    private var username: String {
        if let email = authStore.currentEmail {
            return email.components(separatedBy: "@").first ?? "Player"
        }
        return "Player"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    ShowOffCardView(username: username, wonWord: wonWord)
                        .padding(.top, 20)

                    VStack(spacing: 12) {
                        // Share via text / social
                        Button {
                            let card = ShowOffCardView(username: username, wonWord: wonWord)
                            shareImage = card.renderImage()
                            showShareSheet = true
                        } label: {
                            Label("Share via Message", systemImage: "message.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accent)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Publish to community
                        Button {
                            Task { await publishToCommunity() }
                        } label: {
                            HStack {
                                if isPublishing {
                                    ProgressView().tint(Theme.accent)
                                }
                                Image(systemName: published ? "checkmark.circle.fill" : "globe")
                                Text(published ? "Published!" : "Publish to Community")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(published ? Theme.correct.opacity(0.15) : Theme.tileEmpty)
                            .foregroundColor(published ? Theme.correct : Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isPublishing || published)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .navigationTitle("Show Off")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [
                        "\(username) just solved a word on Paw-dle! 🐾\nThe word was \(wonWord.word.uppercased()) in \(wonWord.triesDisplay) tries!",
                        image
                    ] as [Any])
                }
            }
        }
    }

    private func publishToCommunity() async {
        guard let userId = authStore.currentUserId,
              let token = authStore.accessToken else { return }
        isPublishing = true
        let success = await communityStore.publish(
            userId: userId,
            username: username,
            wonWord: wonWord,
            accessToken: token
        )
        isPublishing = false
        if success { published = true }
    }
}

// MARK: - UIKit Share Sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
