//
//  Question.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import FirebaseFirestore

struct Question: Identifiable, Codable, Equatable {
    var id: String?
    var content: String
    var voteCount: Int
    var isAnswered: Bool
    var senderName: String
    var answer: String?

    init(id: String? = nil,
         content: String,
         voteCount: Int = 0,
         isAnswered: Bool = false,
         senderName: String,
         answer: String? = nil) {
        self.id = id
        self.content = content
        self.voteCount = voteCount
        self.isAnswered = isAnswered
        self.senderName = senderName
        self.answer = answer
    }

    init?(dictionary: [String: Any], documentId: String) {
        guard let content = dictionary["content"] as? String,
              let voteCount = dictionary["voteCount"] as? Int,
              let isAnswered = dictionary["isAnswered"] as? Bool,
              let senderName = dictionary["senderName"] as? String else {
            return nil
        }
        id = documentId
        self.content = content
        self.voteCount = voteCount
        self.isAnswered = isAnswered
        self.senderName = senderName
        answer = dictionary["answer"] as? String
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "content": content,
            "voteCount": voteCount,
            "isAnswered": isAnswered,
            "senderName": senderName,
        ]
        if let answer = answer {
            dict["answer"] = answer
        }
        return dict
    }

    static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.id == rhs.id
    }
}
