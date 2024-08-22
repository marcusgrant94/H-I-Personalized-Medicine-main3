//
//  MessageView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 7/24/23.
//

import SwiftUI

struct MessageView: View {
    var message: Message
    @State private var isImageViewerPresented: Bool = false

    var body: some View {
        HStack {
            if message.isCurrentUser {
                Spacer()
            }

            if let imageURL = message.imageURL, let url = URL(string: imageURL) {
                // Show the image if imageURL is not nil
                URLImage(url: url)
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                    .onTapGesture {
                        isImageViewerPresented.toggle()
                    }
                    .sheet(isPresented: $isImageViewerPresented) {
                        FullScreenImageView(imageURL: url)
                    }
            } else {
                // Show the text message if imageURL is nil
                Text(message.text)
                    .padding()
                    .background(ChatBubble(isFromCurrentUser: message.isCurrentUser).fill(message.isCurrentUser ? Color.blue : Color.gray.opacity(0.2))) // Background color
                    .foregroundColor(message.isCurrentUser ? .white : .black) // Foreground color based on isCurrentUser
                    .cornerRadius(10)
            }

            if !message.isCurrentUser {
                Spacer()
            }
        }
    }
}



struct ChatBubble: Shape {
    var isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [.topLeft, .topRight, isFromCurrentUser ? .bottomLeft : .bottomRight],
                                cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}
