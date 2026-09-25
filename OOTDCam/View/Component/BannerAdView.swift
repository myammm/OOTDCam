//
//  BannerAdView.swift
//  OOTDCam
//

import GoogleMobileAds
import RevenueCatAdMob
import SwiftUI

/// バナー広告枠 (高さ50pt)。標準バナー (320×50) を中央配置し、ロード失敗・ノーフィル時は
/// 下地の灰色の帯がそのまま見える (枠の高さは動かさない、issue #19)。
/// パールの質感 (グラデーション・光沢) は適用しない。アプリUIの一部に見えると
/// 誤認を誘う見え方になるため、灰色の帯として面から素直に切り離す (issue #17)
struct BannerAdView: View {
    var body: some View {
        ZStack {
            Color(.adSlotBase)
            BannerAdContainer()
                .frame(width: 320, height: 50)
        }
    }
}

private struct BannerAdContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSize(size: CGSize(width: 320, height: 50), flags: 0))
        banner.adUnitID = AdConfig.savedBannerAdUnitID
        // ATT は OOTDCamApp が2回目以降の起動時に解決済み (初回起動のみ非パーソナライズ)。
        // RevenueCat Ads: load ではなく loadAndTrack で広告イベントを送る (issue #25)
        banner.loadAndTrack(request: Request(), placement: AdConfig.savedBannerPlacement)
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
