//
//  Room.swift
//  UpQuest
//
//  Created by Enes Eken on 26.07.2025.
//

import FirebaseFirestore

struct Room: Identifiable, Codable {
    var id: String
    var adminId: String
    var createdAt: Date

    init(id: String, adminId: String, createdAt: Date) {
        self.id = id
        self.adminId = adminId
        self.createdAt = createdAt
    }

    init?(document: [String: Any], documentId: String) {
        guard let adminId = document["adminId"] as? String,
              let timestamp = document["createdAt"] as? Timestamp else {
            return nil
        }

        id = documentId
        self.adminId = adminId
        createdAt = timestamp.dateValue()
    }

    var toDictionary: [String: Any] {
        return [
            "adminId": adminId,
            "createdAt": Timestamp(date: createdAt),
        ]
    }
}
