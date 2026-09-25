import Foundation

/// 広告・RevenueCat まわりの識別子置き場 (issue #19 / #25)
enum AdConfig {
    /// RevenueCat の Public API Key (ダッシュボードのアプリ登録画面で発行される "appl_..." 形式)
    /// TODO: RevenueCat のアプリ登録完了後に差し替える (issue #25)
    static let revenueCatAPIKey = "REVENUECAT_PUBLIC_API_KEY_未設定"

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
    /// TODO: AdMob ダッシュボードでバナーユニット作成後に "ca-app-pub-1959551056530277/..." へ差し替える
    static let savedBannerAdUnitID = "PRODUCTION_BANNER_AD_UNIT_ID_未設定"
    #endif

    /// RevenueCat Ads に送る placement 名 (issue #25)
    static let savedBannerPlacement = "save_complete_banner"
}
