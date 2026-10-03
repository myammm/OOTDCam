//
//  ImageCompositorTests.swift
//  OOTDCamTests
//

import Testing
import UIKit
@testable import OOTDCam

struct ImageCompositorTests {
    // MARK: - displayImage

    @Test func displayImageは長辺を上限まで縮小する() {
        let image = TestImages.solid(.gray, width: 3200, height: 2400)

        let display = ImageCompositor.displayImage(from: image, maxLongSide: 1600)

        #expect(display.size == CGSize(width: 1600, height: 1200))
        #expect(display.scale == 1)
    }

    @Test func displayImageはscaleを考慮したピクセル寸法で縮小する() {
        let image = TestImages.solid(.gray, width: 3000, height: 3000, scale: 3)

        let display = ImageCompositor.displayImage(from: image, maxLongSide: 1600)

        #expect(display.size == CGSize(width: 1600, height: 1600))
        #expect(display.scale == 1)
    }

    @Test func displayImageは小さいup画像ならそのまま返す() {
        let image = TestImages.solid(.gray, width: 800, height: 600)

        let display = ImageCompositor.displayImage(from: image, maxLongSide: 1600)

        #expect(display === image)
    }

    @Test func displayImageは小さくてもorientationをupに正規化する() {
        let image = TestImages.solid(.gray, width: 400, height: 300, orientation: .right)

        let display = ImageCompositor.displayImage(from: image, maxLongSide: 1600)

        #expect(display.imageOrientation == .up)
        #expect(display.size == CGSize(width: 300, height: 400))
        #expect(TestImages.pixelSize(of: display) == CGSize(width: 300, height: 400))
    }

    // MARK: - normalizedOrientation

    @Test func normalizedOrientationはup画像をそのまま返す() {
        let image = TestImages.solid(.gray, width: 400, height: 300)

        #expect(ImageCompositor.normalizedOrientation(image) === image)
    }

    @Test func normalizedOrientationは回転を焼き込んでupにする() {
        let image = TestImages.solid(.gray, width: 400, height: 300, orientation: .right)

        let normalized = ImageCompositor.normalizedOrientation(image)

        #expect(normalized.imageOrientation == .up)
        #expect(TestImages.pixelSize(of: normalized) == CGSize(width: 300, height: 400))
    }

    // MARK: - writeJPEG

    @Test func writeJPEGは撮影日時入りのファイル名で書き出す() throws {
        let image = TestImages.solid(.gray, width: 40, height: 30)
        let date = try #require(
            Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 3, minute: 4, second: 5))
        )

        let url = try #require(ImageCompositor.writeJPEG(image, date: date))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(url.lastPathComponent == "figcam_20260102_030405.jpg")
        let decoded = try #require(UIImage(contentsOfFile: url.path))
        #expect(TestImages.pixelSize(of: decoded) == CGSize(width: 40, height: 30))
    }

    /// 同じ秒の撮影や編集後の再保存でも、前に書き出したファイルを上書きしない
    @Test func writeJPEGは同じ日時でも別のファイルに書き出す() throws {
        let date = Date()

        let first = try #require(ImageCompositor.writeJPEG(TestImages.solid(.black, width: 40, height: 30), date: date))
        defer { try? FileManager.default.removeItem(at: first.deletingLastPathComponent()) }
        let second = try #require(ImageCompositor.writeJPEG(TestImages.solid(.white, width: 40, height: 30), date: date))
        defer { try? FileManager.default.removeItem(at: second.deletingLastPathComponent()) }

        #expect(first != second)
        #expect(first.lastPathComponent == second.lastPathComponent)
        let firstPixels = try #require(UIImage(contentsOfFile: first.path).flatMap(PixelBuffer.init))
        #expect(firstPixels.rgb(x: 20, y: 15).distance(to: .init(r: 0, g: 0, b: 0)) <= 8)
    }

    // MARK: - drawDateStamp

    @Test func drawDateStampは寸法を変えず右下にだけ描く() throws {
        let image = TestImages.solid(.black, width: 360, height: 360)

        let stamped = ImageCompositor.drawDateStamp(on: image, date: Date())

        #expect(stamped.size == image.size)
        #expect(stamped.scale == image.scale)

        let pixels = try #require(PixelBuffer(stamped))
        let black = PixelBuffer.RGB(r: 0, g: 0, b: 0)
        // 右下の一帯 (文字＋グロウが乗る範囲) とそれ以外に分けて確かめる
        let stampArea = CGRect(x: 240, y: 300, width: 120, height: 60)
        var hasInk = false
        var inkOutsideStampArea = false
        for y in 0..<pixels.height {
            for x in 0..<pixels.width where pixels.rgb(x: x, y: y).distance(to: black) > 2 {
                if stampArea.contains(CGPoint(x: x, y: y)) {
                    hasInk = true
                } else {
                    inkOutsideStampArea = true
                }
            }
        }
        #expect(hasInk)
        #expect(!inkOutsideStampArea)
    }

    // MARK: - compose

    @Test func composeはシェイプの内側だけ塗り外側は元画像のまま残す() throws {
        let gray = PixelBuffer.RGB(r: 128, g: 128, b: 128)
        let image = TestImages.solid(UIColor(white: 128.0 / 255.0, alpha: 1), width: 200, height: 200)

        let composed = try #require(ImageCompositor().compose(
            original: image,
            shape: .star,
            gradient: CoverPresets.gradient(id: "pink"),
            sheer: 1,
            blurRadius: 0,
            overlayRectInOriginal: CGRect(x: 50, y: 50, width: 100, height: 100)
        ))

        #expect(TestImages.pixelSize(of: composed) == CGSize(width: 200, height: 200))
        #expect(composed.imageOrientation == .up)

        let pixels = try #require(PixelBuffer(composed))
        #expect(pixels.rgb(x: 100, y: 100).distance(to: gray) > 20)
        #expect(pixels.rgb(x: 5, y: 5).distance(to: gray) <= 2)
        #expect(pixels.rgb(x: 194, y: 194).distance(to: gray) <= 2)
    }

    @Test func composeはsheer0ならぼかしだけをシェイプ内にかける() throws {
        // 左黒・右白の境界をシェイプ中心に置くと、ぼかしで中心が中間色になる
        let image = TestImages.split(left: .black, right: .white, width: 200, height: 200)

        let composed = try #require(ImageCompositor().compose(
            original: image,
            shape: .star,
            gradient: CoverPresets.gradient(id: "pink"),
            sheer: 0,
            blurRadius: 20,
            overlayRectInOriginal: CGRect(x: 50, y: 50, width: 100, height: 100)
        ))

        let pixels = try #require(PixelBuffer(composed))
        let center = pixels.rgb(x: 100, y: 100)
        #expect((40...215).contains(center.r))
        // シェイプ外の境界付近はぼけない
        #expect(pixels.rgb(x: 98, y: 5).distance(to: .init(r: 0, g: 0, b: 0)) <= 2)
        #expect(pixels.rgb(x: 101, y: 5).distance(to: .init(r: 255, g: 255, b: 255)) <= 2)
    }
}
