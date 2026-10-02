//
//  SavedToast.swift
//  OOTDCam
//

import SwiftUI

struct SavedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("✓")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Pearl.inkDeep)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Pearl.iris))
            Text("カメラロールに保存しました")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Pearl.ink)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 18)
        .background {
            // 背面ぼかしが意味を持つ唯一の場所。帯の上では背景が不透明で効かないが、
            // ここは写真の上なので実際に写真がぼけて透ける
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().fill(
                        Color.white.opacity(0.5)
                            .shadow(.inner(color: .white.opacity(0.8), radius: 3, y: -2))
                    )
                )
                .overlay(Capsule().strokeBorder(Pearl.glassEdgeLine, lineWidth: 1.2))
                .shadow(color: Color(.toastShadow).opacity(0.7), radius: 12, y: 10)
        }
    }
}
