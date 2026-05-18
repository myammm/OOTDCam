//
//  BlurView.swift
//  OOTDCam
//

import SwiftUI
import UIKit

/// SwiftUI の Material は UIKit ホストのビュー (AVCaptureVideoPreviewLayer など) の中身をブラーできないため、
/// UIVisualEffectView をラップして UIKit レベルでブラーをかける。
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
