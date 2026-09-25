//
//  OOTDCamApp.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import GoogleMobileAds
import RevenueCat
import SwiftUI

@main
struct OOTDCamApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
        // RevenueCat は広告イベントのトラッキングにのみ使用 (IAP なし、issue #25)
        if AdConfig.isRevenueCatKeySet {
            Purchases.configure(withAPIKey: AdConfig.revenueCatAPIKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
