//
//  BannerAdView.swift
//  OOTDCam
//

import AppTrackingTransparency
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
    /// この画面 (広告枠) を表示した累計回数。初回の保存はフォトライブラリ許可の直後で
    /// ダイアログが連続してしまうため、ATT は2回目以降に求める (実機確認による判断)。
    /// 初回のバナーは非パーソナライズになるだけで表示は問題ない
    @AppStorage("savedBannerAppearanceCount") private var appearanceCount = 0

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSize(size: CGSize(width: 320, height: 50), flags: 0))
        banner.adUnitID = AdConfig.savedBannerAdUnitID
        appearanceCount += 1
        if appearanceCount >= 2 {
            // ATT の応答が確定してからロードする (未確定のままだと非パーソナライズ扱いになる)
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    load(banner)
                }
            }
        } else {
            load(banner)
        }
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    private func load(_ banner: BannerView) {
        // RevenueCat Ads: load ではなく loadAndTrack で広告イベントを送る (issue #25)
        banner.loadAndTrack(request: Request(), placement: AdConfig.savedBannerPlacement)
    }
}
