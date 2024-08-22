//
//  ChatView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/24/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CloudKit
import FirebaseStorage

struct Message: Identifiable {
    var id: String
    var text: String
    var imageURL: String?
    var userID: String
    var timestamp: Date
    
    var isCurrentUser: Bool { userID == Auth.auth().currentUser?.uid }
}

class ChatViewModel: ObservableObject {
    @Published var lastMessageID: String?
    
    func subscribeToCloudKitChanges() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("No User is currently signed in")
            return
        }
        
        let predicate = NSPredicate(format: "recipientID == %@", currentUserID)
        let subscription = CKQuerySubscription(recordType: "ChatMessage", predicate: predicate, options: .firesOnRecordCreation)
        let info = CKSubscription.NotificationInfo()
        info.alertBody = "You have a new message"
        info.soundName = "default" // "default" is the system sound
        info.shouldBadge = true
        subscription.notificationInfo = info
        CKContainer(identifier: "iCloud.random.H-I-Personalized-Medicine").publicCloudDatabase.save(subscription) { result, error in
            if let error = error {
                print("Failed to setup subscription: \(error.localizedDescription)")
            } else {
                print("Subscription setup successfully")
            }
        }
    }

}

struct ChatView: View {
    @State private var message = ""
    @State private var messages = [Message]()
    @State private var messagesCount = 0
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showingAlert = false
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var usersViewModel: UsersViewModel // Inject the UsersViewModel
    var recipientID: String // The userID of the person you're chatting with

    var recipient: User? {
        return usersViewModel.users.first(where: { $0.id == recipientID })
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollView in
                    LazyVStack {
                        ForEach(messages.indices, id: \.self) { index in
                            if shouldShowTimestamp(index: index) {
                                Text(getTimestampString(index: index))
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 5)
                            }
                            MessageView(message: messages[index])
                                .id(messages[index].id)
                                .padding(.horizontal)
                        }
                    }
                    .onChange(of: messages.count) { newCount in
                        if newCount > messagesCount {
                            withAnimation {
                                scrollView.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                            messagesCount = newCount
                        }
                    }
                }
            }
            .onAppear {
                fetchMessages()
                viewModel.subscribeToCloudKitChanges()
            }
            HStack {
                TextField("Message", text: $message)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(Color(.gray), lineWidth: 1)
                    )

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding(.all, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8.0)
                }
                .disabled(message.isEmpty)

                Button(action: { isImagePickerPresented.toggle() }) {
                    Image(systemName: "photo.fill")
                        .padding(.all, 10)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8.0)
                }
            }
            .padding(.horizontal, 25)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        if let recipient = recipient,
                           let profileImageURL = recipient.profileImageURL,
                           let url = URL(string: profileImageURL) {
                            URLImage(url: url)
                                .frame(width: 43, height: 50)
                                .clipShape(Circle())
                                .padding(.bottom, 4)
                        }
//                        Text(recipient?.name ?? "User")
                    }
//                    .padding(.top, 5)
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage) // Show the image picker when the button is tapped
            }
            .onChange(of: selectedImage) { newImage in
                // Handle the selected image by uploading it and then sending a message with its URL
                if let imageToUpload = newImage {
                    uploadAndSendMessage(image: imageToUpload)
                }
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "hasSeenChatTutorial") == false {
                showingAlert = true
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Messages"), message: Text("Here you can chat directly with your personal care provider"), dismissButton: .default(Text("Got it!")) {
                UserDefaults.standard.set(true, forKey: "hasSeenChatTutorial")
            })
        }
    }
    
    func uploadAndSendMessage(image: UIImage) {
        // Convert the UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        // Create a unique file name (this could be different depending on your requirements)
        let fileName = UUID().uuidString + ".jpg"

        // Create a reference to the location where you want to upload the file
        let storageRef = Storage.storage().reference().child("images/\(fileName)")

        // Upload the file to the reference
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            guard let _ = metadata else {
                print("Error uploading image: \(error?.localizedDescription ?? "")")
                return
            }

            // Retrieve download URL
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    print("Error getting download URL: \(error?.localizedDescription ?? "")")
                    return
                }

                // Create a new Message object with the image URL
                let userID = Auth.auth().currentUser?.uid ?? ""
                let newMessage = Message(
                    id: UUID().uuidString,
                    text: "",
                    imageURL: downloadURL.absoluteString,
                    userID: userID,
                    timestamp: Date()
                )


                // Add the new message to your messages array, or however you're handling messages
                self.messages.append(newMessage)
                
                // Add code to save the image message to Firestore
                        let db = Firestore.firestore()
                        db.collection("messages").addDocument(data: [
                            "text": "",
                            "userID": userID,
                            "recipientID": self.recipientID,
                            "creationTime": Timestamp(date: Date()),
                            "imageURL": downloadURL.absoluteString // Add this line
                        ]) { error in
                            if let error = error {
                                print("Failed to send image message in Firestore: \(error.localizedDescription)")
                            } else {
                                print("Image message sent successfully in Firestore")
                            }
                        }
            }
        }
    }

    
    func fetchMessages() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("No user is currently signed in")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("messages")
            .whereField("userID", in: [currentUserID, recipientID])
            .whereField("recipientID", in: [currentUserID, recipientID])
            .order(by: "creationTime", descending: false)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.messages = documents.map { queryDocumentSnapshot -> Message in
                    let data = queryDocumentSnapshot.data()
                    let id = data["userID"] as? String ?? "Unknown User"
                    let text = data["text"] as? String ?? ""
                    let imageURL = data["imageURL"] as? String // Add this line
                    let timestamp = (data["creationTime"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return Message(id: queryDocumentSnapshot.documentID, text: text, imageURL: imageURL, userID: id, timestamp: timestamp) // Modify this line
                }
            }
    }
    
    func fetchCloudKitMessages() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("No user is currently signed in")
            return
        }

        let container = CKContainer(identifier: "iCloud.random.H-I-Personalized-Medicine")
        let publicDatabase = container.publicCloudDatabase

        // Create a predicate that will return all ChatMessage records where the userID or recipientID is the current user's ID
        let predicate = NSPredicate(format: "(userID == %@) AND (recipientID == %@)", currentUserID, recipientID)
        
        // Create a query with the predicate and the desired sort descriptors
        let query = CKQuery(recordType: "ChatMessage", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationTime", ascending: false)]
        
        // Perform the query
        publicDatabase.perform(query, inZoneWith: nil) { (results, error) in
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                return
            }
            
            if let results = results {
                // Handle the results
                // Note: this is run on a background queue, so make sure to dispatch any UI updates to the main queue
                DispatchQueue.main.async {
                    self.messages = results.map { record -> Message in
                        let id = record["userID"] as? String ?? "Unknown User"
                        let text = record["text"] as? String ?? ""
                        let timestamp = record["creationTime"] as? Date ?? Date()

                        return Message(id: record.recordID.recordName, text: text, userID: id, timestamp: timestamp)
                    }

                }
            }
        }
    }




    func sendMessage() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("No user is currently signed in")
            return
        }

        // Firestore
        let db = Firestore.firestore()
        db.collection("messages").addDocument(data: [
            "text": message,
            "userID": currentUserID,
            "recipientID": recipientID,
            "creationTime": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Failed to send message in Firestore: \(error.localizedDescription)")
            } else {
                print("Message sent successfully in Firestore")
            }
        }

        // CloudKit
        let container = CKContainer(identifier: "iCloud.random.H-I-Personalized-Medicine")
        let database = container.publicCloudDatabase

        let newMessageRecord = CKRecord(recordType: "ChatMessage")
        newMessageRecord["text"] = message as CKRecordValue
        newMessageRecord["userID"] = currentUserID as CKRecordValue
        newMessageRecord["recipientID"] = recipientID as CKRecordValue

        database.save(newMessageRecord) { (record, error) in
            if let error = error {
                print("Failed to send message in CloudKit: \(error.localizedDescription)")
            } else {
                print("Message sent successfully in CloudKit")
                DispatchQueue.main.async {
                    self.message = ""
                }
            }
        }
    }
    
    // Determines if the timestamp should be shown based on the difference in time between the current message and the next one
    func shouldShowTimestamp(index: Int) -> Bool {
        guard index < messages.count - 1 else {
            return false // Do not show timestamp for last message
        }
        let currentTimestamp = messages[index].timestamp
        let nextTimestamp = messages[index + 1].timestamp
        
        return nextTimestamp.timeIntervalSince(currentTimestamp) >= 5 * 60 // 10 minutes
    }

    
    func getTimestampString(index: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short  // This will include the date
        dateFormatter.timeStyle = .short

        // Check if index + 1 is a valid index
        guard index + 1 < messages.count else {
            // Return an empty string or some default value
            return ""
        }

        return dateFormatter.string(from: messages[index + 1].timestamp)
    }






    func generateConversationID(userID: String, recipientID: String) -> String {
        return userID < recipientID ? userID + recipientID : recipientID + userID
    }


}
