//
//  ContentView.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        ZStack {
            switch coordinator.screen {
            case .camera:
                CameraView(onPhotoTaken: coordinator.didCapture)
                    .transition(.opacity)
            case .review:
                if let image = coordinator.capturedImage {
                    ReviewView(
                        image: image,
                        onRetake: coordinator.retake,
                        onDone: coordinator.didFinishSaving
                    )
                    .transition(.opacity)
                }
            case .done:
                DoneView(onShootAgain: coordinator.shootAgain)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.screen)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
