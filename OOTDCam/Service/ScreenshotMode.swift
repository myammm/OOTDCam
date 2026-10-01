//
//  ScreenshotMode.swift
//  OOTDCam
//
//  App Store 用スクリーンショット撮影の補助。
//  シミュレータではカメラが使えないため、プレビューと撮影結果を
//  サンプル写真 (figcam で保存した実出力) に差し替える。
//  サンプル写真には日付スタンプが焼き込み済みなので、
//  有効時はライブの DateStamp 表示を止めて二重表示を防ぐ。
//
//  写真は Preview Content (DEVELOPMENT_ASSET_PATHS) に置いているため、
//  Archive ビルドには含まれない (リリースに個人写真を同梱しないため)。
//  デバッグビルドには含まれるので、実機で有効にならないよう
//  シミュレータ限定で読み込む。実機では samplePhoto が常に nil。
//

import UIKit

enum ScreenshotMode {
    #if targetEnvironment(simulator)
    static let samplePhoto: UIImage? = UIImage(named: "SamplePhoto")
    #else
    static let samplePhoto: UIImage? = nil
    #endif

    static var isActive: Bool { samplePhoto != nil }
}
