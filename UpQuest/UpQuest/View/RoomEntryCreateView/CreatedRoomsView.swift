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

            if roomViewModel.createdRooms.isEmpty {
                Text("You haven't created a room yet.")
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                    .padding(.top, 10)
            } else {
                ScrollView {
                    ForEach(roomViewModel.createdRooms, id: \.self) { room in
                        HStack {
                            Button(action: {
                                onRoomSelected(room)
                            }) {
                                Text(room)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            Button(action: {
                                onRoomDeleted(room)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 200)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}
