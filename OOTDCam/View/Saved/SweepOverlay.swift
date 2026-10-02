//
//  SweepOverlay.swift
//  OOTDCam
//

import SwiftUI

/// 保存の合図として写真の上を一度だけ左から右に走る虹色の膜。
/// 色は撮影フラッシュ (Pearl.flash) と同じにして、撮影 → 保存を同じ光の演出でつなぐ
struct SweepOverlay: View {
    @State private var go = false

    var body: some View {
        GeometryReader { geo in
            Pearl.flash
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.30),
                            .init(color: .white.opacity(0.55), location: 0.50),
                            .init(color: .clear, location: 0.70)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 1.6)
                    .offset(x: go ? geo.size.width * 0.6 : -geo.size.width * 0.9)
                )
                .opacity(go ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 1).delay(0.25)) { go = true }
                }
        }
        .allowsHitTesting(false)
    }
}
