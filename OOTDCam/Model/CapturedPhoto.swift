//
//  CapturedPhoto.swift
//  OOTDCam
//

import UIKit

/// 撮影結果。フル解像度の original と、プレビュー描画専用の display をペアで持つ。
/// display は撮影直後にバックグラウンドで縮小・orientation 正規化済み。
/// フル解像度をメインスレッドで描画するとレビュー画面への遷移がハングするため、
/// 画面表示には必ず display を使い、original は保存 (焼き込み) 専用とする。
struct CapturedPhoto: Equatable {
    /// 保存用フル解像度 (orientation は EXIF のまま)
    let original: UIImage
    /// 表示用 (.up 正規化・長辺 1600px 以下)
    let display: UIImage
}
