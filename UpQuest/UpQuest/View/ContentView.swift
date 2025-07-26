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
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showLogin = true
    @State private var authChecked = false

    var body: some View {
        NavigationStack {
            if !authChecked {
                VStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.3)

                    Text("Checking session...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Background_Color"))
                .ignoresSafeArea()
                .onAppear {
                    Task {
                        await userViewModel.checkAuthAndFirestore()
                        authChecked = true
                    }
                }
            } else {
                if userViewModel.isUserLoggedIn && !username.isEmpty {
                    RoomEntryCreateView()
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
                                .foregroundStyle(.blue)
                                .fontWeight(.bold)
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
                                    .foregroundStyle(.blue)
                                    .fontWeight(.bold)
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
                                    .foregroundStyle(.blue)
                                    .fontWeight(.bold)
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
