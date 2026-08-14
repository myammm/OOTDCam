//
//  BannerAdView.swift
//  OOTDCam
//

import SwiftUI

/// バナー広告枠 (高さ50pt) のプレースホルダ。広告SDK導入時に中身を SDK のビューへ差し替える。
/// パールの質感 (グラデーション・光沢) は適用しない。アプリUIの一部に見えると
/// 誤認を誘う見え方になるため、灰色の帯として面から素直に切り離す (issue #17)
struct BannerAdView: View {
    var body: some View {
        Color(.adSlotBase)
    }
}
