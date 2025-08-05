//
//  RoomInformationView.swift
//  UpQuest
//
//  Created by Enes Eken on 30.07.2025.
//

import SwiftUI

struct RoomInformationView: View {
    let roomCode: String
    @StateObject private var viewModel: RoomQuestionInfoViewModel

    init(roomCode: String) {
        self.roomCode = roomCode
        _viewModel = StateObject(wrappedValue: RoomQuestionInfoViewModel(roomCode: roomCode))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(roomCode)
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(Color.gray.opacity(0.3))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            HStack(spacing: 10) {
                Text("Admin:")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(viewModel.adminId)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Text("Created At:")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(viewModel.createdAt, style: .date)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .center, spacing: 8) {
                Text("Question Senders")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 5)

                if viewModel.questionSenders.isEmpty {
                    Text("No questions yet.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fontWeight(.bold)
                        .padding(.top, 5)

                } else {
                    ScrollView {
                        VStack(alignment: .center, spacing: 20) {
                            ForEach(viewModel.questionSenders.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }, id: \.self) { sender in
                                Text("\(sender)")
                                    .font(.headline)
                                    .frame(width: 200, height: 20)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.03))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.top, 6)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 200)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .padding(.horizontal)
        .padding()
        .background(Color("Background_Color"))
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("Keyboard_Background_Color"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Room Information")
                    .font(.title3)
                    .foregroundStyle(Color.white)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    RoomInformationView(roomCode: "Oda3")
}
