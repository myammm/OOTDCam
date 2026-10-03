//
//  CropByNormalizedSensorRectTests.swift
//  OOTDCamTests
//

import Testing
import UIKit
@testable import OOTDCam

struct CropByNormalizedSensorRectTests {
    @Test func 正規化矩形をピクセル矩形に換算して切り出す() throws {
        let image = TestImages.solid(.gray, width: 400, height: 300)

        let cropped = try #require(
            CameraService.cropByNormalizedSensorRect(image, normalizedRect: CGRect(x: 0.25, y: 0.5, width: 0.5, height: 0.5))
        )

        #expect(TestImages.pixelSize(of: cropped) == CGSize(width: 200, height: 150))
    }

    @Test func 指定した範囲の中身が切り出される() throws {
        let image = TestImages.split(left: .red, right: .blue, width: 400, height: 300)

        let cropped = try #require(
            CameraService.cropByNormalizedSensorRect(image, normalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
        )

        let pixels = try #require(PixelBuffer(cropped))
        let blue = PixelBuffer.RGB(r: 0, g: 0, b: 255)
        #expect(pixels.rgb(x: 0, y: 0).distance(to: blue) <= 2)
        #expect(pixels.rgb(x: pixels.width - 1, y: pixels.height - 1).distance(to: blue) <= 2)
    }

    /// cgImage は raw (landscape) のまま切り出し、orientation と scale は元画像を引き継ぐ
    @Test func orientationとscaleを維持する() throws {
        let image = TestImages.solid(.gray, width: 400, height: 300, scale: 3, orientation: .right)

        let cropped = try #require(
            CameraService.cropByNormalizedSensorRect(image, normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 1))
        )

        #expect(cropped.imageOrientation == .right)
        #expect(cropped.scale == 3)
        #expect(TestImages.pixelSize(of: cropped) == CGSize(width: 200, height: 300))
    }

    @Test func 画像外にはみ出した分は画像内に収める() throws {
        let image = TestImages.solid(.gray, width: 400, height: 300)

        let cropped = try #require(
            CameraService.cropByNormalizedSensorRect(image, normalizedRect: CGRect(x: 0.5, y: 0.5, width: 1, height: 1))
        )

        #expect(TestImages.pixelSize(of: cropped) == CGSize(width: 200, height: 150))
    }

    @Test func 画像と重ならない矩形なら元画像をそのまま返す() {
        let image = TestImages.solid(.gray, width: 400, height: 300)

        let result = CameraService.cropByNormalizedSensorRect(image, normalizedRect: CGRect(x: 2, y: 2, width: 1, height: 1))

        #expect(result === image)
    }

    @Test func cgImageを持たない画像は元画像をそのまま返す() {
        let image = UIImage(ciImage: CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10)))

        let result = CameraService.cropByNormalizedSensorRect(image, normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

        #expect(result === image)
    }
}
