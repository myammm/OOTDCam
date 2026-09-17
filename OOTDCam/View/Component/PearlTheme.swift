//
//  PearlTheme.swift
//  OOTDCam
//
//  パール/ガラス方向の共通デザイン定義 (issue #14)
//  色は Assets.xcassets/Colors に定義したカラーセットを参照する
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

    /// 虹色グラデーション (アプリアイコンのリングと同じ3色・均等配置)。
    /// 適用箇所はロゴ・完了ボタン・シャッターリング・撮影フラッシュ・
    /// 保存完了画面の続けて撮るボタンとトーストのチェック丸に限定し、
    /// 個別にグラデーションを書かず必ずこの定義を参照する
    static let irisColors: [Color] = [
        Color(.irisPink), Color(.irisLavender), Color(.irisSky)
    ]
    static let iris = LinearGradient(
        colors: irisColors,
        startPoint: UnitPoint(x: 0, y: 0.35),
        endPoint: UnitPoint(x: 1, y: 0.65)
    )

    /// 上部の帯の高さ。撮影・編集で揃えないとプレートの開始位置が画面間でずれる
    static let topBarHeight: CGFloat = 48

    /// 撮影フラッシュの膜 (iris と同じ3色に透過を乗せたもの・115deg)。
    /// 保存完了画面のスイープ演出もこの色を使う
    static let flash = LinearGradient(
        stops: [
            .init(color: Color(.irisPink).opacity(0.95), location: 0),
            .init(color: Color(.irisLavender).opacity(0.90), location: 0.5),
            .init(color: Color(.irisSky).opacity(0.95), location: 1)
        ],
        startPoint: UnitPoint(x: 0, y: 0.3),
        endPoint: UnitPoint(x: 1, y: 0.7)
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
        .overlay(AuroraBlobs())
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

/// 画面の奥にたゆたう光だまり。すりガラス面 (frostedPanel) が透かす相手で、
/// これがないと地が単色に近くガラスに見えない。
/// 写真の主役性を守るため、縁に寄せて淡く保つ (色は iris トークンを共有)
private struct AuroraBlobs: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle()
                    .fill(Color(.irisPink))
                    .frame(width: w * 0.9, height: w * 0.9)
                    .position(x: w * 0.94, y: h * 0.16)
                Circle()
                    .fill(Color(.irisSky))
                    .frame(width: w * 0.75, height: w * 0.75)
                    .position(x: w * 0.02, y: h * 0.48)
                Circle()
                    .fill(Color(.irisLavender))
                    .frame(width: w * 0.95, height: w * 0.95)
                    .position(x: w * 0.72, y: h * 0.98)
            }
            .blur(radius: 70)
            .opacity(0.45)
            // 静止した装飾なので1枚のレイヤーに焼いて毎フレームのブラー計算を避ける
            .drawingGroup()
        }
        .allowsHitTesting(false)
    }
}

/// すりガラス面 (撮影画面のキャプションピルなど)。
/// パール地の光だまりが透けて初めてガラスに見えるので、パール地の上でのみ使う。
/// Material は使わない: システムのマテリアルはグレーのベース色を持ち (ダークモードでは暗転もする)、
/// パステル地の上で濁って浮く。背後の光だまりは既にぼけているので、白の透過膜だけで
/// すりガラスに見え、色もそのまま透ける。
/// 写真の上に置くトースト (SavedToast) は実ブラーが要る別レシピ
struct FrostedPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    // 乳白の膜 + 上端の内側ハイライトで「厚みのある板」にする
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.66), location: 0),
                                .init(color: .white.opacity(0.38), location: 0.55),
                                .init(color: .white.opacity(0.5), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .shadow(.inner(color: .white.opacity(0.9), radius: 6, y: -3))
                    )
                    .overlay(
                        shape.strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.95), location: 0),
                                    .init(color: .white.opacity(0.35), location: 0.5),
                                    .init(color: .white.opacity(0.8), location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                    )
                    .shadow(color: Pearl.shadow.opacity(0.35), radius: 16, y: 10)
            }
    }
}

extension View {
    /// 浮いたガラスカード (撮影画面のキャプションピルなど)。
    /// 編集画面のコントロール群には使わない: 縦予算を食って 3:4 プレートが痩せるため、
    /// グミ質感の部品はパール地に直接並べる
    func frostedPanel(cornerRadius: CGFloat = 24) -> some View {
        modifier(FrostedPanelModifier(cornerRadius: cornerRadius))
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

/// 押している間だけ縮めて触った感触を出す。標準スタイルは押下時に半透明になり
/// 質感が消えるので、質感のあるボタンには必ずこちらを使う
struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// 虹色カプセル (完了ボタンなど)。
/// 内側下の白い光で厚みを、紫寄りの外影で浮きを出す。黒い影は安っぽくなるので使わない
struct IrisCapsuleModifier: ViewModifier {
    var fontSize: CGFloat = 13
    var verticalPadding: CGFloat = 9
    var horizontalPadding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(Pearl.inkDeep)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background {
                Capsule()
                    .fill(Pearl.iris.shadow(.inner(color: .white.opacity(0.7), radius: 3, y: -2)))
                    .shadow(color: Color(.irisButtonGlow).opacity(0.9), radius: 8, y: 7)
            }
    }
}

extension View {
    func irisCapsule(fontSize: CGFloat = 13, verticalPadding: CGFloat = 9, horizontalPadding: CGFloat = 20) -> some View {
        modifier(IrisCapsuleModifier(fontSize: fontSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding))
    }
}

/// ガラス球ボタン (編集画面の +/−/✕ など)
struct PearlCircleButtonStyle: ButtonStyle {
    var size: CGFloat = 38
    var foreground: Color = Pearl.ink

    /// .disabled() の状態。無効時は彩度を落として沈ませ「押せない」見た目にする
    @Environment(\.isEnabled) private var isEnabled

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
            .saturation(isEnabled ? 1.0 : 0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}
