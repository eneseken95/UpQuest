//
//  RoomViewModel.swift
//  UpQuest
//
//  Created by Enes Eken on 6.07.2025.
//

import FirebaseFirestore

class RoomViewModel: ObservableObject {
    private var db = Firestore.firestore()

    @Published var joinedRooms: [Room] = []
    @Published var createdRooms: [Room] = []
    @Published var isLoading: Bool = false

    func createRoom(roomCode: String, adminId: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("rooms").document(roomCode)
        let room = Room(id: roomCode, adminId: adminId, createdAt: Date())

        ref.setData(room.toDictionary()) { error in
            if let error = error {
                print("Room could not be created: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func checkRoomExists(roomCode: String, completion: @escaping (Bool) -> Void) {
        guard !roomCode.isEmpty else {
            completion(false)
            return
        }

        let docRef = db.collection("rooms").document(roomCode)
        docRef.getDocument { snapshot, _ in
            if let snapshot = snapshot, snapshot.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    func ensureUserDocumentExists(userId: String) {
        let ref = db.collection("users").document(userId)
        ref.getDocument { snapshot, _ in
            if snapshot?.exists != true {
                ref.setData([
                    "joinedRooms": [],
                    "createdRooms": [],
                ])
            }
        }
    }

    func addJoinedRoomToUser(_ roomCode: String, for userId: String) {
        let ref = db.collection("users").document(userId)
        ref.updateData([
            "joinedRooms": FieldValue.arrayUnion([roomCode]),
        ])
    }

    func addCreatedRoomToUser(_ roomCode: String, for userId: String) {
        let ref = db.collection("users").document(userId)
        ref.updateData([
            "createdRooms": FieldValue.arrayUnion([roomCode]),
        ])
    }

    func removeJoinedRoomFromUser(_ roomCode: String, for userId: String) {
        let ref = db.collection("users").document(userId)
        ref.updateData([
            "joinedRooms": FieldValue.arrayRemove([roomCode]),
        ])
    }

    func deleteCreatedRoomFromUser(roomCode: String, for userId: String, completion: @escaping (Bool, String?) -> Void) {
        let roomRef = db.collection("rooms").document(roomCode)
        let userRef = db.collection("users").document(userId)

        roomRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking room: \(error.localizedDescription)")
                completion(false, "An error occurred while checking the room.")
                return
            }
            guard let data = snapshot?.data(), snapshot?.exists == true else {
                completion(false, "Room not found.")
                return
            }

            if let adminId = data["adminId"] as? String, adminId == userId {
                roomRef.delete { error in
                    if let error = error {
                        print("Error while deleting room: \(error.localizedDescription)")
                        completion(false, "An error occurred while deleting the room.")
                        return
                    }

                    userRef.updateData([
                        "createdRooms": FieldValue.arrayRemove([roomCode]),
                    ]) { error in
                        if let error = error {
                            print("Could not delete room from user-createdRooms array: \(error.localizedDescription)")
                            completion(false, "The room was deleted but the user record could not be updated.")
                            return
                        }

                        DispatchQueue.main.async {
                            self.createdRooms.removeAll { $0.id == roomCode }
                        }
                        completion(true, nil)
                    }
                }
            } else {
                completion(false, "You do not have permission to delete this room.")
            }
        }
    }

    func fetchUserRooms(userId: String, completion: @escaping () -> Void) {
        isLoading = true
        let ref = db.collection("users").document(userId)
        ref.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching user rooms: \(error?.localizedDescription ?? "Unknown error")")
                self.isLoading = false
                completion()
                return
            }

            let joinedRoomCodes = data["joinedRooms"] as? [String] ?? []
            let createdRoomCodes = data["createdRooms"] as? [String] ?? []

            self.fetchRoomsByCodes(joinedRoomCodes) { joinedRooms in
                self.fetchRoomsByCodes(createdRoomCodes) { createdRooms in
                    DispatchQueue.main.async {
                        self.joinedRooms = joinedRooms
                        self.createdRooms = createdRooms
                        self.isLoading = false
                        completion()
                    }
                }
            }
        }
    }

    private func fetchRoomsByCodes(_ roomCodes: [String], completion: @escaping ([Room]) -> Void) {
        let group = DispatchGroup()
        var fetchedRooms: [Room] = []

        for code in roomCodes {
            group.enter()
            let ref = db.collection("rooms").document(code)
            ref.getDocument { snapshot, _ in
                if let data = snapshot?.data(),
                   let room = Room(document: data, documentId: code) {
                    fetchedRooms.append(room)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(fetchedRooms)
        }
    }
}
