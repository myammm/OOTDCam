//
//  GummyTile.swift
//  OOTDCam
//
//  編集画面の形選択タイル (グミ質感)
//

import SwiftUI

/// グミ質感タイル。光源は全要素と同じ左上固定。
/// 面のグラデ + 内側の影(上) + 内側の光(下) + 紫寄りの外影の4層で立体にする
struct GummyTile<Icon: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let icon: (Bool) -> Icon

    var body: some View {
        Button(action: action) {
            ZStack {
                icon(isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: isSelected
                                ? [.init(color: Color(.tileSelectedPink), location: 0),
                                   .init(color: Color(.tileSelectedLavender), location: 0.5),
                                   .init(color: Color(.tileSelectedSky), location: 1)]
                                : [.init(color: Color(.glassHighlight), location: 0),
                                   .init(color: Color(.glassMid), location: 0.55),
                                   .init(color: Color(.glassLow), location: 1)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .shadow(.inner(color: Color(.glassInnerShadow).opacity(0.35), radius: 4, y: 3))
                        .shadow(.inner(color: .white.opacity(0.95), radius: 4, y: -3))
                    )
                    // 艶 (左上の白いぼかし楕円)。非選択面はほぼ白でハイライトが
                    // 効かず影だけ目立つため、色が乗る選択中のみ出す
                    .overlay(alignment: .topLeading) {
                        Ellipse()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 24, height: 10)
                            .blur(radius: 2)
                            .offset(x: 12, y: 5)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(.white, lineWidth: isSelected ? 2 : 0)
                    }
                    .shadow(
                        color: isSelected ? Pearl.glowPink.opacity(0.7) : Pearl.shadow.opacity(0.35),
                        radius: isSelected ? 8 : 4,
                        y: isSelected ? 6 : 3
                    )
            }
            .offset(y: isSelected ? -3 : 0)
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: isSelected)
    }
}

/// タイルに載せる形のアイコン。shapeID が nil なら「なし」の ✕
struct ShapeTileIcon: View {
    let shapeID: CoverShapeID?
    let selected: Bool

    private var color: Color {
        selected ? Color(.shapeIconSelected) : Color(.shapeIconMuted)
    }

    var body: some View {
        if let shapeID {
            let nominal = shapeID.nominalSize
            let width: CGFloat = 22
            CoverShape(id: shapeID)
                .fill(color)
                .frame(width: width, height: width * nominal.height / nominal.width)
        } else {
            Text("✕")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}
