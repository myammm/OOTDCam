//
//  SavedPhoto.swift
//  OOTDCam
//

import UIKit

/// 保存結果。CapturedPhoto と同じ理由で、共有用フル解像度の full と
/// 保存完了画面の描画専用に縮小した display をペアで持つ。
struct SavedPhoto: Equatable {
    /// 共有用 (カメラロールに保存したものと同一)
    let full: UIImage
    /// 表示用 (.up 正規化・長辺 1600px 以下)
    let display: UIImage
}
