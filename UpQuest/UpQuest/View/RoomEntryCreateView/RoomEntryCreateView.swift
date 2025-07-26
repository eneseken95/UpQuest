//
//  RoomEntryCreateView.swift
//  UpQuest
//
//  Created by Enes Eken on 5.07.2025.
//

import SwiftUI

struct RoomEntryCreateView: View {
    @State private var roomCode: String = ""
    @State private var hideMyName: Bool = false
    @State private var isRoomValid: Bool = false
    @State private var showRoomAlert: Bool = false
    @State private var isRoomAvailableToCreate: Bool = false
    @State private var path: [String] = []

    @StateObject private var roomViewModel = RoomViewModel()
    @EnvironmentObject var viewModel: UserViewModel

    var displayName: String {
        hideMyName ? "Anonymous" : viewModel.username
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack(spacing: 8) {
                    Spacer()

                    VStack(spacing: 5) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.white)
                            .font(.system(size: 50))
                            .padding(.horizontal)

                        Text("\(displayName)")
                            .font(.title3)
                            .foregroundColor(.white)
                            .fontWeight(.bold)

                        if let email = viewModel.emailStorage, !email.isEmpty {
                            Text("Email: \(email)")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                                .fontWeight(.bold)
                        }

                        if let createdAt = viewModel.createdAt {
                            Text("Account creation date: \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                                .fontWeight(.bold)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 35)

                TextField("Room Code", text: $roomCode)
                    .fontWeight(.bold)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                Toggle(isOn: $hideMyName) {
                    Text("Hide my name (Anonymous)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding()
                .padding(.horizontal, 20)

                Button(action: {
                    roomViewModel.checkRoomExists(roomCode: roomCode) { exists in
                        if exists {
                            roomViewModel.addJoinedRoomToUser(roomCode, for: viewModel.username)
                            path.append("room")
                        }
                    }
                }) {
                    Text("Enter the Room")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((roomCode.isEmpty || !isRoomValid) ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundStyle((roomCode.isEmpty || !isRoomValid) ? .gray : .white)
                        .cornerRadius(8)
                }
                .disabled(roomCode.isEmpty || !isRoomValid)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                .onChange(of: roomCode) { newCode in
                    if newCode.isEmpty {
                        isRoomValid = false
                    } else {
                        roomViewModel.checkRoomExists(roomCode: newCode) { exists in
                            DispatchQueue.main.async {
                                isRoomValid = exists
                            }
                        }
                    }
                }

                Button(action: {
                    roomViewModel.checkRoomExists(roomCode: roomCode) { exists in
                        if !exists {
                            roomViewModel.createRoom(roomCode: roomCode, adminId: viewModel.username) { success in
                                if success {
                                    roomViewModel.addCreatedRoomToUser(roomCode, for: viewModel.username)
                                    DispatchQueue.main.async {
                                        path.append("room")
                                    }
                                }
                            }
                        }
                    }
                }) {
                    Text("Create the Room")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((roomCode.isEmpty || !isRoomAvailableToCreate) ? Color.gray.opacity(0.3) : Color.purple)
                        .foregroundStyle((roomCode.isEmpty || !isRoomAvailableToCreate) ? .gray : .white)
                        .cornerRadius(8)
                }
                .disabled(roomCode.isEmpty || !isRoomAvailableToCreate)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                .onChange(of: roomCode) { newCode in
                    if newCode.isEmpty {
                        isRoomAvailableToCreate = false
                    } else {
                        roomViewModel.checkRoomExists(roomCode: newCode) { exists in
                            DispatchQueue.main.async {
                                isRoomAvailableToCreate = !exists
                            }
                        }
                    }
                }

                VStack(spacing: 25) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            JoinedRoomsView(
                                roomViewModel: roomViewModel,
                                onRoomSelected: { code in
                                    roomViewModel.checkRoomExists(roomCode: code) { exists in
                                        if exists {
                                            self.roomCode = code
                                            roomViewModel.addJoinedRoomToUser(code, for: viewModel.username)
                                            path.append("room")
                                        } else {
                                            showRoomAlert = true
                                        }
                                    }
                                },
                                onRoomDeleted: { code in
                                    roomViewModel.removeJoinedRoomFromUser(code, for: viewModel.username)
                                    roomViewModel.joinedRooms.removeAll { $0 == code }
                                }
                            )
                            .frame(width: 300, height: 270)

                            CreatedRoomsView(
                                roomViewModel: roomViewModel,
                                username: viewModel.username,
                                onRoomSelected: { code in
                                    roomViewModel.checkRoomExists(roomCode: code) { exists in
                                        if exists {
                                            self.roomCode = code
                                            path.append("room")
                                        } else {
                                            showRoomAlert = true
                                        }
                                    }
                                },
                                onRoomDeleted: { deletedCode in
                                    roomViewModel.deleteCreatedRoomFromUser(roomCode: deletedCode, for: viewModel.username) { success, errorMessage in
                                        if success {
                                            print("The room was deleted successfully.")
                                        } else if let msg = errorMessage {
                                            print("Delete failed: \(msg)")
                                        }
                                    }
                                }
                            )
                            .frame(width: 300, height: 270)
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Background_Color"))
            .ignoresSafeArea()
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        hideKeyboard()
                    }
            )
            .onAppear {
                roomCode = ""
                roomViewModel.ensureUserDocumentExists(userId: viewModel.username)
                roomViewModel.fetchUserRooms(userId: viewModel.username) { }
            }
            .alert(isPresented: $showRoomAlert) {
                Alert(
                    title: Text("The selected room was deleted."),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(for: String.self) { value in
                if value == "room" {
                    QuestionListView(roomCode: roomCode, hideMyName: hideMyName)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    let vm = UserViewModel()
    vm.username = "enes"
    vm.emailStorage = "enes@example.com"
    vm.createdAt = Date(timeIntervalSince1970: 1688000000)

    return RoomEntryCreateView()
        .environmentObject(vm)
}
