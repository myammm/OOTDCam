//
//  ReviewHeader.swift
//  OOTDCam
//

import SwiftUI

struct ReviewHeader: View {
    let isSaving: Bool
    /// 実際に表示されている写真の幅。ボタン列の左右端はこれに揃える
    /// (3:4 プレートは高さ制約で縮むことがあり、固定 padding では写真の縁とずれる。
    /// ReviewControlPad と同じ実測束縛方式)
    let contentWidth: CGFloat
    let onRetake: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Wordmark()

            HStack {
                // 左上はアイコンだけのガラス球。「帯の ← = 1画面戻る」で全画面共通
                // (SNOW 系の慣習に合わせテキストは置かない。✕ はモチーフ削除と被るので使わない)。
                // 文言がない分、読み上げラベルは必須
                Button(action: onRetake) {
                    Text("←")
                }
                .buttonStyle(PearlCircleButtonStyle(size: Pearl.barButtonHeight))
                .accessibilityLabel("撮り直す")

                Spacer()

                Button(action: onDone) {
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Pearl.inkDeep)
                                .scaleEffect(0.7)
                        } else {
                            Text("完了")
                                .tracking(0.5)
                        }
                    }
                    .frame(minHeight: 16)
                    .irisCapsule()
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(isSaving)
            }
        }
        // 実測幅が取れるまでの初回フレームだけ固定 padding で近似する
        .frame(width: contentWidth > 0 ? contentWidth : nil)
        .padding(.horizontal, contentWidth > 0 ? 0 : Pearl.barHorizontalPadding)
        .frame(height: Pearl.topBarHeight)
        .frame(maxWidth: .infinity)
    }
}
