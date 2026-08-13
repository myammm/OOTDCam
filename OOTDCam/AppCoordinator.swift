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
    @Published var capturedPhoto: CapturedPhoto?

    func didCapture(_ photo: CapturedPhoto) {
        capturedPhoto = photo
        screen = .review
    }

    func retake() {
        capturedPhoto = nil
        screen = .camera
    }

    func didFinishSaving() {
        screen = .done
    }

    func shootAgain() {
        capturedPhoto = nil
        screen = .camera
    }
}
