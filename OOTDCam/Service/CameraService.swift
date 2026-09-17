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

    /// カメラ入力まで組めたときだけ true。シミュレータなどカメラを取れない環境では
    /// false のままにして startRunning を呼ばせない (未構成のまま呼ぶと NSGenericException で落ちる)
    private var isConfigured = false

    private func configureSession() {
        session.beginConfiguration()
        // 入力が取れず途中で抜ける場合も beginConfiguration を必ず閉じる
        defer { session.commitConfiguration() }
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

        isConfigured = true
    }

    /// startRunning / stopRunning はどちらも完了までブロックするので、
    /// メインスレッドでは呼ばず専用の直列キューで順序を保証して実行する
    private let sessionQueue = DispatchQueue(label: "jp.linqinc.OOTDCam.cameraSession")

    func startSession() {
        sessionQueue.async {
            if self.isConfigured && !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    /// プレビューを固定する (最後のフレームが表示されたまま止まる)。
    /// 撮影処理は端末を動かしていると多フレーム合成で1秒以上かかることがあるため、
    /// シャッター直後に呼んで「撮れた」フィードバックを即座に返す
    func freezePreview() {
        activePreviewLayer?.connection?.isEnabled = false
    }

    func unfreezePreview() {
        activePreviewLayer?.connection?.isEnabled = true
    }

    /// 撮影 + 「プレビュー上の可視矩形」だけクロップして返す
    /// - Parameter visibleRectInLayer: プレビューレイヤーのローカル座標での可視矩形
    ///   (プレビューがレイヤー全域を占める場合は origin .zero + レイヤーサイズ)
    func capturePhoto(
        visibleRectInLayer: CGRect,
        completion: @escaping (CapturedPhoto?) -> Void
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
            // クロップと表示用縮小はバックグラウンドで行う
            DispatchQueue.global(qos: .userInitiated).async {
                let cropped = image.flatMap { Self.cropByNormalizedSensorRect($0, normalizedRect: normalizedRect) } ?? image
                let photo = cropped.map {
                    CapturedPhoto(original: $0, display: ImageCompositor.displayImage(from: $0))
                }
                completion(photo)
            }
            // currentProcessors はメインでのみ触る (append もメインから)
            DispatchQueue.main.async {
                self?.currentProcessors.removeAll { $0 === processor }
            }
        })
        currentProcessors.append(processor)
        // デリゲートは capturePhoto を呼んだスレッドで呼ばれる。メインから呼ぶと
        // cgImageRepresentation() の写真デコードがメインで走り、動きのある撮影
        // (多フレーム合成で処理が重い) で実際にハングするため、必ず sessionQueue から投入する
        sessionQueue.async {
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
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
