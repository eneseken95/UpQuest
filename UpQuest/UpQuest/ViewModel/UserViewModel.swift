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
    @AppStorage("username") private var username: String = ""

    @Published var inputUsername = ""
    @Published var email = ""
    @Published var password = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var isUserLoggedIn = false

    private let db = Firestore.firestore()

    func register() async {
        let usernameLower = inputUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !usernameLower.isEmpty, !emailTrimmed.isEmpty, !passwordTrimmed.isEmpty else {
            alertMessage = "Please fill all fields."
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

            username = usernameLower
            isUserLoggedIn = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }

        isLoading = false
    }

    func login() async {
        let usernameLower = inputUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !usernameLower.isEmpty, !passwordTrimmed.isEmpty else {
            alertMessage = "Please fill all fields."
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
            username = usernameLower
            isUserLoggedIn = true
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
            } else {
                try Auth.auth().signOut()
                isUserLoggedIn = false
                username = ""
            }
        } catch {
            print("Auth check error: \(error.localizedDescription)")
            isUserLoggedIn = false
            username = ""
        }
    }
}
