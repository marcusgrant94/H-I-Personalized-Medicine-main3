//
//  TutorialOverlay.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/18/23.
//

import SwiftUI

struct TutorialOverlay: ViewModifier {
    var text: String
    @Binding var show: Bool

    func body(content: Content) -> some View {
        ZStack {
            if show {
                content
                    .blur(radius: 3)
                    .overlay(
                        Text(text)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding()
                        , alignment: .bottom)
            } else {
                content
            }
        }
    }
}

extension View {
    func tutorialOverlay(text: String, show: Binding<Bool>) -> some View {
        self.overlay(
            VStack {
                if show.wrappedValue {
                    Spacer(minLength: 0)  // push the shape to the bottom
                    
                    ZStack {
                        SpeechBubble()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 250, height: 80)
                            .offset(y: -10)  // adjust this to fine-tune position
                            
                        Text(text)
                            .foregroundColor(.white)
                            .padding()
                            .offset(y: -10)  // adjust this to fine-tune position
                    }
                }
            }
        )
    }
}

extension View {
    func blurBackground(show: Binding<Bool>) -> some View {
        self.overlay(
            Group {
                if show.wrappedValue {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .blur(radius: 5)
                        .onTapGesture {
                            show.wrappedValue = false
                        }
                }
            }
        )
    }
}


