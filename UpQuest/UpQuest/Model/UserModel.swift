//
//  UserModel.swift
//  UpQuest
//
//  Created by Enes Eken on 26.07.2025.
//

import FirebaseFirestore

struct UserModel: Identifiable, Codable {
    var id: String { username }
    let username: String
    let email: String
    let uid: String
    let createdAt: Date

    init(username: String, email: String, uid: String, createdAt: Date) {
        self.username = username
        self.email = email
        self.uid = uid
        self.createdAt = createdAt
    }

    init?(dictionary: [String: Any]) {
        guard
            let username = dictionary["username"] as? String,
            let email = dictionary["email"] as? String,
            let uid = dictionary["uid"] as? String,
            let timestamp = dictionary["createdAt"] as? Timestamp
        else { return nil }

        self.username = username
        self.email = email
        self.uid = uid
        createdAt = timestamp.dateValue()
    }

    func toDictionary() -> [String: Any] {
        return [
            "username": username,
            "email": email,
            "uid": uid,
            "createdAt": Timestamp(date: createdAt),
        ]
    }
}
