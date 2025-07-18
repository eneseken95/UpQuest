//
//  ContentView.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import FirebaseAuth
import SwiftUI

struct ContentView: View {
    @AppStorage("username") private var username: String = ""
    @StateObject private var userViewModel = UserViewModel()
    @State private var showLogin = true
    @State private var authChecked = false

    var body: some View {
        NavigationStack {
            if !authChecked {
                ProgressView("Checking session...")
                    .onAppear {
                        Task {
                            await userViewModel.checkAuthAndFirestore()
                            authChecked = true
                        }
                    }
            } else {
                if userViewModel.isUserLoggedIn && !username.isEmpty {
                    RoomEntryView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Logout") {
                                    Task {
                                        do {
                                            try Auth.auth().signOut()
                                            await MainActor.run {
                                                username = ""
                                                userViewModel.isUserLoggedIn = false
                                                authChecked = false
                                            }
                                        } catch {
                                            print("Logout error: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }
                } else {
                    if showLogin {
                        LoginView()
                            .environmentObject(userViewModel)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Register") {
                                        showLogin = false
                                    }
                                }
                            }
                    } else {
                        RegisterView()
                            .environmentObject(userViewModel)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Login") {
                                        showLogin = true
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
