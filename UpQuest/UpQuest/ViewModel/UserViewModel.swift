//
//  UserViewModel.swift
//  UpQuest
//
//  Created by Enes Eken on 14.07.2025.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    @AppStorage("username") var username: String = ""
    @AppStorage("createdAt") var createdAtStorage: Double?
    @AppStorage("email") var emailStorage: String?

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var isUserLoggedIn = false
    @Published var createdAt: Date? = nil

    private let db = Firestore.firestore()

    func register(username: String, email: String, password: String) async {
        let usernameLower = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !usernameLower.isEmpty, !emailTrimmed.isEmpty, !passwordTrimmed.isEmpty else {
            alertMessage = "Please fill all fields."
            showAlert = true
            return
        }

        guard usernameLower.count <= 15 else {
            alertMessage = "Username must be at most 15 characters."
            showAlert = true
            return
        }

        isLoading = true

        do {
            let usernameDoc = try await db.collection("users").document(usernameLower).getDocument()
            if usernameDoc.exists {
                alertMessage = "Username already taken."
                showAlert = true
                isLoading = false
                return
            }

            let emailQuery = try await db.collection("users")
                .whereField("email", isEqualTo: emailTrimmed)
                .getDocuments()

            if !emailQuery.documents.isEmpty {
                alertMessage = "Email is already registered."
                showAlert = true
                isLoading = false
                return
            }

            let result = try await Auth.auth().createUser(withEmail: emailTrimmed, password: passwordTrimmed)

            try await db.collection("users").document(usernameLower).setData([
                "username": usernameLower,
                "email": emailTrimmed,
                "uid": result.user.uid,
                "createdAt": Timestamp(date: Date()),
            ])

            self.username = usernameLower
            emailStorage = emailTrimmed
            isUserLoggedIn = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }

        isLoading = false
    }

    func login(username: String, password: String) async {
        let usernameLower = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !usernameLower.isEmpty, !passwordTrimmed.isEmpty else {
            alertMessage = "Please fill all fields."
            showAlert = true
            return
        }

        guard usernameLower.count <= 15 else {
            alertMessage = "Username must be at most 15 characters."
            showAlert = true
            return
        }

        isLoading = true

        do {
            let userDoc = try await db.collection("users").document(usernameLower).getDocument()
            guard let data = userDoc.data(), let email = data["email"] as? String else {
                alertMessage = "Username not found."
                showAlert = true
                isLoading = false
                return
            }

            _ = try await Auth.auth().signIn(withEmail: email, password: passwordTrimmed)
            self.username = usernameLower
            isUserLoggedIn = true
            await checkAuthAndFirestore()

        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }

        isLoading = false
    }

    func checkAuthAndFirestore() async {
        guard let user = Auth.auth().currentUser else {
            isUserLoggedIn = false
            username = ""
            createdAt = nil
            createdAtStorage = nil
            emailStorage = ""
            return
        }

        do {
            let snapshot = try await db.collection("users")
                .whereField("uid", isEqualTo: user.uid)
                .getDocuments()

            if let doc = snapshot.documents.first,
               let fetchedUsername = doc.data()["username"] as? String {
                username = fetchedUsername
                isUserLoggedIn = true

                if let fetchedEmail = doc.data()["email"] as? String {
                    emailStorage = fetchedEmail
                }

                if let timestamp = doc.data()["createdAt"] as? Timestamp {
                    let date = timestamp.dateValue()
                    createdAt = date
                    createdAtStorage = date.timeIntervalSince1970
                }

            } else {
                try Auth.auth().signOut()
                isUserLoggedIn = false
                username = ""
                createdAt = nil
                createdAtStorage = nil
                emailStorage = ""
            }
        } catch {
            print("Auth check error: \(error.localizedDescription)")
            isUserLoggedIn = false
            username = ""
            createdAt = nil
            createdAtStorage = nil
            emailStorage = ""
        }
    }
}
