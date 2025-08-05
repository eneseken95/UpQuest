//
//  QuestionViewModel.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import FirebaseFirestore

class QuestionViewModel: ObservableObject {
    @Published var questions: [QuestionModel] = []
    @Published var newQuestion: String = ""
    @Published var adminId: String = ""

    var hideMyName: Bool = false
    private var db = Firestore.firestore()
    private var roomCode: String
    private var listener: ListenerRegistration?

    init(roomCode: String, hideMyName: Bool = false) {
        self.roomCode = roomCode
        self.hideMyName = hideMyName
        fetchAdminId()
        fetchQuestions()
    }

    deinit {
        listener?.remove()
    }

    func fetchAdminId() {
        db.collection("rooms").document(roomCode).getDocument { document, _ in
            if let data = document?.data() {
                self.adminId = data["adminId"] as? String ?? ""
            }
        }
    }

    func fetchQuestions() {
        listener = db.collection("rooms")
            .document(roomCode)
            .collection("questions")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }

                self.questions = documents.compactMap { doc in
                    QuestionModel(dictionary: doc.data(), documentId: doc.documentID)
                }
            }
    }

    func sendQuestion(username: String) {
        let trimmedQuestion = newQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }

        let sender = hideMyName ? "Anonim" : username
        let question = QuestionModel(content: trimmedQuestion, senderName: sender)

        db.collection("rooms")
            .document(roomCode)
            .collection("questions")
            .addDocument(data: question.toDictionary()) { error in
                if let error = error {
                    print("Error adding question: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.newQuestion = ""
                    }
                }
            }
    }

    func vote(for question: QuestionModel, username: String) {
        guard let questionId = question.id else { return }
        let ref = db.collection("rooms")
            .document(roomCode)
            .collection("questions")
            .document(questionId)

        ref.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            var voters = data["voters"] as? [String] ?? []
            var voteCount = data["voteCount"] as? Int ?? 0

            if voters.contains(username) {
                voters.removeAll { $0 == username }
                voteCount = max(voteCount - 1, 0)
                print("User revoked vote.")
            } else {
                voters.append(username)
                voteCount += 1
                print("User voted.")
            }

            ref.updateData([
                "voteCount": voteCount,
                "voters": voters,
            ])
        }
    }

    func deleteQuestion(_ question: QuestionModel) {
        guard let questionId = question.id else { return }
        db.collection("rooms").document(roomCode).collection("questions").document(questionId).delete()
    }

    func answerTopQuestion(question: QuestionModel, answer: String) {
        guard let questionId = question.id else { return }

        db.collection("rooms")
            .document(roomCode)
            .collection("questions")
            .document(questionId)
            .updateData([
                "answer": answer,
                "isAnswered": true,
            ])
    }
}
