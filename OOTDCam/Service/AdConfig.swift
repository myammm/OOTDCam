import Foundation

/// 広告・RevenueCat まわりの識別子置き場 (issue #19 / #25)
enum AdConfig {
    /// RevenueCat の Public API Key (クライアント配布前提の公開キー)
    static let revenueCatAPIKey = "appl_DoxWjKbkIesixyxLlgaxUKIWiIG"

    /// キー未設定のまま Purchases.configure すると起動ごとにエラーログが出るため、
    /// 設定済みかどうかで初期化を分岐できるようにしておく
    static var isRevenueCatKeySet: Bool {
        revenueCatAPIKey.hasPrefix("appl_")
    }

    /// 保存完了画面のバナー広告ユニット ID
    /// Debug は Google 提供のテスト専用 ID (常にテスト広告が返る)。本番 ID をタップしない運用を
    /// コードで保証する (issue #19: 無効トラフィック対策)
    #if DEBUG
    static let savedBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    #else
    static let savedBannerAdUnitID = "ca-app-pub-1959551056530277/4263677000"
    #endif

    /// RevenueCat Ads に送る placement 名 (issue #25)
    static let savedBannerPlacement = "save_complete_banner"
}
