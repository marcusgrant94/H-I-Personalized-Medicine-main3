//
//  FullScreenImageView.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/10/23.
//

import Foundation
import SwiftUI

struct FullScreenImageView: View {
    let imageURL: URL

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } placeholder: {
                ProgressView() // Placeholder while loading
            }
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
        }
    }
}



