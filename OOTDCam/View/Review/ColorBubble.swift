//
//  ColorBubble.swift
//  OOTDCam
//
//  編集画面のカラー選択ドット (シャボン玉)
//

import SwiftUI

/// シャボン玉のカラードット。中心を左上にずらした放射グラデーションで球に見せ、
/// 上下から内側に白を入れて丸みを出す
struct ColorBubble: View {
    let gradient: CoverGradient
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: gradient.colors[0], location: 0.40),
                            .init(color: gradient.colors[2], location: 1)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.26),
                        startRadius: 0,
                        endRadius: 34
                    )
                    .shadow(.inner(color: .white.opacity(0.85), radius: 3, y: -3))
                    .shadow(.inner(color: .white.opacity(0.45), radius: 3, y: 3))
                )
                .frame(width: 34, height: 34)
                // 艶 (左上の白いぼかし楕円)。タイルと同様、選択中のみ出す
                .overlay(alignment: .topLeading) {
                    Ellipse()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 12, height: 8)
                        .blur(radius: 1.4)
                        .offset(x: 7, y: 5)
                        .opacity(isSelected ? 1 : 0)
                }
                .overlay {
                    Circle().stroke(.white.opacity(isSelected ? 1 : 0.7), lineWidth: isSelected ? 2.5 : 1)
                }
                .shadow(
                    color: isSelected ? Pearl.glowPink.opacity(0.7) : Pearl.shadow.opacity(0.4),
                    radius: isSelected ? 8 : 4,
                    y: isSelected ? 0 : 3
                )
                .scaleEffect(isSelected ? 1.1 : 1)
                .offset(y: isSelected ? -4 : 0)
                // 見た目34ptでも当たり判定は44ptを確保
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
