//
//  ReviewViewModel.swift
//  OOTDCam
//

import SwiftUI

@MainActor
final class ReviewViewModel: ObservableObject {
    /// 保存 (焼き込み) 用のフル解像度画像。メインスレッドでは描画しない
    let originalImage: UIImage

    /// プレビュー表示用の軽量画像 (orientation .up・縮小済み)。撮影直後にバックグラウンドで生成済み。
    /// フル解像度や orientation 付きのまま blur + mask に載せるとハング・ずれの原因になる
    let displayImage: UIImage

    @Published var selectedShape: CoverShapeID = .heart
    @Published var selectedGradientID: String = "pink"
    @Published var sheer: Double = 0.55
    @Published var blur: Double = 12

    /// オーバーレイ中心座標 (写真エリア座標系)
    @Published var overlayCenter: CGPoint = .zero
    /// 初期値 0.35 は撮影ガイドのハート (72pt 幅) とほぼ同寸 (200 × 0.35 = 70pt)
    @Published var overlayScale: CGFloat = 0.35
    /// 起動時はカバーなし。ユーザーがシェイプを選んで初めて表示される
    @Published var hasOverlay: Bool = false

    /// 保存画像に日付スタンプを焼き込むか
    @Published var includeDateStamp: Bool = true

    @Published var isSaving: Bool = false
    @Published var saveErrorMessage: String?

    /// 撮影時刻 (プレビューと保存で同じ日付を出すために固定)
    let capturedDate: Date = Date()

    private var hasInitializedPosition = false
    private let compositor = ImageCompositor()
    private let photoLibrary: PhotoLibrarySaving
    /// CoreImage 焼き込み用の orientation 正規化済み画像。初回 compose 時にバックグラウンドで生成
    private var cachedNormalizedImage: UIImage?

    /// 保存済み判定用の編集状態スナップショット。
    /// 保存完了画面から「戻る」→ 編集せずに再度「完了」を押したとき、
    /// 同じ写真をカメラロールに2枚保存しないために使う
    private struct EditFingerprint: Equatable {
        var hasOverlay: Bool
        var shape: CoverShapeID
        var gradientID: String
        var sheer: Double
        var blur: Double
        var center: CGPoint
        var scale: CGFloat
        var includeDateStamp: Bool
    }

    private var currentFingerprint: EditFingerprint {
        EditFingerprint(
            hasOverlay: hasOverlay,
            shape: selectedShape,
            gradientID: selectedGradientID,
            sheer: sheer,
            blur: blur,
            center: overlayCenter,
            scale: overlayScale,
            includeDateStamp: includeDateStamp
        )
    }

    /// 直近にカメラロールへ保存した編集状態とその結果
    private var lastSaved: (fingerprint: EditFingerprint, photo: SavedPhoto)?

    var selectedGradient: CoverGradient {
        CoverPresets.gradient(id: selectedGradientID)
    }

    init(photo: CapturedPhoto, photoLibrary: PhotoLibrarySaving = PhotoLibraryService()) {
        self.originalImage = photo.original
        self.displayImage = photo.display
        self.photoLibrary = photoLibrary
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
            // OFF → ON のときは位置とサイズを維持して復帰させる
            // 位置は initializePositionIfNeeded で初回設定済み
            hasOverlay = true
        }
    }

    /// OFF ボタン用: オーバーレイを非表示にする
    func disableOverlay() {
        hasOverlay = false
    }

    func selectGradient(id: String, areaSize: CGSize) {
        selectedGradientID = id
        // gradient のタップでは overlay を勝手に出さない (OFF 状態を尊重)
    }

    func translate(to point: CGPoint) {
        overlayCenter = point
    }

    /// サイズの段階。顔を隠す用途なので大きくはせず、小さい側は細かく刻む
    private static let scaleLevels: [CGFloat] = [0.2, 0.275, 0.35, 0.5, 0.65]

    /// 現在値に最も近い段階の index (overlayScale は常に段階上の値だが誤差を許容)
    private var scaleIndex: Int {
        Self.scaleLevels.enumerated().min { abs($0.element - overlayScale) < abs($1.element - overlayScale) }!.offset
    }

    /// ±ボタンの活性判定 (端に到達したら無効)
    var canScaleUp: Bool { scaleIndex < Self.scaleLevels.count - 1 }
    var canScaleDown: Bool { scaleIndex > 0 }

    /// direction: +1 で一段大きく、-1 で一段小さく
    func stepScale(_ direction: Int) {
        let index = min(max(scaleIndex + direction, 0), Self.scaleLevels.count - 1)
        overlayScale = Self.scaleLevels[index]
    }

    func removeOverlay() {
        hasOverlay = false
    }

    // MARK: - Save

    /// 合成してカメラロールへ保存し、保存完了画面用の SavedPhoto を返す。失敗時は nil。
    /// 前回保存時から編集内容が変わっていなければ、保存をスキップして前回の結果を返す
    /// (「戻る」→「完了」の繰り返しで同じ写真が重複保存されるのを防ぐ)
    func compositeAndSave(areaSize: CGSize) async -> SavedPhoto? {
        if let last = lastSaved, last.fingerprint == currentFingerprint {
            return last.photo
        }

        isSaving = true
        defer { isSaving = false }

        let fingerprint = currentFingerprint

        // orientation 正規化はバックグラウンドで一度だけ
        let normalized = await ensureNormalizedImage()

        var imageToSave: UIImage?
        if hasOverlay {
            imageToSave = composeImage(normalized: normalized, areaSize: areaSize)
        } else {
            imageToSave = normalized
        }

        // 日付スタンプ焼き込み (ON のとき)
        if includeDateStamp, let img = imageToSave {
            imageToSave = ImageCompositor.drawDateStamp(on: img, date: capturedDate)
        }

        guard let image = imageToSave else {
            saveErrorMessage = "画像の合成に失敗しました"
            return nil
        }

        // エンコードは 1 回だけ: 先に JPEG をファイル化し、同じファイルを
        // カメラロール保存と共有シートの両方に使う。表示用の縮小も同じ裏時間で
        // (フル解像度をメインスレッドで描画・エンコードするとハングする)
        let date = capturedDate
        let (display, fileURL) = await Task.detached(priority: .userInitiated) {
            (ImageCompositor.displayImage(from: image),
             ImageCompositor.writeJPEG(image, date: date))
        }.value

        if let fileURL {
            guard await saveToPhotoLibrary(contentsOf: fileURL) else { return nil }
        } else {
            // ファイル化に失敗したときだけ iOS 側エンコードで保存自体は成立させる
            guard await saveToPhotoLibrary(image) else { return nil }
        }

        let saved = SavedPhoto(display: display, fileURL: fileURL)
        lastSaved = (fingerprint, saved)
        return saved
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
            try await photoLibrary.save(image)
            return true
        } catch {
            saveErrorMessage = "写真保存に失敗: \(error.localizedDescription)"
            return false
        }
    }

    private func saveToPhotoLibrary(contentsOf url: URL) async -> Bool {
        do {
            try await photoLibrary.save(contentsOf: url)
            return true
        } catch {
            saveErrorMessage = "写真保存に失敗: \(error.localizedDescription)"
            return false
        }
    }
}
