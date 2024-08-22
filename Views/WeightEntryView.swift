//
//  WeightEntryView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/24/23.
//

import SwiftUI
import FirebaseFirestore

struct WeightEntry: Identifiable {
    var id: UUID? = UUID()
    var documentID: String?
    var weight: Double
    var date: Date
}

struct WeightEntryView: View {
    let userID: String
    @ObservedObject var usersViewModel = UsersViewModel()
    @State private var entries: [WeightEntry] = []
    @State private var weightEntry = WeightEntry(weight: 0.0, date: Date())
    @State private var isSubmissionViewPresented = false
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var currentUser: User? {
        return usersViewModel.users.first(where: { $0.id == userID })
    }
    
    var body: some View {
        ZStack {
            // Main Content
            VStack(spacing: 20) {
                Text("Logs")
                    .font(.title)
                    .bold()
                    .padding([.top, .horizontal])
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                List {
                    ForEach(entries.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Date: \(Self.dateFormatter.string(from: entries[index].date))")
                                .font(.headline)
                                .padding(.vertical, 5)
                            
                            Text("Weight: \(String(format: "%g", entries[index].weight)) lbs")
                                .padding(.vertical, 5)
                        }
                        .padding(.vertical, 10)
                    }
                    .onDelete(perform: deleteEntry)
                }
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                usersViewModel.fetchData(for: userID)
                fetchEntries()
            }
            
            // Floating Button
            VStack {
                Spacer() // push the button to the bottom
                HStack {
                    Spacer() // push the button to the trailing edge
                    AddPostButton {
                        isSubmissionViewPresented = true
                    }
                    .padding([.bottom, .trailing])
                    .disabled(usersViewModel.currentUserRole == "admin")
                }
            }
        }
        .sheet(isPresented: $isSubmissionViewPresented) {
            WeightSubmissionView(userID: self.userID)
        }
    }
    


    func fetchEntries() {
        let db = Firestore.firestore()
        db.collection("weightLogs").whereField("userID", isEqualTo: userID).order(by: "date", descending: true).addSnapshotListener { (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                print("Error fetching logs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let newEntries = documents.compactMap { document in
                let data = document.data()
                let weight = data["weight"] as? Double ?? 0.0
                let date = data["date"] as? Date ?? Date()
                return WeightEntry(documentID: document.documentID, weight: weight, date: date)
            }

            DispatchQueue.main.async {
                self.entries = newEntries
            }
        }
    }




    
    func deleteEntry(at offsets: IndexSet) {
        let db = Firestore.firestore()

        // For each index in the offsets:
        offsets.forEach { index in
            guard let documentID = entries[index].documentID else {
                print("Error: Missing document ID for deletion")
                return
            }

            // Delete from Firestore
            db.collection("weightLogs").document(documentID).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
        }

        // Remove entries locally
        entries.remove(atOffsets: offsets)
    }



}


