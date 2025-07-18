//
//  RoomViewModel.swift
//  UpQuest
//
//  Created by Enes Eken on 6.07.2025.
//

import FirebaseFirestore

class RoomViewModel: ObservableObject {
    private var db = Firestore.firestore()

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
}
