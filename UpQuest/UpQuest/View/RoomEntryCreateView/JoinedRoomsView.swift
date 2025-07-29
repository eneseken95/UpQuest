//
//  JoinedRoomsView.swift
//  UpQuest
//
//  Created by Enes Eken on 25.07.2025.
//

import SwiftUI

struct JoinedRoomsView: View {
    @ObservedObject var roomViewModel: RoomViewModel
    var onRoomSelected: (String) -> Void
    var onRoomDeleted: (String) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Rooms You Enter")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 5)

            if roomViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.3)
                    .padding(.top, 10)

            } else if roomViewModel.joinedRooms.isEmpty {
                Text("You have not joined the room yet.")
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                    .padding(.top, 10)

            } else {
                ScrollView {
                    ForEach(roomViewModel.joinedRooms, id: \.id) { room in
                        HStack {
                            Button(action: {
                                onRoomSelected(room.id)
                            }) {
                                Text(room.id)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .frame(height: 25)

                            Spacer()

                            Button(action: {
                                onRoomDeleted(room.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(white: 0.9), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 200)
                .padding(.top, 10)
            }
        }
        .frame(width: 300, height: 270)
        .background(Color("Keyboard_Background_Color"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.9), lineWidth: 1)
        )
        .padding()
    }
}
