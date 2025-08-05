//
//  RoomQuestionInfoViewModel.swift
//  UpQuest
//
//  Created by Enes Eken on 30.07.2025.
//

import FirebaseFirestore

class RoomQuestionInfoViewModel: ObservableObject {
    @Published var adminId: String = ""
    @Published var createdAt: Date = Date()
    @Published var questionSenders: [String] = []

    private let db = Firestore.firestore()
    private let roomCode: String

    init(roomCode: String) {
        self.roomCode = roomCode
        fetchRoomInfo()
        fetchQuestionSenders()
    }

    private func fetchRoomInfo() {
        db.collection("rooms").document(roomCode).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching room info:", error?.localizedDescription ?? "Unknown")
                return
            }

            self.adminId = data["adminId"] as? String ?? "Unknown"

            if let timestamp = data["createdAt"] as? Timestamp {
                self.createdAt = timestamp.dateValue()
            }
        }
    }

    private func fetchQuestionSenders() {
        db.collection("rooms").document(roomCode).collection("questions").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else {
                print("Error fetching questions:", error?.localizedDescription ?? "Unknown")
                return
            }

            let sendersSet = Set(docs.compactMap { $0.data()["senderName"] as? String })
            DispatchQueue.main.async {
                self.questionSenders = Array(sendersSet).sorted()
            }
        }
    }
}
