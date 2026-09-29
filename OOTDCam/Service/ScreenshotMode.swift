//
//  ScreenshotMode.swift
//  OOTDCam
//
//  App Store 用スクリーンショット撮影の補助。
//  シミュレータではカメラが使えないため、プレビューと撮影結果を
//  リポジトリ内のサンプル写真 (figcam で保存した実出力) に差し替える。
//  サンプル写真には日付スタンプが焼き込み済みなので、
//  有効時はライブの DateStamp 表示を止めて二重表示を防ぐ。
//
//  写真はアプリにバンドルしない (リリースに個人写真を同梱しないため)。
//  実機ビルドでは samplePhoto が常に nil のため、この機能は一切動かない。
//

import UIKit

enum ScreenshotMode {
    #if targetEnvironment(simulator)
    /// #filePath はビルドしたマシン上のこのファイルの絶対パスに展開されるため、
    /// どの環境のチェックアウトでもリポジトリ直下の Screenshots/ を指せる
    static let samplePhoto: UIImage? = {
        let repoRoot = URL(fileURLWithPath: #filePath) // <repo>/OOTDCam/Service/ScreenshotMode.swift
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let path = repoRoot.appendingPathComponent("Screenshots/sample-photo.jpg").path
        return UIImage(contentsOfFile: path)
    }()
    #else
    static let samplePhoto: UIImage? = nil
    #endif

    static var isActive: Bool { samplePhoto != nil }
}
