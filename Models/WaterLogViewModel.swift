//
//  WaterLogVieModel.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/20/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct WaterLog: Identifiable {
    let id: UUID
    let date: Date
    let unit: String
    let amount: String
}


class WaterLogViewModel: ObservableObject {
    @Published var logs: [WaterLog] = []
    private var db = Firestore.firestore()
    let userID: String
    
    init(userID: String) {
        self.userID = userID
    }
    
    func addWaterLog(forUserWithID id: String, logEntry: WaterLog) {
        let waterLogData: [String: Any] = [
            "date": logEntry.date,
            "unit": logEntry.unit,
            "amount": logEntry.amount
        ]
        
        db.collection("users").document(id).collection("waterLogs").document(logEntry.id.uuidString).setData(waterLogData) { error in
            if let error = error {
                print("Error adding water log to Firestore: \(error)")
            } else {
                print("Water log added to Firestore successfully.")
                self.fetchWaterLogs(forUserWithID: id)
            }
        }
    }
    
    func fetchWaterLogs(forUserWithID id: String) {
            db.collection("users").document(id).collection("waterLogs").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
                self.logs = documents.map { queryDocumentSnapshot -> WaterLog in
                                let data = queryDocumentSnapshot.data()
                                let date = data["date"] as? Timestamp
                                let unit = data["unit"] as? String ?? ""
                                let amount = data["amount"] as? String ?? ""
                                let id = UUID(uuidString: queryDocumentSnapshot.documentID) ?? UUID() // Convert documentID to UUID

                                return WaterLog(id: id, date: date?.dateValue() ?? Date(), unit: unit, amount: amount)
            }
        }
    }

    
    func delete(_ log: WaterLog) {
        let docRefPath = db.collection("users").document(userID).collection("waterLogs").document(log.id.uuidString)
        print("Attempting to delete document at path: \(docRefPath.path)")
        docRefPath.delete { [self] err in
            if let err = err {
                print("Error removing log: \(err)")
            } else {
                print("Log successfully removed!")
                self.fetchWaterLogs(forUserWithID: self.userID) // Fetch logs again to refresh
            }
        }
    }
    
    struct FirestoreEncoder {
        func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            let data = try encoder.encode(value)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            return dictionary ?? [:]
        }
    }


    
    
}



