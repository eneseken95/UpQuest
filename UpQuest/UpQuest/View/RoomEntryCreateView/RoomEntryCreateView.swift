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
    @State private var isRoomAvailableToCreate: Bool = false
    @State private var showRoomAlert: Bool = false
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

                        Text(displayName)
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
                .padding(.top, 45)

                TextField("Room Code", text: $roomCode)
                    .fontWeight(.bold)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    .onChange(of: roomCode) { newCode in
                        let trimmed = newCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            isRoomValid = false
                            isRoomAvailableToCreate = false
                            return
                        }

                        roomViewModel.checkRoomExists(roomCode: trimmed) { exists in
                            DispatchQueue.main.async {
                                isRoomValid = exists
                                isRoomAvailableToCreate = !exists
                            }
                        }
                    }

                Toggle(isOn: $hideMyName) {
                    Text("Hide my name (Anonymous)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding()
                .padding(.horizontal, 20)

                Button {
                    guard isRoomValid else { return }
                    roomViewModel.addJoinedRoomToUser(roomCode, for: viewModel.username)
                    path.append("room")
                } label: {
                    Text("Enter the Room")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRoomValid ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundStyle(isRoomValid ? .white : .gray)
                        .cornerRadius(8)
                }
                .disabled(!isRoomValid)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)

                Button {
                    guard isRoomAvailableToCreate else { return }
                    roomViewModel.createRoom(roomCode: roomCode, adminId: viewModel.username) { success in
                        if success {
                            roomViewModel.addCreatedRoomToUser(roomCode, for: viewModel.username)
                            DispatchQueue.main.async {
                                path.append("room")
                            }
                        }
                    }
                } label: {
                    Text("Create the Room")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRoomAvailableToCreate ? Color.purple : Color.gray.opacity(0.3))
                        .foregroundStyle(isRoomAvailableToCreate ? .white : .gray)
                        .cornerRadius(8)
                }
                .disabled(!isRoomAvailableToCreate)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)

                VStack(spacing: 25) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
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
                                    roomViewModel.joinedRooms.removeAll { $0.id == code }
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
                    title: Text("Room deleted"),
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
    RoomEntryCreateView()
        .environmentObject({
            let vm = UserViewModel()
            vm.usernameStorage = "enes"
            vm.emailStorage = "enes@example.com"
            vm.createdAtStorage = 1688000000
            vm.isUserLoggedIn = true
            return vm
        }())
}
