//
//  BannerAdView.swift
//  OOTDCam
//

import GoogleMobileAds
import RevenueCatAdMob
import SwiftUI

/// バナー広告枠 (高さ50pt)。標準バナー (320×50) を中央配置する。
/// ロード失敗・ノーフィル時は下地の灰色の帯も出さず空白にする。枠の高さは動かさない (issue #19)。
/// パールの質感 (グラデーション・光沢) は適用しない。アプリUIの一部に見えると
/// 誤認を誘う見え方になるため、灰色の帯として面から素直に切り離す (issue #17)
struct BannerAdView: View {
    /// 広告を1度でも受け取ったら true。以降のリフレッシュ失敗では前の広告が残るので戻さない
    @Binding var isLoaded: Bool

    var body: some View {
        ZStack {
            Color(.adSlotBase)
                .opacity(isLoaded ? 1 : 0)
            BannerAdContainer(isLoaded: $isLoaded)
                .frame(width: 320, height: 50)
        }
    }
}

private struct BannerAdContainer: UIViewRepresentable {
    @Binding var isLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSize(size: CGSize(width: 320, height: 50), flags: 0))
        banner.adUnitID = AdConfig.savedBannerAdUnitID
        // ATT は OOTDCamApp が2回目以降の起動時に解決済み (初回起動のみ非パーソナライズ)。
        // RevenueCat Ads: load ではなく loadAndTrack で広告イベントを送る (issue #25)。
        // delegate は RevenueCat 側で weak 参照なので、Coordinator (SwiftUI が保持) を渡す
        banner.loadAndTrack(
            request: Request(),
            placement: AdConfig.savedBannerPlacement,
            delegate: context.coordinator
        )
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, BannerViewDelegate {
        private let isLoaded: Binding<Bool>

        init(isLoaded: Binding<Bool>) {
            self.isLoaded = isLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            isLoaded.wrappedValue = true
        }
    }
}
