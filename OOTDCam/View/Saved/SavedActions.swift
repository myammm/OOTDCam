//
//  SavedActions.swift
//  OOTDCam
//

import SwiftUI

/// 主 CTA は撮影ループの頻度が高い「続けて撮る」(iris)。
/// iOS の慣習 (横並びの右=推奨アクション) に合わせて右に置き、強調色もセットで揃える
struct SavedActions: View {
    let onShare: () -> Void
    let onShoot: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onShare) {
                Text("共有する")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Pearl.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color(.glassHighlight), location: 0),
                                        .init(color: Color(.glassMid), location: 0.55),
                                        .init(color: Color(.glassLow), location: 1)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .shadow(.inner(color: Color(.glassInnerShadow).opacity(0.35), radius: 4, y: 3))
                                .shadow(.inner(color: .white.opacity(0.95), radius: 4, y: -3))
                            )
                            .shadow(color: Pearl.shadow.opacity(0.55), radius: 5, y: 5)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())

            Button(action: onShoot) {
                Text("続けて撮る")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Pearl.inkDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        // 形は編集画面の完了ボタン (irisCapsule) に合わせる
                        Capsule()
                            .fill(Pearl.iris.shadow(.inner(color: .white.opacity(0.7), radius: 3, y: -2)))
                            .shadow(color: Color(.irisButtonGlow).opacity(0.9), radius: 8, y: 7)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }
}
