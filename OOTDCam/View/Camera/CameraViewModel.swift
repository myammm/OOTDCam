//
//  CameraViewModel.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI

final class CameraViewModel: ObservableObject {
    @Published var isShutterAnimating: Bool = false
    @Published var showSparkles: Bool = false
    
    func takePhoto() {
        // 撮影処理 (ここではダミー)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShutterAnimating = true
        }
        
        // シャッターアニメーション後に戻す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                self.isShutterAnimating = false
            }
        }
        
        // きらめき演出をトリガー
        withAnimation {
            showSparkles = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                self.showSparkles = false
            }
        }
    }
}
