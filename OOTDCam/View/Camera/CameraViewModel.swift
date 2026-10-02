//
//  CameraViewModel.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI
import AVFoundation

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var isShutterAnimating: Bool = false
    @Published var showSparkles: Bool = false
    @Published var showFlash: Bool = false
    @Published var lastCapturedPhoto: CapturedPhoto?
    
    let service = CameraService()
    private let photoLibrary: PhotoLibrarySaving

    init(photoLibrary: PhotoLibrarySaving = PhotoLibraryService()) {
        self.photoLibrary = photoLibrary
    }


    // 権限状態
    private var cameraAuthorized = false
    private var photoLibraryAuthorized = false
    @Published var cameraPermissionDenied = false
    @Published var photoLibraryPermissionDenied = false
    
    enum Input {
        case onAppear
        case onDisappear
        case takePhoto(visibleRect: CGRect)
    }

    func send(_ input: Input) {
        switch input {
        case .onAppear:
            requestPermissionsAndStart()
        case .onDisappear:
            stop()
        case .takePhoto(let visibleRect):
            takePhoto(visibleRect: visibleRect)
        }
    }
    
    // MARK: - 権限チェック & セッション開始
    private func requestPermissionsAndStart() {
        // スクショモードはカメラを使わないので権限確認ごと省略 (ダイアログがスクショに写るのを防ぐ)
        guard !ScreenshotMode.isActive else { return }
        Task {
            // カメラ権限
            cameraAuthorized = await checkCameraPermission()
            guard cameraAuthorized else {
                cameraPermissionDenied = true
                return
            }
            
            // 写真ライブラリ権限
            photoLibraryAuthorized = await photoLibrary.requestAddPermission()
            guard photoLibraryAuthorized else {
                photoLibraryPermissionDenied = true
                return
            }
            
            // 両方OKならセッション開始 (固定されたままのプレビューが残っていたら解除)
            service.unfreezePreview()
            service.startSession()
        }
    }

    private func checkCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            // 完了ハンドラ版はバックグラウンドで呼ばれ、メインアクター上で書いたクロージャだと
            // Swift 6 の実行時アイソレーションチェックで落ちるため async 版を使う
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    private func stop() {
        service.stopSession()
    }
    
    private func takePhoto(visibleRect: CGRect) {
        // スクショモードは権限に依存しない (シミュレータで権限ダイアログを出さない)
        guard (cameraAuthorized && photoLibraryAuthorized) || ScreenshotMode.isActive else { return }

        // シャッター直後にプレビューを固定して「撮れた」を即座に見せる
        service.freezePreview()

        // 撮影処理 (保存はレビュー画面の DONE で行うため、ここでは保持のみ)
        Task {
            if let photo = await service.capturePhoto(visibleRectInLayer: visibleRect) {
                lastCapturedPhoto = photo
            } else {
                // 撮影失敗時はライブプレビューに戻して撮り直せるようにする
                service.unfreezePreview()
            }
        }

        playShutterEffects()
    }

    /// シャッター・フラッシュ・きらめきの演出。出すのは同時、戻すのは時間差
    private func playShutterEffects() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShutterAnimating = true
        }
        withAnimation {
            showSparkles = true
        }
        // フラッシュの膜 (素早く出て、ゆっくり消える)
        withAnimation(.easeOut(duration: 0.09)) {
            showFlash = true
        }

        Task {
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.easeOut(duration: 0.4)) { showFlash = false }

            try? await Task.sleep(for: .seconds(0.4))
            withAnimation { isShutterAnimating = false }

            // きらめきは SparkleOverlay の演出が 0.8 秒以内に収まる前提
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation { showSparkles = false }
        }
    }
}
