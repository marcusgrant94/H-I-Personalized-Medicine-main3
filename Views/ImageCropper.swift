//
//  ImageCropper.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/18/23.
//

import SwiftUI
import Foundation
import TOCropViewController

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isShown: Bool

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImageCropper>) -> TOCropViewController {
        let cropViewController = TOCropViewController(image: image!)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: TOCropViewController, context: UIViewControllerRepresentableContext<ImageCropper>) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, TOCropViewControllerDelegate {
        var parent: ImageCropper

        init(parent: ImageCropper) {
            self.parent = parent
        }

        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.image = image
            parent.isShown = false
        }

        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            parent.isShown = false
        }
    }
}
