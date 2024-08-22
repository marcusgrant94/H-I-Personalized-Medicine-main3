//
//  HealthKitView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 5/26/24.
//

import SwiftUI
import HealthKit

struct HealthKitView: View {
    @State private var healthData: [String: Double] = [:]
    private var healthStore = HealthStore()
    
    var body: some View {
        VStack {
            if healthData.isEmpty {
                Text("Requesting HealthKit Authorization...")
            } else {
                List {
                    ForEach(healthData.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(String(format: "%.2f", healthData[key]!))
                        }
                    }
                }
            }
        }
        .onAppear {
            healthStore.requestAuthorization { success in
                if success {
                    healthStore.fetchAllData { data in
                        self.healthData = data
                    }
                }
            }
        }
    }
}


#Preview {
    HealthKitView()
}
