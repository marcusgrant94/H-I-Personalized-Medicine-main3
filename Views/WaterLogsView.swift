//
//  WaterLogsView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/20/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct WaterLogsView: View {
    @ObservedObject var waterLogViewModel: WaterLogViewModel
    @EnvironmentObject var userViewModel: UsersViewModel
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Logs")
                .font(.title)
                .bold()
                .padding([.top, .horizontal])
                .frame(maxWidth: .infinity, alignment: .leading)
            
            List {
                ForEach(waterLogViewModel.logs.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Date: \(dateFormatter.string(from: waterLogViewModel.logs[index].date))")
                            .font(.headline)
                            .padding(.vertical, 5)
                        
                        Text("Unit: \(waterLogViewModel.logs[index].unit)")
                            
                        
                        Text("Amount: \(waterLogViewModel.logs[index].amount)")
                                                }
                    .padding(.vertical, 10)
                }
                .onDelete(perform: deleteWaterLog)
            }
            
            NavigationLink(destination: AddWaterView(waterLogViewModel: waterLogViewModel)) {
                HStack {
                    Image(systemName: "plus") // Adds a plus icon from SF Symbols
                        .foregroundColor(.white)
                    Text("Add Water")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.blue)  // You can choose your desired color
                .cornerRadius(10)
            }
            .padding([.bottom, .horizontal])
        }
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            waterLogViewModel.fetchWaterLogs(forUserWithID: waterLogViewModel.userID)
        }
    }
    
    private func deleteWaterLog(at offsets: IndexSet) {
        offsets.forEach { index in
            let log = waterLogViewModel.logs[index]
            waterLogViewModel.delete(log)
        }
    }
}

