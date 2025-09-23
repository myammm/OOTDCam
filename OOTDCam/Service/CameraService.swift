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
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let data = photo.fileDataRepresentation(),
           let image = UIImage(data: data) {
            completion(image)
        } else {
            completion(nil)
        }
    }
}
