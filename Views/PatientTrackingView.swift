//
//  PatientTrackingView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/19/23.
//

import SwiftUI

struct PatientTrackingView: View {
    let userID: String
    @StateObject var waterLogViewModel: WaterLogViewModel
    @StateObject var exerciseLogViewModel: ExerciseLogViewModel
    @State private var showingTutorialAlert = false
    
    init(userID: String) {
        self.userID = userID
        self._waterLogViewModel = StateObject(wrappedValue: WaterLogViewModel(userID: userID))
        self._exerciseLogViewModel = StateObject(wrappedValue: ExerciseLogViewModel(userID: userID))
    }
    
    
    let columns = [GridItem(.flexible()),
                   GridItem(.flexible())
    ]
    let componetList = [
        componets(name: "Water", image: "waterdrop"),
        componets(name: "Weight", image: "scale"),
        componets(name: "Exercise", image: "dumbells"),
        componets(name: "Height", image: "height"),
        componets(name: "Age", image: "age")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(componetList.indices, id: \.self) { index in
                            let component = componetList[index]
                            switch component.name {
                            case "Water":
                                NavigationLink(destination: WaterLogsView(waterLogViewModel: waterLogViewModel)) {
                                    TrackingView(name: component.name, image: component.image)
                                }
                            case "Weight":
                                NavigationLink(destination: WeightEntryView(userID: userID)) {
                                    TrackingView(name: component.name, image: component.image)
                                }
                            case "Exercise":
                                NavigationLink(destination: ExerciseView(logViewModel: exerciseLogViewModel, userID: self.userID)) {
                                    TrackingView(name: component.name, image: component.image)
                                }
                            case "Height":
                                NavigationLink(destination: HeightEntryView()) {
                                    TrackingView(name: component.name, image: component.image)
                                }
                            case "Age":
                                NavigationLink(destination: AgeEntryView()) {
                                    TrackingView(name: component.name, image: component.image)
                                }
                            default:
                                TrackingView(name: component.name, image: component.image)
                            }
                        }
                    }
                    
                    NavigationLink(destination: HealthKitView()) {
                        Text("HealthKit")
                    }
                    .padding()
                }
                .navigationTitle("Health Tracking")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading:
                                        NavigationLink(destination: SettingsView2()) {
                    Image(systemName: "gear")
                        .imageScale(.large)
                        .padding()
                        .accessibilityLabel("Settings")
                }.buttonStyle(PlainButtonStyle()))
            }
        }
        .onAppear {
                    if UserDefaults.standard.bool(forKey: "hasSeenTrackingTutorial") == false {
                        showingTutorialAlert = true
                    }
                }
                .alert(isPresented: $showingTutorialAlert) {
                    Alert(title: Text("Tracking"),
                          message: Text("Here you can track various health metrics like water consumption, weight, exercise, and more."),
                          dismissButton: .default(Text("Got it!")) {
                            UserDefaults.standard.set(true, forKey: "hasSeenTrackingTutorial")
                          })
                }
    }
    
    struct TrackingView: View {
        let name: String
        let image: String
        
        var body: some View {
            Tracking(imageName: image, caption: name)
        }
    }
}



struct PatientTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        PatientTrackingView(userID: "dummyUserID")
    }
}
