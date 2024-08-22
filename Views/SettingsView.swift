//
//  SettingsView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/14/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct SettingsView: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let currentUser = Auth.auth().currentUser
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage? = nil
    @State private var inputImage: UIImage?
    @State private var showingConfirmationAlert = false
    var user: User?

    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
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
                }
                Text(getUser()?.name ?? "Not Signed In")
                    .bold()
                    .offset(y: -18)
                Text(getUser()?.email ?? "Not Signed In")
                    .offset(y: -15)
                Spacer()
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Group {
                Button {
                    showingConfirmationAlert = true
                } label: {
                    Text("Log Out")
                        .foregroundColor(.red)
                }
            }
            )
            .alert(isPresented: $showingConfirmationAlert) {
                Alert(title: Text("Log Out"),
                      message: Text("Are you sure you want to log out?"),
                      primaryButton: .destructive(Text("Log Out"), action: {
                        authViewModel.signOut { (success, errorMessage) in
                            if success {
                                // You can perform navigation or change the state that controls the view hierarchy here
                               authViewModel.isSignedIn = false
                                // Optionally, navigate to the login screen or update the UI to show that the user is not signed in
                            } else {
                                // You could show another alert here if there's an error
                                print("Logout failed: \(errorMessage ?? "Unknown error")")
                            }
                        }
                    }),
                      secondaryButton: .cancel())
            }

        }
        .onAppear {
            loadImageFromURL()
        }
    }
    
    func loadImageFromURL() {
        guard let user = getUser(), let urlString = user.profileImageURL, let url = URL(string: urlString) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.profileImage = UIImage(data: data)
                }
            }
        }
    }
    
    func loadImage() {
        guard let user = getUser(), let inputImage = inputImage else { return }
        profileImage = nil
        usersViewModel.uploadImage(inputImage, for: user)

        }
    
    func getUser() -> User? {
        return usersViewModel.users.first { $0.id == currentUser?.uid }
    }
}
