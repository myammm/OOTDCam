//
//  ReviewViewModelTests.swift
//  OOTDCamTests
//

import Foundation
import Testing
import UIKit
@testable import OOTDCam

/// Photos に触らず、保存の呼び出し回数と失敗を制御するモック
actor MockPhotoLibrary: PhotoLibrarySaving {
    struct SaveError: LocalizedError {
        var errorDescription: String? { "mock failure" }
    }

    private(set) var saveCount = 0
    private var shouldFail = false

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func requestAddPermission() async -> Bool { true }

    func save(_ image: UIImage) async throws {
        if shouldFail { throw SaveError() }
        saveCount += 1
    }

    func save(contentsOf url: URL) async throws {
        if shouldFail { throw SaveError() }
        saveCount += 1
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
        if let url = photo?.fileURL {
            try? FileManager.default.removeItem(at: url)
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

        #expect(second != nil)
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
