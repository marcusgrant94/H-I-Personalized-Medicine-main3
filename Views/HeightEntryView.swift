//
//  HeightEntryView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/17/23.
//

import SwiftUI
import Firebase


struct HeightEntryView: View {
    @State var heightFeet: Int = 0
    @State var heightInches: Int = 0
    @State private var showAlert = false
    @Environment(\.presentationMode) var presentationMode


    var body: some View {
        ZStack {
            // This color will set the background for the entire ZStack
            Color.backgroundGray // or whichever color you'd like
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Enter Your Height")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        groupForMeasurement(value: $heightFeet, label: "Feet")
                        groupForMeasurement(value: $heightInches, label: "Inches")
                    }
                    .padding(.horizontal)

                    Button("Submit Height") {
                        let totalHeightInInches = (heightFeet * 12) + heightInches
                        storeHeightInFirestore(feet: heightFeet, inches: heightInches)
                        showAlert = true
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Height Submitted"),
                            message: Text("Your height has been recorded as \(heightFeet) feet and \(heightInches) inches."),
                            dismissButton: .default(Text("OK")) {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(15)
                .padding(.horizontal)
                
            }.padding(.vertical)
        }
        .navigationTitle("Height Entry")
    }

    // A helper function to create the grouped measurement views
    private func groupForMeasurement(value: Binding<Int>, label: String) -> some View {
        VStack(alignment: .center) {
            TextField("0", value: value, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            Text(label)
                .font(.subheadline)
        }
    }
}

extension Color {
    static let backgroundGray = Color("backgroundGray") // You'll need to define this color in your asset catalog
}


func storeHeightInFirestore(feet: Int, inches: Int) {
    let db = Firestore.firestore()
    guard let userID = Auth.auth().currentUser?.uid else {
        print("Error: No user ID found")
        return
    }

    let heightData: [String: Any] = [
        "feet": feet,
        "inches": inches
    ]

    db.collection("users").document(userID).setData(["height": heightData], merge: true) { err in
        if let err = err {
            print("Error adding height data: \(err)")
        } else {
            print("Height data successfully written!")
        }
    }
}




struct HeightEntryView_Previews: PreviewProvider {
    static var previews: some View {
        HeightEntryView()
    }
}
