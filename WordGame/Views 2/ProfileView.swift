import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var pawPointsStore: PawPointsStore
    @EnvironmentObject var syncStatusStore: SyncStatusStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAuthPrompt = false

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
                    Spacer()

                    // Avatar
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Theme.accent)

                    if authStore.isAuthenticated {
                        Text(username)
                            .font(.title2.bold())

                        if let email = authStore.currentEmail {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Paw points
                        HStack(spacing: 4) {
                            Text("\u{1F43E}")
                            Text("\(pawPointsStore.balance)")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accent.opacity(0.1))
                        .clipShape(Capsule())

                        // Sync status
                        HStack(spacing: 6) {
                            Image(systemName: syncStatusStore.state.icon)
                            Text(syncStatusStore.state.label)
                                .lineLimit(1)
                        }
                        .font(.caption)
                        .foregroundStyle(syncStatusStore.state.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(syncStatusStore.state.color.opacity(0.12))
                        .clipShape(Capsule())
                    } else {
                        Text("Not logged in")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        if authStore.isAuthenticated {
                            Button {
                                authStore.signOut()
                            } label: {
                                Text("Log Out")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.12))
                                    .foregroundColor(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        } else {
                            Button {
                                showAuthPrompt = true
                            } label: {
                                Text("Log In or Sign Up")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.accent)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .sheet(isPresented: $showAuthPrompt) {
                AuthView(isPresented: $showAuthPrompt)
            }
        }
    }
}
