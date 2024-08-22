//
//  CustomTextEditior.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/16/23.
//

import SwiftUI

struct CustomTextEditor: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .background(Color.clear)
                .cornerRadius(8)

            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.all, 6) // Adjust padding to your liking
            }
        }
    }
}

struct CustomTextEditor_Previews: PreviewProvider {
    @State static var text: String = ""
    
    static var previews: some View {
        CustomTextEditor(text: $text, placeholder: "Write a specific title")
            .frame(height: 200)
            .padding()
            .border(Color.gray)
    }
}

