//
//  ScreenshotMode.swift
//  OOTDCam
//
//  App Store 用スクリーンショット撮影の補助。
//  シミュレータではカメラが使えないため、プレビューと撮影結果を
//  サンプル写真に差し替える。
//
//  サンプル写真は起動引数で切り替える (未指定なら standard):
//    xcrun simctl launch booted app.myammm.figcam -ScreenshotSample mirror
//  - standard: figcam で保存した実出力。日付スタンプが焼き込み済みなので、
//              ライブの DateStamp 表示を止めて二重表示を防ぐ
//  - mirror:   鏡越しの撮影シーン (iPhone 標準カメラで撮影、スタンプなし)
//
//  写真は Preview Content (DEVELOPMENT_ASSET_PATHS) に置いているため、
//  Archive ビルドには含まれない (リリースに個人写真を同梱しないため)。
//  デバッグビルドには含まれるので、実機で有効にならないよう
//  シミュレータ限定で読み込む。実機では samplePhoto が常に nil。
//

import UIKit

enum ScreenshotMode {
    private enum Sample: String {
        case standard
        case mirror

        var assetName: String {
            switch self {
            case .standard: "SamplePhoto"
            case .mirror: "MirrorSamplePhoto"
            }
        }

        var hasBakedDateStamp: Bool { self == .standard }
    }

    #if targetEnvironment(simulator)
    private static let sample: Sample? =
        Sample(rawValue: UserDefaults.standard.string(forKey: "ScreenshotSample") ?? "") ?? .standard
    #else
    private static let sample: Sample? = nil
    #endif

    static let samplePhoto: UIImage? = sample.flatMap { UIImage(named: $0.assetName) }

    static var isActive: Bool { samplePhoto != nil }

    /// サンプル写真にスタンプが焼き込み済みで、ライブの DateStamp を出すと二重になるか
    static var hidesLiveDateStamp: Bool { isActive && sample?.hasBakedDateStamp == true }
}
