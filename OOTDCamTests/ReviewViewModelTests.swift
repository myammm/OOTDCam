//
//  ReviewViewModelTests.swift
//  OOTDCamTests
//

import Foundation
import Testing
import UIKit
@testable import OOTDCam

/// Photos に触らず、保存の呼び出しと失敗を制御するモック
actor MockPhotoLibrary: PhotoLibrarySaving {
    struct SaveError: LocalizedError {
        var errorDescription: String? { "mock failure" }
    }

    /// save(contentsOf:) で渡されたファイル
    private(set) var savedFileURLs: [URL] = []
    /// save(_:) (iOS 側で再エンコードする経路) の呼び出し回数
    private(set) var savedImageCount = 0
    private var shouldFail = false

    var saveCount: Int { savedFileURLs.count + savedImageCount }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func requestAddPermission() async -> Bool { true }

    func save(_ image: UIImage) async throws {
        if shouldFail { throw SaveError() }
        savedImageCount += 1
    }

    func save(contentsOf url: URL) async throws {
        if shouldFail { throw SaveError() }
        savedFileURLs.append(url)
    }
}

@MainActor
struct ReviewViewModelTests {
    private let areaSize = CGSize(width: 300, height: 400)

    private func makeViewModel(
        width: Int = 300,
        height: Int = 400,
        photoLibrary: PhotoLibrarySaving
    ) -> ReviewViewModel {
        let image = TestImages.solid(.gray, width: width, height: height)
        return ReviewViewModel(photo: CapturedPhoto(original: image, display: image), photoLibrary: photoLibrary)
    }

    private func removeTemporaryFile(of photo: SavedPhoto?) {
        // writeJPEG は書き出しごとのディレクトリに置くので、ディレクトリごと消す
        if let url = photo?.fileURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
    }

    // MARK: - 保存済み判定

    @Test func 編集せずに再保存しても重複保存せず前回の結果を返す() async throws {
        let library = MockPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library)

        let first = try #require(await viewModel.compositeAndSave(areaSize: areaSize))
        defer { removeTemporaryFile(of: first) }
        let second = await viewModel.compositeAndSave(areaSize: areaSize)

        #expect(second == first)
        #expect(await library.saveCount == 1)
    }

    @Test func 保存後に編集すると再保存する() async throws {
        let library = MockPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library)

        let first = await viewModel.compositeAndSave(areaSize: areaSize)
        defer { removeTemporaryFile(of: first) }
        viewModel.includeDateStamp.toggle()
        let second = await viewModel.compositeAndSave(areaSize: areaSize)
        defer { removeTemporaryFile(of: second) }

        let firstURL = try #require(first?.fileURL)
        let secondURL = try #require(second?.fileURL)
        #expect(firstURL != secondURL)
        #expect(FileManager.default.fileExists(atPath: firstURL.path))
        #expect(await library.saveCount == 2)
    }

    /// 「編集したか」ではなく「保存時と同じ状態か」で判定する
    @Test func 編集して元に戻した場合は保存済みとみなす() async throws {
        let library = MockPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library)

        let first = await viewModel.compositeAndSave(areaSize: areaSize)
        defer { removeTemporaryFile(of: first) }
        let originalSheer = viewModel.sheer
        viewModel.sheer = 0.9
        viewModel.sheer = originalSheer
        let second = await viewModel.compositeAndSave(areaSize: areaSize)

        #expect(second == first)
        #expect(await library.saveCount == 1)
    }

    @Test func 保存に失敗したらnilを返し次回は再試行する() async throws {
        let library = MockPhotoLibrary()
        await library.setShouldFail(true)
        let viewModel = makeViewModel(photoLibrary: library)

        let failed = await viewModel.compositeAndSave(areaSize: areaSize)

        #expect(failed == nil)
        #expect(viewModel.saveErrorMessage != nil)
        #expect(viewModel.isSaving == false)

        await library.setShouldFail(false)
        let retried = await viewModel.compositeAndSave(areaSize: areaSize)
        defer { removeTemporaryFile(of: retried) }

        #expect(retried != nil)
        #expect(await library.saveCount == 1)
    }

    @Test func カバーありでも合成して保存できる() async throws {
        let library = MockPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library)
        viewModel.initializePositionIfNeeded(areaSize: areaSize)
        viewModel.selectShape(.heart, areaSize: areaSize)

        let saved = try #require(await viewModel.compositeAndSave(areaSize: areaSize))
        defer { removeTemporaryFile(of: saved) }

        #expect(saved.display.size == CGSize(width: 300, height: 400))
        #expect(await library.saveCount == 1)
    }

    /// エンコードは 1 回だけ: カメラロールには書き出した JPEG をそのまま渡し、共有用にも同じファイルを返す
    @Test func 書き出したファイルをそのままカメラロールに保存し共有にも使う() async throws {
        let library = MockPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library)

        let saved = try #require(await viewModel.compositeAndSave(areaSize: areaSize))
        defer { removeTemporaryFile(of: saved) }

        let fileURL = try #require(saved.fileURL)
        #expect(await library.savedFileURLs == [fileURL])
        #expect(await library.savedImageCount == 0)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    /// 写真エリア座標 → 元画像ピクセル座標の変換を、保存された画像の画素で確かめる。
    /// 元画像 600×800 を 300×500 のエリアに表示すると、上下に 50pt ずつ余白ができ、1pt = 2px になる
    @Test func カバーは表示位置に対応する元画像の位置に焼き込まれる() async throws {
        let gray = PixelBuffer.RGB(r: 128, g: 128, b: 128)
        let image = TestImages.solid(UIColor(white: 128.0 / 255.0, alpha: 1), width: 600, height: 800)
        let library = MockPhotoLibrary()
        let viewModel = ReviewViewModel(photo: CapturedPhoto(original: image, display: image), photoLibrary: library)
        let area = CGSize(width: 300, height: 500)
        viewModel.selectShape(.star, areaSize: area)
        viewModel.sheer = 1
        viewModel.blur = 0
        viewModel.includeDateStamp = false
        // 表示写真の左上寄り (写真内 60, 100pt) → 元画像 (120, 200px)
        viewModel.translate(to: CGPoint(x: 60, y: 150))

        let saved = try #require(await viewModel.compositeAndSave(areaSize: area))
        defer { removeTemporaryFile(of: saved) }

        let fileURL = try #require(saved.fileURL)
        let written = try #require(UIImage(contentsOfFile: fileURL.path))
        let pixels = try #require(PixelBuffer(written))
        #expect(pixels.width == 600 && pixels.height == 800)
        // JPEG の圧縮誤差があるので許容幅は広めに取る
        #expect(pixels.rgb(x: 120, y: 200).distance(to: gray) > 20)
        // 余白分 (50pt = 100px) のずれや縦横の取り違えがあると、ここに色が乗る / 中心から外れる
        #expect(pixels.rgb(x: 120, y: 300).distance(to: gray) <= 8)
        #expect(pixels.rgb(x: 200, y: 120).distance(to: gray) <= 8)
        #expect(pixels.rgb(x: 480, y: 600).distance(to: gray) <= 8)
    }

    // MARK: - サイズの段階

    @Test func サイズは段階ごとに上下し端で止まる() {
        let viewModel = makeViewModel(photoLibrary: MockPhotoLibrary())
        #expect(viewModel.overlayScale == 0.35)

        viewModel.stepScale(1)
        viewModel.stepScale(1)
        #expect(viewModel.overlayScale == 0.65)
        #expect(viewModel.canScaleUp == false)

        viewModel.stepScale(1)
        #expect(viewModel.overlayScale == 0.65)

        for _ in 0..<5 { viewModel.stepScale(-1) }
        #expect(viewModel.overlayScale == 0.2)
        #expect(viewModel.canScaleDown == false)
        #expect(viewModel.canScaleUp)
    }

    // MARK: - レイアウト

    @Test func 横長の写真は上下に余白を空けて表示する() {
        let viewModel = makeViewModel(width: 400, height: 300, photoLibrary: MockPhotoLibrary())

        #expect(viewModel.displayedPhotoRect(in: CGSize(width: 300, height: 400)) == CGRect(x: 0, y: 87.5, width: 300, height: 225))
    }

    @Test func 縦長の写真は左右に余白を空けて表示する() {
        let viewModel = makeViewModel(width: 300, height: 400, photoLibrary: MockPhotoLibrary())

        #expect(viewModel.displayedPhotoRect(in: CGSize(width: 400, height: 400)) == CGRect(x: 50, y: 0, width: 300, height: 400))
    }

    @Test func 表示エリアが空なら矩形も空() {
        let viewModel = makeViewModel(photoLibrary: MockPhotoLibrary())

        #expect(viewModel.displayedPhotoRect(in: .zero) == .zero)
    }

    @Test func 初期位置は写真の中央に一度だけ設定する() {
        let viewModel = makeViewModel(photoLibrary: MockPhotoLibrary())

        viewModel.initializePositionIfNeeded(areaSize: CGSize(width: 300, height: 400))
        #expect(viewModel.overlayCenter == CGPoint(x: 150, y: 200))

        viewModel.initializePositionIfNeeded(areaSize: CGSize(width: 600, height: 800))
        #expect(viewModel.overlayCenter == CGPoint(x: 150, y: 200))
    }
}
