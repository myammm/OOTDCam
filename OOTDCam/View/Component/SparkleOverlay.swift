//
//  SparkleOverlay.swift
//  OOTDCam
//
//  Created on 2026/09/18.
//

import SwiftUI

// MARK: - Sparkle Effect (撮影瞬間の「キラッ」)
/// 4点星を写真の上へランダムに散らす一発演出。
/// 車輪状の回転はローディングスピナーに見えて待たされ感が出るため、
/// 出現→消滅のきらめきで「撮れた」を祝う形にしている
struct SparkleOverlay: View {
    private struct Sparkle: Identifiable {
        let id = UUID()
        /// プレート内の相対位置 (0-1)
        let position: CGPoint
        let size: CGFloat
        let delay: Double
        let rotation: Double
    }

    // 親の再評価で配置が変わらないよう @State に初回生成分を固定する
    @State private var sparkles = Self.scatter()

    /// 縁に寄りすぎない範囲で位置・大きさ・タイミングをばらす。
    /// 消え終わりが showSparkles の 0.8 秒窓に収まるよう delay は 0.22 まで
    private static func scatter() -> [Sparkle] {
        (0..<10).map { _ in
            Sparkle(
                position: CGPoint(x: .random(in: 0.12...0.88), y: .random(in: 0.10...0.86)),
                size: .random(in: 14...30),
                delay: .random(in: 0...0.22),
                rotation: .random(in: -22...22)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(sparkles) { sparkle in
                TwinkleStar(size: sparkle.size, delay: sparkle.delay, rotation: sparkle.rotation)
                    .position(x: geo.size.width * sparkle.position.x,
                              y: geo.size.height * sparkle.position.y)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// 1つの星: ポップに現れて、すっと縮みながら消える
private struct TwinkleStar: View {
    let size: CGFloat
    let delay: Double
    let rotation: Double
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0

    var body: some View {
        SparkleShape()
            .fill(Color.white)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .shadow(color: Pearl.glowPink.opacity(0.9), radius: size * 0.28)
            .shadow(color: .white.opacity(0.8), radius: 1.5)
            .scaleEffect(scale)
            .opacity(opacity)
            .task {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.55).delay(delay)) {
                    scale = 1
                    opacity = 1
                }
                // 画面から外れたら .task ごとキャンセルされ、消える演出も走らない
                guard (try? await Task.sleep(for: .seconds(delay + 0.32))) != nil else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    scale = 0.5
                    opacity = 0
                }
            }
    }
}

/// プリクラ的な 4点星 (辺が中心へ凹むダイヤ)
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pull: CGFloat = 0.18
        let cx = rect.midX
        let cy = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy),
                          control: CGPoint(x: cx + rect.width * pull, y: cy - rect.height * pull))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY),
                          control: CGPoint(x: cx + rect.width * pull, y: cy + rect.height * pull))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: cy),
                          control: CGPoint(x: cx - rect.width * pull, y: cy + rect.height * pull))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.minY),
                          control: CGPoint(x: cx - rect.width * pull, y: cy - rect.height * pull))
        path.closeSubpath()
        return path
    }
}
