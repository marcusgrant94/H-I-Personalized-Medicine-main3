//
//  AddPostButton.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/16/23.
//

import SwiftUI

import SwiftUI

struct AddPostButton: View {
    var action: () -> Void = {} // this closure can be used to define what happens when the button is tapped

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .foregroundColor(.blue) // or any color you like
                    .frame(width: 50, height: 50)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct AddPostButton_Previews: PreviewProvider {
    static var previews: some View {
        AddPostButton()
    }
}

