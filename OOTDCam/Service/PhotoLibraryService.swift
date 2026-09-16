//
//  PhotoLibraryService.swift
//  OOTDCam
//

import Photos
import UIKit

/// 写真ライブラリの保存と権限確認の境界。
/// ViewModel は Photos に直接依存せず、このプロトコル越しに扱う (テスト時はモック差し替え)
protocol PhotoLibrarySaving {
    /// 追加専用 (.addOnly) 権限を確認し、未決定ならリクエストする
    func requestAddPermission() async -> Bool
    /// カメラロールへ保存する。失敗時は throw
    func save(_ image: UIImage) async throws
}

final class PhotoLibraryService: PhotoLibrarySaving {
    func requestAddPermission() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    continuation.resume(returning: newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func save(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
