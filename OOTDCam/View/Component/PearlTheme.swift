//
//  PearlTheme.swift
//  OOTDCam
//
//  パール/ガラス方向の共通デザイン定義 (issue #14)
//  色は Assets.xcassets/Pearl に定義したカラーセットを参照する
//

import SwiftUI

enum Pearl {
    /// 本文の墨色
    static let ink = Color(.pearlInk)
    /// 補助テキスト
    static let inkSoft = Color(.pearlInkSoft)
    /// 虹色地の上に載せる濃い墨色 (完了ボタンなど)
    static let inkDeep = Color(.pearlInkDeep)
    /// 影のベース色
    static let shadow = Color(.pearlShadow)
    /// マーカー・選択状態のピンクグロウ
    static let glowPink = Color(.pearlGlowPink)
    /// ガイド線の暗い縁取り。白単色だと明るい背景で消えるので必ず重ねる
    static let guideEdge = Color(.pearlGuideEdge)

    /// 虹色グラデーション。ロゴ・完了ボタン・シャッターリムに限定して使う
    static let irisColors: [Color] = [
        Color(.irisPink), Color(.irisLavender), Color(.irisSky),
        Color(.irisMint), Color(.irisCream)
    ]
    static let iris = LinearGradient(
        colors: irisColors,
        startPoint: UnitPoint(x: 0, y: 0.35),
        endPoint: UnitPoint(x: 1, y: 0.65)
    )
}

/// 画面全体のパール地。斜め上から光が差す面として扱う
struct PearlBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(.pearlBase1), location: 0),
                .init(color: Color(.pearlBase2), location: 0.32),
                .init(color: Color(.pearlBase3), location: 0.58),
                .init(color: Color(.pearlBase4), location: 0.82),
                .init(color: Color(.pearlBase5), location: 1)
            ],
            startPoint: UnitPoint(x: 0.35, y: 0),
            endPoint: UnitPoint(x: 0.65, y: 1)
        )
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.85), Color.white.opacity(0)],
                center: UnitPoint(x: 0.18, y: 0.06),
                startRadius: 0,
                endRadius: 420
            )
        )
        .ignoresSafeArea()
    }
}

/// ロゴ。虹色グラデーションを乗せるのはここだけ
struct Wordmark: View {
    var body: some View {
        Text("fig.cam")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .tracking(0.9)
            .foregroundStyle(Pearl.iris)
            .saturation(1.3)
            .brightness(-0.08)
    }
}

/// 写真領域を囲むガラス縁。帯にめり込んだ長方形ではなく、面の上に置かれた一枚として見せる
struct PearlPlateModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.95), location: 0),
                            .init(color: Color(.glassEdge).opacity(0.6), location: 0.45),
                            .init(color: Color.white.opacity(0.85), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: Pearl.shadow.opacity(0.4), radius: 15, y: 8)
            )
    }
}

extension View {
    func pearlPlate() -> some View { modifier(PearlPlateModifier()) }
}

/// ガラス球ボタン (編集画面の +/−/✕ など)
struct PearlCircleButtonStyle: ButtonStyle {
    var size: CGFloat = 38
    var foreground: Color = Pearl.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.44, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: Color(.orbHighlight), location: 0.4),
                            .init(color: Color(.orbMid), location: 0.74),
                            .init(color: Color(.orbLow), location: 1)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.26),
                        startRadius: 0,
                        endRadius: size * 0.8
                    ))
                    .shadow(color: Pearl.shadow.opacity(0.45), radius: 5, y: 3)
            )
            .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
