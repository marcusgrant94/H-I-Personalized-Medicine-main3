//
//  PatientProfile.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/17/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PatientProfile: View {
    
    @ObservedObject var usersViewModel: UsersViewModel
    @ObservedObject var exerciseLogViewModel = ExerciseLogViewModel()
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var weight: Double = 0.0
    @State private var height: Double = 0.0
    @State private var age: Int = 0
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    
    var user: User
    var currentUser: User? {
           usersViewModel.users.first { $0.id == user.id }
       }
    
    
    var body: some View {
        VStack {
            if let inputImage = inputImage {
                Image(uiImage: inputImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(Circle())
                    .padding()
            } else if let profileImageURL = user.profileImageURL, let url = URL(string: profileImageURL) {
                URLImage(url: url)
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(Circle())
                    .padding()
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 70)
                    .clipShape(Circle())
                    .padding()
            }

                Text(user.name)
                    .bold()
                    .offset(y: -18)
                Text(user.email)
                    .offset(y: -15)
                Divider()
                HStack() {
                    Text("Weight: \(currentUser?.weight ?? 0) lbs")
                    Text("Height: \(currentUser?.heightFeet ?? 0) feet \(currentUser?.heightInches ?? 0) inches")
                    Text("Age: \(currentUser?.age ?? 0)")
                }
            Group {
                Divider()
                //                Group {
                NavigationLink(destination: WaterLogsView(waterLogViewModel: WaterLogViewModel(userID: user.id))) {
                    Text("Water Tracker")
                }
                Divider()
                NavigationLink(destination: ExerciseView(logViewModel: ExerciseLogViewModel(userID: user.id), userID: user.id)) {
                    Text("Exercise Tracker")
                }
                Divider()
                NavigationLink(destination: WeightEntryView(userID: user.id)) {
                    Text("Weight Entry")
                }
            }


//                }
                Spacer()
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: NavigationLink(destination: ChatView(recipientID: user.id)) {
                Image(systemName: "bubble.right.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
            })
                }
    
    
    func loadImage() {
        // Here you can do something with the selected image
    }
}

