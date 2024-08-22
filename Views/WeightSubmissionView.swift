//
//  WeightSubmissionView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/16/23.
//

import SwiftUI
import Firebase

struct WeightSubmissionView: View {
    let userID: String
    let id: String? = nil
    @State private var weightEntry = WeightEntry(id: nil, weight: 0.0, date: Date())
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
            VStack {
                Form {
                    Section(header: Text("Weight")) {
                        TextField("Enter your weight", value: $weightEntry.weight, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                    }
                }
                
                Button(action: submitWeightData) {
                    Text("Submit")
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Submitted Successfully"),
                          message: Text("Your weight information has been submitted successfully"),
                          dismissButton: .default(Text("OK")) {
                              self.presentationMode.wrappedValue.dismiss()
                          })
                }
            }
        }
        
        func submitWeightData() {
            let db = Firestore.firestore()

            // Update users collection with the latest weight data
            let userData: [String: Any] = [
                "weight": weightEntry.weight,
                "date": weightEntry.date
            ]
            
            db.collection("users").document(userID).setData(userData, merge: true)

            // Add a new log to the weightLogs collection
            var logData = userData
            logData["userID"] = userID
            db.collection("weightLogs").addDocument(data: logData) { err in
                if let err = err {
                    print("Error adding log: \(err)")
                } else {
                    self.showingAlert = true
                }
            }
        }
    }
