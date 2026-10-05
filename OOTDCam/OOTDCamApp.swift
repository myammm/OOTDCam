//
//  OOTDCamApp.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import AppTrackingTransparency
import GoogleMobileAds
import RevenueCat
import SwiftUI

@main
struct OOTDCamApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// ATT は2回目以降の起動で求める。初回起動はカメラ許可と重なり、
    /// 保存時に出すと「保存できた」の瞬間に割り込むため (実機確認による判断)。
    /// 初回起動の広告は非パーソナライズになるだけで表示は問題ない
    private let isSecondOrLaterLaunch: Bool

    init() {
        let launchCount = UserDefaults.standard.integer(forKey: "appLaunchCount") + 1
        UserDefaults.standard.set(launchCount, forKey: "appLaunchCount")
        isSecondOrLaterLaunch = launchCount >= 2

        MobileAds.shared.start(completionHandler: nil)
        // RevenueCat は広告イベントのトラッキングにのみ使用 (IAP なし、issue #25)
        Purchases.configure(withAPIKey: AdConfig.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    // ATT のダイアログはアプリがアクティブになってからでないと表示されない
                    guard newPhase == .active,
                          isSecondOrLaterLaunch,
                          ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
                    // 完了ハンドラ版はバックグラウンドで呼ばれ、メインアクター上で書いたクロージャだと
                    // Swift 6 の実行時アイソレーションチェックで落ちるため async 版を使う
                    Task { _ = await ATTrackingManager.requestTrackingAuthorization() }
                }
        }
    }
}
