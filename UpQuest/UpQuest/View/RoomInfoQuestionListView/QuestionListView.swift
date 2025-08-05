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
    @State private var editingAnswerQuestionId: String? = nil
    @FocusState private var isAnswerFieldFocused: Bool

    init(roomCode: String, hideMyName: Bool) {
        self.roomCode = roomCode
        _viewModel = StateObject(wrappedValue: QuestionViewModel(roomCode: roomCode, hideMyName: hideMyName))
    }

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.questions.sorted(by: { $0.voteCount > $1.voteCount })) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.white)
                                .font(.title)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(question.senderName)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .fontWeight(.bold)

                                Text(question.senderName == viewModel.adminId ? "Admin" : "Member")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()

                            if question.isAnswered {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .font(.title3)
                            }
                        }
                        .padding(.top, 10)

                        Divider()
                            .frame(height: 0.5)
                            .background(Color.white.opacity(0.5))
                            .padding(.vertical, 2)

                        Text(question.content)
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        if let answer = question.answer, !answer.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(answer)
                                        .font(.subheadline)
                                        .foregroundStyle(.orange)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 8)
                                .overlay(
                                    Rectangle()
                                        .frame(width: 3)
                                        .foregroundColor(.green),
                                    alignment: .leading
                                )

                                Spacer()
                            }
                            .padding(.bottom, 10)
                        }

                        HStack {
                            Button(action: {
                                viewModel.vote(for: question, username: username)
                            }) {
                                HStack {
                                    Image(systemName: "hand.thumbsup")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)

                                    Text("\(question.voteCount)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .fontWeight(.bold)
                                }
                            }
                            .buttonStyle(.bordered)
                            .cornerRadius(20)

                            if username == viewModel.adminId,
                               let topQuestion = viewModel.questions.sorted(by: { $0.voteCount > $1.voteCount }).first,
                               question.id == topQuestion.id,
                               !question.isAnswered {
                                Button(action: {
                                    if answeringQuestionId == question.id {
                                        answeringQuestionId = nil
                                        answerText = ""
                                        isAnswerFieldFocused = false
                                    } else {
                                        answeringQuestionId = question.id
                                        answerText = question.answer ?? ""
                                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                                            isAnswerFieldFocused = true
                                        }
                                    }
                                }) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.bordered)
                                .cornerRadius(20)
                            }

                            if (username == viewModel.adminId) || (question.senderName == username) {
                                Button(action: {
                                    viewModel.deleteQuestion(question)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.bordered)
                                .cornerRadius(20)
                            }

                            if username == viewModel.adminId,
                               question.answer != nil {
                                Button(action: {
                                    editingAnswerQuestionId = question.id
                                    answerText = question.answer ?? ""
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isAnswerFieldFocused = true
                                    }
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.bordered)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    .listRowSeparator(.hidden)
                    .padding()
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(white: 0.9), lineWidth: 1)
                            )
                            .padding(.vertical, 10)
                    )
                    .listRowInsets(EdgeInsets())
                }
            }
            .padding(.top, -15)
            .scrollContentBackground(.hidden)
            .background(Color("Background_Color"))
            .onChange(of: viewModel.questions.sorted(by: { $0.voteCount > $1.voteCount }).first) { newTopQuestion in
                if answeringQuestionId != newTopQuestion?.id {
                    answeringQuestionId = nil
                }
            }
            .onChange(of: viewModel.questions) { updatedQuestions in
                if let editingId = editingAnswerQuestionId,
                   !updatedQuestions.contains(where: { $0.id == editingId }) {
                    editingAnswerQuestionId = nil
                    answerText = ""
                    isAnswerFieldFocused = false
                }
            }

            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        hideKeyboard()
                    }
            )

            if answeringQuestionId == nil && editingAnswerQuestionId == nil {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 0.2)
                        .edgesIgnoringSafeArea(.horizontal)
                        .padding(.top, -8)

                    HStack {
                        HStack(alignment: .bottom) {
                            HStack(spacing: 8) {
                                TextField("", text: $viewModel.newQuestion, axis: .vertical)
                                    .placeholder(when: viewModel.newQuestion.isEmpty) {
                                        Text("Write a question")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                viewModel.newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                    ? Color.white.opacity(0.5)
                                                    : Color.white,
                                                lineWidth: 1
                                            )
                                    )
                                    .foregroundColor(.white)
                                    .lineLimit(...4)
                            }
                            .background(Color("Keyboard_Background_Color"))
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 55)
                        .background(Color("Keyboard_Background_Color"))
                        .ignoresSafeArea()

                        Button(action: {
                            if !viewModel.newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.sendQuestion(username: username)
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(
                                    viewModel.newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.white.opacity(0.5)
                                        : Color.white
                                )
                        }
                        .padding(8)
                        .disabled(viewModel.newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.leading, 17)
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
                    .padding(.top, 3)
                }
            } else if let question = viewModel.questions.first(where: { $0.id == answeringQuestionId }),
                      username == viewModel.adminId && !question.isAnswered {
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 0.2)
                        .edgesIgnoringSafeArea(.horizontal)
                        .padding(.top, -8)

                    ZStack(alignment: .topTrailing) {
                        HStack(alignment: .top, spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(question.senderName)")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                Text(question.content)
                                    .font(.subheadline)
                                    .foregroundColor(.cyan)
                                    .truncationMode(.tail)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, 8)
                            .overlay(
                                Rectangle()
                                    .frame(width: 3)
                                    .foregroundColor(.white),
                                alignment: .leading
                            )

                            Spacer()
                        }
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal, 14)

                        Button(action: {
                            isAnswerFieldFocused = false
                            answeringQuestionId = nil
                            answerText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.headline)
                        }
                        .padding(.top, 6)
                        .padding(.trailing, 20)
                    }
                    .padding(.vertical, 3)

                    HStack {
                        HStack(alignment: .bottom) {
                            HStack(spacing: 8) {
                                TextField("", text: $answerText, axis: .vertical)
                                    .focused($isAnswerFieldFocused)
                                    .placeholder(when: answerText.isEmpty) {
                                        Text("Your answer")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                    ? Color.white.opacity(0.5)
                                                    : Color.white,
                                                lineWidth: 1
                                            )
                                    )
                                    .foregroundColor(.white)
                                    .lineLimit(...4)
                            }
                            .background(Color("Keyboard_Background_Color"))
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 55)
                        .background(Color("Keyboard_Background_Color"))
                        .ignoresSafeArea()

                        Button(action: {
                            saveAnswer(for: question)
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(
                                    answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.white.opacity(0.5)
                                        : Color.white
                                )
                        }
                        .padding(8)
                        .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 17)
                    .padding(.vertical, 13)
                }
            } else if let question = viewModel.questions.first(where: { $0.id == editingAnswerQuestionId }),
                      username == viewModel.adminId,
                      question.answer != nil {
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 0.2)
                        .edgesIgnoringSafeArea(.horizontal)
                        .padding(.top, -8)

                    ZStack(alignment: .topTrailing) {
                        HStack(alignment: .top, spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(question.answer ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .truncationMode(.tail)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, 8)
                            .overlay(
                                Rectangle()
                                    .frame(width: 3)
                                    .foregroundColor(.green),
                                alignment: .leading
                            )

                            Spacer()
                        }
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal, 14)

                        Button(action: {
                            isAnswerFieldFocused = false
                            editingAnswerQuestionId = nil
                            answerText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.headline)
                        }
                        .padding(.top, 4)
                        .padding(.trailing, 18)
                    }
                    .padding(.vertical, 3)

                    HStack {
                        HStack(alignment: .bottom) {
                            HStack(spacing: 8) {
                                TextField("", text: $answerText, axis: .vertical)
                                    .focused($isAnswerFieldFocused)
                                    .placeholder(when: answerText.isEmpty) {
                                        Text("Edit Your Answer")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                    ? Color.white.opacity(0.5)
                                                    : Color.white,
                                                lineWidth: 1
                                            )
                                    )
                                    .foregroundColor(.white)
                                    .lineLimit(...4)
                            }
                            .background(Color("Keyboard_Background_Color"))
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 55)
                        .background(Color("Keyboard_Background_Color"))
                        .ignoresSafeArea()

                        Button(action: {
                            saveAnswer(for: question)
                            isAnswerFieldFocused = false
                            editingAnswerQuestionId = nil
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(
                                    answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.white.opacity(0.5)
                                        : Color.white
                                )
                        }
                        .padding(8)
                        .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 17)
                    .padding(.vertical, 13)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("Keyboard_Background_Color"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color("Keyboard_Background_Color"))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(roomCode)
                    .font(.title3)
                    .foregroundStyle(Color.white)
                    .fontWeight(.bold)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: RoomInformationView(roomCode: roomCode)) {
                    Image(systemName: "info.circle")
                        .font(.headline)
                        .foregroundColor(Color.purple)
                }
            }
        }
    }

    private func saveAnswer(for question: QuestionModel) {
        viewModel.answerTopQuestion(question: question, answer: answerText)
        answerText = ""
        answeringQuestionId = nil
        editingAnswerQuestionId = nil
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    QuestionListView(roomCode: "Oda90", hideMyName: false)
}
