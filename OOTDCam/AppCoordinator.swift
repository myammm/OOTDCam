//
//  AppCoordinator.swift
//  OOTDCam
//

import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    enum Screen {
        case camera
        case review
        case done
    }

    @Published var screen: Screen = .camera
    @Published var capturedImage: UIImage?

    func didCapture(_ image: UIImage) {
        capturedImage = image
        screen = .review
    }

    func retake() {
        capturedImage = nil
        screen = .camera
    }

    func didFinishSaving() {
        screen = .done
    }

    func shootAgain() {
        capturedImage = nil
        screen = .camera
    }
}
