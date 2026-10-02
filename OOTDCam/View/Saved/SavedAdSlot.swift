//
//  SavedAdSlot.swift
//  OOTDCam
//

import SwiftUI

/// 保存完了画面下部のバナー広告枠 (撮影・編集画面には広告を入れない)
struct SavedAdSlot: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("広告")
                .font(.system(size: 9.5))
                .kerning(1)
                .foregroundStyle(Color(.adLabelText))
            BannerAdView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) { adDivider }
                .overlay(alignment: .bottom) { adDivider }
        }
        // 「続けて撮る」との間隔 20pt。ボタンに隣接させると誤タップが増え、
        // 無効トラフィックとして跳ね返るので詰めないこと
        .padding(.top, 20)
        // SE (667pt) はこの画面が縦ぴったりで、10pt だと広告が下端からはみ出す
        .padding(.bottom, 6)
    }

    private var adDivider: some View {
        Rectangle()
            .fill(Color(.adDivider).opacity(0.14))
            .frame(height: 1)
    }
}
