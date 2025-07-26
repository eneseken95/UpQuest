//
//  RoomViewModel.swift
//  UpQuest
//
//  Created by Enes Eken on 6.07.2025.
//

import FirebaseFirestore

class RoomViewModel: ObservableObject {
    private var db = Firestore.firestore()
    @Published var joinedRooms: [String] = []
    @Published var createdRooms: [String] = []

    func createRoom(roomCode: String, adminId: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("rooms").document(roomCode)
        ref.setData([
            "adminId": adminId,
            "createdAt": Timestamp(date: Date()),
        ]) { error in
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
        let docRef = Firestore.firestore().collection("rooms").document(roomCode)
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
                            self.createdRooms.removeAll { $0 == roomCode }
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
        let ref = db.collection("users").document(userId)
        ref.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching user rooms: \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }

            DispatchQueue.main.async {
                self.joinedRooms = data["joinedRooms"] as? [String] ?? []
                self.createdRooms = data["createdRooms"] as? [String] ?? []
                completion()
            }
        }
    }
}
