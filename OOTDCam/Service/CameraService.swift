//
//  CameraService.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import AVFoundation
import Photos
import UIKit

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var currentProcessors: [PhotoCaptureProcessor] = []
    
    override init() {
        super.init()
        configureSession()
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // カメラ入力
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)
        
        // 写真出力
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        var processor: PhotoCaptureProcessor!
        processor = PhotoCaptureProcessor(completion: { [weak self] image in
            completion(image)
            // 終わったら保持から削除
            self?.currentProcessors.removeAll { $0 === processor }
        })
        currentProcessors.append(processor) // 保持
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }
}

// MARK: - PhotoCaptureProcessor
private class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    /// AVFoundation のデリゲートキュー (バックグラウンド) で呼ばれる。
    /// 表示直前にメインスレッドで遅延デコードが走るのを避けるため、ここでデコード＆orientation正規化を完了させる。
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let raw = UIImage(data: data) else {
            completion(nil)
            return
        }
        let prepared = Self.decodeAndNormalize(raw)
        completion(prepared)
    }

    /// バックグラウンドでデコード＆orientation正規化を済ませる。出力は orientation = .up
    private static func decodeAndNormalize(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }
}
