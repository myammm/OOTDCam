//
//  ReviewViewModel.swift
//  OOTDCam
//

import SwiftUI
import Photos

@MainActor
final class ReviewViewModel: ObservableObject {
    let originalImage: UIImage

    @Published var selectedShape: CoverShapeID = .heart
    @Published var selectedGradientID: String = "pink"
    @Published var sheer: Double = 0.55
    @Published var blur: Double = 12

    /// オーバーレイ中心座標 (写真エリア座標系)
    @Published var overlayCenter: CGPoint = .zero
    @Published var overlayScale: CGFloat = 0.5
    @Published var hasOverlay: Bool = true

    @Published var isSaving: Bool = false
    @Published var saveErrorMessage: String?

    private var hasInitializedPosition = false
    private let compositor = ImageCompositor()
    /// CoreImage 焼き込み用の orientation 正規化済み画像。初回 compose 時にバックグラウンドで生成
    private var cachedNormalizedImage: UIImage?

    var selectedGradient: CoverGradient {
        CoverPresets.gradient(id: selectedGradientID)
    }

    init(image: UIImage) {
        self.originalImage = image
    }

    // MARK: - Layout helpers

    /// aspectFit で表示される写真の矩形 (写真エリア座標系)
    func displayedPhotoRect(in areaSize: CGSize) -> CGRect {
        let imgSize = originalImage.size
        guard imgSize.width > 0, imgSize.height > 0,
              areaSize.width > 0, areaSize.height > 0 else { return .zero }
        let imageAspect = imgSize.width / imgSize.height
        let areaAspect = areaSize.width / areaSize.height
        if imageAspect > areaAspect {
            let h = areaSize.width / imageAspect
            return CGRect(x: 0, y: (areaSize.height - h) / 2, width: areaSize.width, height: h)
        } else {
            let w = areaSize.height * imageAspect
            return CGRect(x: (areaSize.width - w) / 2, y: 0, width: w, height: areaSize.height)
        }
    }

    /// 表示用シェイプサイズ (nominal × scale)
    func displayedShapeSize(in areaSize: CGSize) -> CGSize {
        let nominal = selectedShape.nominalSize
        return CGSize(width: nominal.width * overlayScale, height: nominal.height * overlayScale)
    }

    func initializePositionIfNeeded(areaSize: CGSize) {
        guard !hasInitializedPosition else { return }
        let rect = displayedPhotoRect(in: areaSize)
        overlayCenter = CGPoint(x: rect.midX, y: rect.midY)
        hasInitializedPosition = true
    }

    // MARK: - User actions

    func selectShape(_ shape: CoverShapeID, areaSize: CGSize) {
        selectedShape = shape
        if !hasOverlay {
            hasOverlay = true
            let rect = displayedPhotoRect(in: areaSize)
            overlayCenter = CGPoint(x: rect.midX, y: rect.midY)
        }
    }

    func selectGradient(id: String, areaSize: CGSize) {
        selectedGradientID = id
        if !hasOverlay {
            hasOverlay = true
            let rect = displayedPhotoRect(in: areaSize)
            overlayCenter = CGPoint(x: rect.midX, y: rect.midY)
        }
    }

    func translate(to point: CGPoint) {
        overlayCenter = point
    }

    func adjustScale(by delta: CGFloat) {
        overlayScale = max(0.4, min(2.0, overlayScale + delta))
    }

    func setScale(_ scale: CGFloat) {
        overlayScale = max(0.4, min(2.0, scale))
    }

    func removeOverlay() {
        hasOverlay = false
    }

    // MARK: - Save

    func compositeAndSave(areaSize: CGSize) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        // orientation 正規化はバックグラウンドで一度だけ
        let normalized = await ensureNormalizedImage()

        let imageToSave: UIImage?
        if hasOverlay {
            imageToSave = composeImage(normalized: normalized, areaSize: areaSize)
        } else {
            imageToSave = normalized
        }

        guard let image = imageToSave else {
            saveErrorMessage = "画像の合成に失敗しました"
            return false
        }

        return await saveToPhotoLibrary(image)
    }

    private func ensureNormalizedImage() async -> UIImage {
        if let cached = cachedNormalizedImage { return cached }
        // CameraService 側でバックグラウンド処理済みなら即返す
        if originalImage.imageOrientation == .up {
            cachedNormalizedImage = originalImage
            return originalImage
        }
        // フォールバック (ライブラリ画像など orientation が .up でない場合)
        let image = originalImage
        let normalized = await Task.detached(priority: .userInitiated) {
            ImageCompositor.normalizedOrientation(image)
        }.value
        cachedNormalizedImage = normalized
        return normalized
    }

    private func composeImage(normalized: UIImage, areaSize: CGSize) -> UIImage? {
        let displayed = displayedPhotoRect(in: areaSize)
        guard displayed.width > 0, displayed.height > 0 else { return nil }

        let displayedShape = displayedShapeSize(in: areaSize)

        // 写真エリア座標 → 表示写真座標
        let centerInPhoto = CGPoint(
            x: overlayCenter.x - displayed.origin.x,
            y: overlayCenter.y - displayed.origin.y
        )

        // 表示 (pt) → オリジナル画像 (pt)
        let imgPointSize = normalized.size
        let scaleX = imgPointSize.width / displayed.width
        let scaleY = imgPointSize.height / displayed.height
        let originalCenterPt = CGPoint(
            x: centerInPhoto.x * scaleX,
            y: centerInPhoto.y * scaleY
        )
        let originalShapePt = CGSize(
            width: displayedShape.width * scaleX,
            height: displayedShape.height * scaleY
        )

        // pt → ピクセル
        let imageScale = normalized.scale
        let originalRectPx = CGRect(
            x: (originalCenterPt.x - originalShapePt.width / 2) * imageScale,
            y: (originalCenterPt.y - originalShapePt.height / 2) * imageScale,
            width: originalShapePt.width * imageScale,
            height: originalShapePt.height * imageScale
        )

        // ぼかし半径もピクセル基準に
        let avgScale = (scaleX + scaleY) / 2 * imageScale
        let blurRadiusPx = blur * Double(avgScale)

        return compositor.compose(
            original: normalized,
            shape: selectedShape,
            gradient: selectedGradient,
            sheer: sheer,
            blurRadius: blurRadiusPx,
            overlayRectInOriginal: originalRectPx
        )
    }

    private func saveToPhotoLibrary(_ image: UIImage) async -> Bool {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            return true
        } catch {
            saveErrorMessage = "写真保存に失敗: \(error.localizedDescription)"
            return false
        }
    }
}
