//
//  AgeEntryView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/17/23.
//

import SwiftUI
import Firebase

struct AgeEntryView: View {
    @State var age: Int = 0
    @State private var showAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // This color will set the background for the entire ZStack
            Color.backgroundGray // or whichever color you'd like
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Enter Your Age")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                VStack(spacing: 20) {
                    HStack {
                        TextField("Age", value: $age, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .frame(width: 100, alignment: .center)
                    }
                    .padding(.horizontal)

                    Button("Submit Age") {
                        storeAgeInFirestore(age: age)
                        showAlert = true
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Age Submitted"),
                            message: Text("Your age has been recorded as \(age) years."),
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
        .navigationTitle("Age Entry")
    }

    func storeAgeInFirestore(age: Int) {
        let db = Firestore.firestore()
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user ID found")
            return
        }

        db.collection("users").document(userID).setData(["age": age], merge: true) { err in
            if let err = err {
                print("Error adding age data: \(err)")
            } else {
                print("Age data successfully written!")
            }
        }
    }

    }

struct AgeEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AgeEntryView()
    }
}
