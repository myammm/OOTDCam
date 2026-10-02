//
//  PhotoLibraryService.swift
//  OOTDCam
//

import Photos
import UIKit

/// 写真ライブラリの保存と権限確認の境界。
/// ViewModel は Photos に直接依存せず、このプロトコル越しに扱う (テスト時はモック差し替え)
protocol PhotoLibrarySaving: Sendable {
    /// 追加専用 (.addOnly) 権限を確認し、未決定ならリクエストする
    func requestAddPermission() async -> Bool
    /// カメラロールへ保存する。iOS 側で再エンコードされるため、
    /// エンコード済みファイルがあるときは save(contentsOf:) を使う。失敗時は throw
    func save(_ image: UIImage) async throws
    /// エンコード済み画像ファイルをそのまま (再エンコードなしで) カメラロールへ保存する。
    /// ファイルはコピーされるので呼び出し後も残る。失敗時は throw
    func save(contentsOf url: URL) async throws
}

final class PhotoLibraryService: PhotoLibrarySaving {
    func requestAddPermission() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return newStatus == .authorized || newStatus == .limited
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

    func save(contentsOf url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: url, options: nil)
        }
    }
}
