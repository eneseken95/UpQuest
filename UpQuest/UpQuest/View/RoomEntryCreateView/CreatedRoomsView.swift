//
//  CreatedRoomsView.swift
//  UpQuest
//
//  Created by Enes Eken on 25.07.2025.
//

import SwiftUI

struct CreatedRoomsView: View {
    @ObservedObject var roomViewModel: RoomViewModel
    var username: String
    var onRoomSelected: (String) -> Void
    var onRoomDeleted: (String) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Rooms You Create")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 5)

            if roomViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.3)
                    .padding(.top, 10)

            } else if roomViewModel.createdRooms.isEmpty {
                Text("You haven't created a room yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                    .padding(.top, 5)

            } else {
                ScrollView {
                    ForEach(roomViewModel.createdRooms, id: \.id) { room in
                        HStack {
                            Button(action: {
                                onRoomSelected(room.id)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(room.id)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)

                                    Text("Created at: \(dateFormatter.string(from: room.createdAt))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    let mockViewModel = RoomViewModel()

    mockViewModel.createdRooms = [
        RoomModel(id: "ABC123", adminId: "testuser", createdAt: Date()),
        RoomModel(id: "XYZ789", adminId: "testuser", createdAt: Date().addingTimeInterval(-3600)),
    ]

    return CreatedRoomsView(
        roomViewModel: mockViewModel,
        username: "testuser",
        onRoomSelected: { roomId in
            print("Selected room: \(roomId)")
        },
        onRoomDeleted: { roomId in
            print("Deleted room: \(roomId)")
        }
    )
}
