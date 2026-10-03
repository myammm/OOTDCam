//
//  TestImages.swift
//  OOTDCamTests
//

import UIKit

/// テスト用の画像生成・ピクセル読み出しヘルパー
enum TestImages {
    /// 単色の画像を作る (scale 1 で描画し、指定の scale / orientation を付け直す)
    static func solid(
        _ color: UIColor,
        width: Int,
        height: Int,
        scale: CGFloat = 1,
        orientation: UIImage.Orientation = .up
    ) -> UIImage {
        split(left: color, right: color, width: width, height: height, scale: scale, orientation: orientation)
    }

    /// 左半分と右半分で色が違う画像を作る
    static func split(
        left: UIColor,
        right: UIColor,
        width: Int,
        height: Int,
        scale: CGFloat = 1,
        orientation: UIImage.Orientation = .up
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let size = CGSize(width: width, height: height)
        let base = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            left.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
            right.setFill()
            ctx.fill(CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height))
        }
        return UIImage(cgImage: base.cgImage!, scale: scale, orientation: orientation)
    }

    /// cgImage の生ピクセル寸法 (orientation 適用前)
    static func pixelSize(of image: UIImage) -> CGSize? {
        guard let cg = image.cgImage else { return nil }
        return CGSize(width: cg.width, height: cg.height)
    }
}

/// RGBA8 に展開したビットマップ。座標は左上原点
struct PixelBuffer {
    let width: Int
    let height: Int
    private let bytes: [UInt8]

    init?(_ image: UIImage) {
        guard let cg = image.cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        self.width = width
        self.height = height
        bytes = data
    }

    struct RGB: Equatable {
        let r: Int, g: Int, b: Int

        /// チャンネルごとの差の最大値 (色空間変換の丸め誤差を許容して比較するため)
        func distance(to other: RGB) -> Int {
            max(abs(r - other.r), abs(g - other.g), abs(b - other.b))
        }
    }

    func rgb(x: Int, y: Int) -> RGB {
        let i = (y * width + x) * 4
        return RGB(r: Int(bytes[i]), g: Int(bytes[i + 1]), b: Int(bytes[i + 2]))
    }
}
