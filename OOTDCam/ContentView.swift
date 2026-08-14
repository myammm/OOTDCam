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
            // クロスフェード中は前後の画面が両方半透明になり、背後のウィンドウの地 (黒) が
            // 透けて一瞬暗く沈む。遷移の外側に不透明なパール地を常駐させて防ぐ
            PearlBackground()

            switch coordinator.screen {
            case .camera:
                CameraView(onPhotoTaken: coordinator.didCapture)
                    .transition(.opacity)
            case .review:
                if let viewModel = coordinator.reviewViewModel {
                    ReviewView(
                        viewModel: viewModel,
                        onRetake: coordinator.retake,
                        onDone: coordinator.didFinishSaving
                    )
                    .transition(.opacity)
                }
            case .saved:
                if let saved = coordinator.savedPhoto {
                    SavedView(
                        photo: saved,
                        onBack: coordinator.backToEdit,
                        onShoot: coordinator.shootAgain
                    )
                    .transition(.opacity)
                }
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
