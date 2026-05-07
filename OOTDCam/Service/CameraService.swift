//
//  CameraService.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import AVFoundation
import Photos
import UIKit
import ImageIO

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    weak var activePreviewLayer: AVCaptureVideoPreviewLayer?

    private var currentProcessors: [PhotoCaptureProcessor] = []

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)

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

    /// 撮影 + 「プレビュー上の可視矩形」だけクロップして返す
    /// - Parameter visibleRectInLayer: フルスクリーンプレビューレイヤー上の可視矩形 (= グローバル座標)
    func capturePhoto(
        visibleRectInLayer: CGRect,
        completion: @escaping (UIImage?) -> Void
    ) {
        // canonical な AVFoundation 変換: 各コーナーをセンサー正規化座標 [0,1]^2 に変換
        // (videoOrientation, gravity, scaling すべて内部で正しく扱ってくれる)
        let normalizedRect: CGRect
        if let layer = activePreviewLayer {
            let tl = layer.captureDevicePointConverted(fromLayerPoint: CGPoint(x: visibleRectInLayer.minX, y: visibleRectInLayer.minY))
            let br = layer.captureDevicePointConverted(fromLayerPoint: CGPoint(x: visibleRectInLayer.maxX, y: visibleRectInLayer.maxY))
            normalizedRect = CGRect(
                x: min(tl.x, br.x),
                y: min(tl.y, br.y),
                width: abs(br.x - tl.x),
                height: abs(br.y - tl.y)
            )
        } else {
            normalizedRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        let settings = AVCapturePhotoSettings()
        var processor: PhotoCaptureProcessor!
        processor = PhotoCaptureProcessor(completion: { [weak self] image in
            let cropped = image.flatMap { Self.cropByNormalizedSensorRect($0, normalizedRect: normalizedRect) } ?? image
            completion(cropped)
            self?.currentProcessors.removeAll { $0 === processor }
        })
        currentProcessors.append(processor)
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }

    /// `captureDevicePointConverted` が返すのは raw センサー (landscape) 座標系の正規化値。
    /// 撮影画像の cgImage も raw (landscape) なので、そのまま掛け算すれば pixel rect が得られる。
    /// 画像の orientation (.right 等) はクロップ後に維持する。
    static func cropByNormalizedSensorRect(_ image: UIImage, normalizedRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        var pixelRect = CGRect(
            x: normalizedRect.minX * w,
            y: normalizedRect.minY * h,
            width: normalizedRect.width * w,
            height: normalizedRect.height * h
        )
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        pixelRect = pixelRect.intersection(bounds)
        guard !pixelRect.isEmpty,
              let cropped = cgImage.cropping(to: pixelRect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - PhotoCaptureProcessor
private class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    /// AVFoundation のデリゲートキューで呼ばれる。
    /// JPEG/HEIC エンコード+デコードのラウンドトリップを避けるため、
    /// 直接 cgImageRepresentation() (=デコード済みの raw CGImage) を取得する。
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let cgImage = photo.cgImageRepresentation() {
            let exif = (photo.metadata[kCGImagePropertyOrientation as String] as? UInt32) ?? 1
            let orientation = Self.uiImageOrientation(exifValue: exif)
            completion(UIImage(cgImage: cgImage, scale: 1, orientation: orientation))
            return
        }
        // フォールバック (基本通らない)
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }

    private static func uiImageOrientation(exifValue: UInt32) -> UIImage.Orientation {
        switch exifValue {
        case 1: return .up
        case 2: return .upMirrored
        case 3: return .down
        case 4: return .downMirrored
        case 5: return .leftMirrored
        case 6: return .right
        case 7: return .rightMirrored
        case 8: return .left
        default: return .up
        }
    }
}
