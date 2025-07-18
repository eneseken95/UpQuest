//
//  Question.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import FirebaseFirestore

struct Question: Identifiable, Codable {
    @DocumentID var id: String?
    var content: String
    var voteCount: Int
    var isAnswered: Bool
    var senderName: String
    var answer: String?
}
