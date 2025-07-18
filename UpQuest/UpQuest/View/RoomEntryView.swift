//
//  RoomEntryView.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import SwiftUI

struct RoomEntryView: View {
    @State private var roomCode: String = ""
    @State private var hideMyName: Bool = false
    @State private var showRoomCreateAlert = false
    @State private var path: [String] = []
    @StateObject private var roomViewModel = RoomViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                TextField("Room Code", text: $roomCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Toggle(isOn: $hideMyName) {
                    Text("Hide my name (Anonymous Mode)")
                }
                .padding()

                Button("Login") {
                    roomViewModel.checkRoomExists(roomCode: roomCode) { exists in
                        if exists {
                            path.append("room")
                        } else {
                            showRoomCreateAlert = true
                        }
                    }
                }
                .disabled(roomCode.isEmpty)
            }
            .alert(isPresented: $showRoomCreateAlert) {
                Alert(
                    title: Text("Room Not Found"),
                    message: Text("This room does not exist. Would you like to create it?"),
                    primaryButton: .default(Text("Create")) {
                        path.append("create")
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationTitle("Room Entrance")
            .navigationDestination(for: String.self) { value in
                switch value {
                case "room":
                    if !roomCode.isEmpty {
                        QuestionListView(roomCode: roomCode, hideMyName: hideMyName)
                    } else {
                        Text("Error: Room code is empty")
                    }
                case "create":
                    RoomCreateView(roomCode: roomCode, onRoomCreated: {
                        if !roomCode.isEmpty {
                            path.append("room")
                        } else {
                            print("Room code is empty, access is not possible.")
                        }
                    })
                default:
                    EmptyView()
                }
            }
        }
    }
}
