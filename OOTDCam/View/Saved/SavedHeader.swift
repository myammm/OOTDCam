//
//  SavedHeader.swift
//  OOTDCam
//

import SwiftUI

struct SavedHeader: View {
    /// 実際に表示されている写真の幅。ボタン列の左右端はこれに揃える (ReviewHeader と同じ実測束縛方式)
    let contentWidth: CGFloat
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Wordmark()

            HStack {
                // 左上はアイコンだけのガラス球。「帯の ← = 1画面戻る」で編集画面と共通の文法
                Button(action: onBack) {
                    Text("←")
                }
                .buttonStyle(PearlCircleButtonStyle(size: Pearl.barButtonHeight))
                Spacer()
            }
        }
        // 実測幅が取れるまでの初回フレームだけ固定 padding で近似する
        .frame(width: contentWidth > 0 ? contentWidth : nil)
        .padding(.horizontal, contentWidth > 0 ? 0 : Pearl.barHorizontalPadding)
        // 高さは撮影・編集の帯と揃える。揃えないとプレートの開始位置が
        // クロスフェード中にずれて見える (#18 と同じ理由)
        .frame(height: Pearl.topBarHeight)
        .frame(maxWidth: .infinity)
    }
}
