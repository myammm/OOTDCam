//
//  SavedPhoto.swift
//  OOTDCam
//

import UIKit

/// 保存結果。フル解像度はカメラロールと fileURL のファイルにあり、
/// メモリ上には保持しない (保存完了画面の間 40MB 超を抱えることになるため)
struct SavedPhoto: Equatable {
    /// 表示用 (.up 正規化・長辺 1600px 以下)
    let display: UIImage
    /// カメラロールに保存したものと同一の JPEG 一時ファイル。共有シートに渡す
    /// (書き出しに失敗し iOS 側エンコードで保存した場合のみ nil)
    let fileURL: URL?
}
