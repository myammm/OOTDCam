//
//  ImageCompositor.swift
//  OOTDCam
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// 撮影画像にカバー (ぼかし＋グラデ) を焼き込む
final class ImageCompositor {
    private let context = CIContext()

    /// 画像の orientation を up に正規化する。CIImage は exif orientation を自動で考慮しないので必須
    static func normalizedOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// - Parameters:
    ///   - original: 撮影直後の画像 (orientation は事前正規化済み想定)
    ///   - shape: カバーシェイプ
    ///   - gradient: グラデプリセット
    ///   - sheer: 0..1 グラデ不透明度
    ///   - blurRadius: オリジナル画像ピクセル空間でのガウシアンブラー半径
    ///   - overlayRectInOriginal: シェイプ外接矩形 (originalピクセル空間, 左上原点 y-down)
    func compose(
        original: UIImage,
        shape: CoverShapeID,
        gradient: CoverGradient,
        sheer: CGFloat,
        blurRadius: CGFloat,
        overlayRectInOriginal: CGRect
    ) -> UIImage? {
        guard let cgImage = original.cgImage else { return nil }
        let canvasSize = CGSize(width: cgImage.width, height: cgImage.height)
        let ciOriginal = CIImage(cgImage: cgImage)
        let extent = ciOriginal.extent

        guard let maskCG = makeShapeMask(shape: shape, overlayRect: overlayRectInOriginal, canvasSize: canvasSize) else {
            return nil
        }
        let ciMask = CIImage(cgImage: maskCG)

        // (1) 全体ぼかし → シェイプ範囲だけブレンドで戻す
        let withBlur: CIImage
        if blurRadius > 0 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = ciOriginal.clampedToExtent()
            blur.radius = Float(blurRadius)
            let blurred = (blur.outputImage ?? ciOriginal).cropped(to: extent)

            let blendBlur = CIFilter.blendWithMask()
            blendBlur.inputImage = blurred
            blendBlur.backgroundImage = ciOriginal
            blendBlur.maskImage = ciMask
            withBlur = blendBlur.outputImage ?? ciOriginal
        } else {
            withBlur = ciOriginal
        }

        // (2) グラデ画像をキャンバスサイズで作成
        guard let gradientCG = makeGradientImage(colors: gradient.uiColors, overlayRect: overlayRectInOriginal, canvasSize: canvasSize) else {
            return renderUIImage(from: withBlur, like: original, extent: extent)
        }
        let ciGradient = CIImage(cgImage: gradientCG)

        // (3) sheer 不透明度を適用
        let alphaFilter = CIFilter.colorMatrix()
        alphaFilter.inputImage = ciGradient
        alphaFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: sheer)
        let gradientWithAlpha = alphaFilter.outputImage ?? ciGradient

        // (4) シェイプ範囲だけ残す
        let clearBg = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: extent)
        let maskGradient = CIFilter.blendWithMask()
        maskGradient.inputImage = gradientWithAlpha
        maskGradient.backgroundImage = clearBg
        maskGradient.maskImage = ciMask
        let maskedGradient = maskGradient.outputImage ?? gradientWithAlpha

        // (5) ぼかし済み画像の上にグラデを sourceOver 合成
        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = maskedGradient
        composite.backgroundImage = withBlur
        let final = composite.outputImage ?? withBlur

        return renderUIImage(from: final, like: original, extent: extent)
    }

    private func renderUIImage(from ciImage: CIImage, like original: UIImage, extent: CGRect) -> UIImage? {
        guard let cg = context.createCGImage(ciImage, from: extent) else { return nil }
        return UIImage(cgImage: cg, scale: original.scale, orientation: .up)
    }

    /// シェイプの白黒マスクを作成 (UIKit y-down で描画)
    private func makeShapeMask(shape: CoverShapeID, overlayRect: CGRect, canvasSize: CGSize) -> CGImage? {
        let width = Int(canvasSize.width)
        let height = Int(canvasSize.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // CG (y-up) を UIKit (y-down) 風に反転
        ctx.translateBy(x: 0, y: canvasSize.height)
        ctx.scaleBy(x: 1, y: -1)

        let path = CoverShape(id: shape).path(in: overlayRect).cgPath
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.addPath(path)
        ctx.fillPath()

        return ctx.makeImage()
    }

    /// 線形グラデを overlayRect 内に描画 (135deg = top-left → bottom-right)
    private func makeGradientImage(colors: [UIColor], overlayRect: CGRect, canvasSize: CGSize) -> CGImage? {
        let width = Int(canvasSize.width)
        let height = Int(canvasSize.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))

        // CG (y-up) を UIKit (y-down) 風に反転
        ctx.translateBy(x: 0, y: canvasSize.height)
        ctx.scaleBy(x: 1, y: -1)

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors.map { $0.cgColor } as CFArray,
            locations: nil
        ) else { return nil }

        let start = CGPoint(x: overlayRect.minX, y: overlayRect.minY)
        let end = CGPoint(x: overlayRect.maxX, y: overlayRect.maxY)

        ctx.drawLinearGradient(
            gradient,
            start: start,
            end: end,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )

        return ctx.makeImage()
    }
}
