//
//  QuestionListView.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import SwiftUI

struct QuestionListView: View {
    var roomCode: String
    @StateObject private var viewModel: QuestionViewModel
    @AppStorage("username") private var username: String = ""
    @State private var answeringQuestionId: String? = nil
    @State private var answerText: String = ""

    init(roomCode: String, hideMyName: Bool) {
        self.roomCode = roomCode
        _viewModel = StateObject(wrappedValue: QuestionViewModel(roomCode: roomCode, hideMyName: hideMyName))
    }

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.questions.sorted(by: { $0.voteCount > $1.voteCount })) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.content)
                            .font(.headline)
                        Text("Sender: \(question.senderName)\(question.senderName == viewModel.adminId ? " (Admin)" : "")")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let answer = question.answer, !answer.isEmpty {
                            Text("Reply: \(answer) (Admin)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }

                        if question.isAnswered {
                            Text("Answered")
                                .font(.caption)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Button(action: {
                                viewModel.vote(for: question, username: username)
                            }) {
                                Label("\(question.voteCount)", systemImage: "hand.thumbsup")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            if username == viewModel.adminId {
                                Button(action: {
                                    viewModel.deleteQuestion(question)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }

                            if username == viewModel.adminId,
                               let topQuestion = viewModel.questions.sorted(by: { $0.voteCount > $1.voteCount }).first,
                               question.id == topQuestion.id {
                                Button(action: {
                                    if answeringQuestionId == question.id {
                                        answeringQuestionId = nil
                                        answerText = ""
                                    } else {
                                        answeringQuestionId = question.id
                                        answerText = question.answer ?? ""
                                    }
                                }) {
                                    Label("Reply", systemImage: "bubble.left.and.bubble.right")
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                            }
                        }

                        if answeringQuestionId == question.id && username == viewModel.adminId {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Your answer", text: $answerText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .submitLabel(.done)
                                    .onSubmit {
                                        saveAnswer(for: question)
                                    }
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        saveAnswer(for: question)
                                    }) {
                                        Label("Send", systemImage: "paperplane.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    Spacer()
                                }
                                .padding(.top, 15)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .listRowSeparator(.hidden)
                    Divider()
                        .padding(.vertical, 8)
                }
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        hideKeyboard()
                    }
            )

            HStack {
                TextField("Write a question", text: $viewModel.newQuestion)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    if !viewModel.newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.sendQuestion(username: username)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Room: \(roomCode)")
    }

    private func saveAnswer(for question: Question) {
        viewModel.answerTopQuestion(question: question, answer: answerText)
        answerText = ""
        answeringQuestionId = nil
    }
}

#Preview {
    QuestionListView(roomCode: "Oda3", hideMyName: false)
}
