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
    @AppStorage("username") var usernameStorage: String = ""
    @AppStorage("createdAt") var createdAtStorage: Double?
    @AppStorage("email") var emailStorage: String?

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var isUserLoggedIn = false
    @Published var currentUser: User? = nil

    private let db = Firestore.firestore()

    var username: String {
        usernameStorage
    }

    var createdAt: Date? {
        guard let ts = createdAtStorage else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

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

            let newUser = User(username: usernameLower, email: emailTrimmed, uid: result.user.uid, createdAt: Date())

            try await db.collection("users").document(usernameLower).setData(newUser.toDictionary())

            currentUser = newUser
            usernameStorage = usernameLower
            emailStorage = emailTrimmed
            createdAtStorage = newUser.createdAt.timeIntervalSince1970
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

            if let userModel = User(dictionary: data) {
                currentUser = userModel
                usernameStorage = userModel.username
                emailStorage = userModel.email
                createdAtStorage = userModel.createdAt.timeIntervalSince1970
                isUserLoggedIn = true
            }

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
            currentUser = nil
            usernameStorage = ""
            emailStorage = ""
            createdAtStorage = nil
            return
        }

        do {
            let snapshot = try await db.collection("users")
                .whereField("uid", isEqualTo: user.uid)
                .getDocuments()

            if let doc = snapshot.documents.first,
               let userModel = User(dictionary: doc.data()) {
                currentUser = userModel
                usernameStorage = userModel.username
                emailStorage = userModel.email
                createdAtStorage = userModel.createdAt.timeIntervalSince1970
                isUserLoggedIn = true
            } else {
                try Auth.auth().signOut()
                isUserLoggedIn = false
                currentUser = nil
                usernameStorage = ""
                emailStorage = ""
                createdAtStorage = nil
            }
        } catch {
            print("Auth check error: \(error.localizedDescription)")
            isUserLoggedIn = false
            currentUser = nil
            usernameStorage = ""
            emailStorage = ""
            createdAtStorage = nil
        }
    }
}
