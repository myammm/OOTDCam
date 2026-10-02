//
//  CameraPreviewView.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let service: CameraService
    var gravity: AVLayerVideoGravity = .resizeAspect
    /// 撮影時のクロップ計算用にレイヤーを CameraService に登録するか
    var registerForCapture: Bool = true

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: service.session)
        previewLayer.videoGravity = gravity
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer
        if registerForCapture {
            service.activePreviewLayer = previewLayer
        }
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer?.videoGravity = gravity
        if registerForCapture, let layer = uiView.previewLayer {
            service.activePreviewLayer = layer
        }
    }
}

/// previewLayer の frame をレイアウト変更時に追従させる
final class PreviewContainerView: UIView {
    weak var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
