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
        GeometryReader { geo in
            ZStack {
                // クロスフェード中は前後の画面が両方半透明になり、背後のウィンドウの地 (黒) が
                // 透けて一瞬暗く沈む。遷移の外側に不透明なパール地を常駐させて防ぐ
                PearlBackground()

                switch coordinator.screen {
                case .camera:
                    CameraView(
                        onPhotoTaken: coordinator.didCapture,
                        onPreviewWidthChanged: { coordinator.basePhotoWidth = $0 }
                    )
                    .transition(.opacity)
                case .review:
                    if let viewModel = coordinator.reviewViewModel {
                        ReviewView(
                            viewModel: viewModel,
                            basePhotoWidth: coordinator.basePhotoWidth,
                            onRetake: coordinator.retake,
                            onDone: coordinator.didFinishSaving
                        )
                        .transition(.opacity)
                    }
                case .saved:
                    if let saved = coordinator.savedPhoto {
                        SavedView(
                            photo: saved,
                            basePhotoWidth: coordinator.basePhotoWidth,
                            onBack: coordinator.backToEdit,
                            onShoot: coordinator.shootAgain
                        )
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: coordinator.screen)
            // アイランド/ノッチ端末は安全領域が帯の上に余白を残しすぎるので 6pt 食い込ませる。
            // SE 系 (安全領域トップ=ステータスバー20pt) は食い込むと時刻表示に重なるため何もしない。
            // 全画面共通に掛けるので、画面間でプレートの開始位置はずれない (#18)
            .padding(.top, geo.safeAreaInsets.top > 30 ? -6 : 0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
