//
//  CameraPreviewView.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var service: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: service.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.cornerRadius = 0
        previewLayer.masksToBounds = true
        view.layer.addSublayer(previewLayer)
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
