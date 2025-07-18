//
//  RoomCreateView.swift
//  UpQuest
//
//  Created by Enes Eken on 6.07.2025.
//

import SwiftUI

struct RoomCreateView: View {
    var roomCode: String
    var onRoomCreated: () -> Void

    @AppStorage("username") private var username: String = ""
    @StateObject private var roomViewModel = RoomViewModel()
    @State private var isCreating = false

    var body: some View {
        VStack {
            Text("Room Code: \(roomCode)")
                .font(.headline)
                .padding()

            Button("Create the Room") {
                isCreating = true
                roomViewModel.createRoom(roomCode: roomCode, adminId: username) { success in
                    isCreating = false
                    if success {
                        onRoomCreated()
                    }
                }
            }
            .disabled(isCreating)
        }
        .navigationTitle("Create Room")
    }
}
