//
//  GuideOverlayView.swift
//  OOTDCam
//
//  Created on 2025/09/23.
//

import SwiftUI

/// ガイドの目印で使う紫 (#8A5CF6) — 旧バッジから流用
let guidePurple = Color(red: 0.541, green: 0.361, blue: 0.965)

/// ハート・ブラケット・タイトルで使うピンク (#FF2D88)
let guidePink = Color(hex: "#FF2D88")

struct GuideOverlayView: View {
    @State private var breath: CGFloat = 1.0

    private let neonGradient = LinearGradient(
        colors: [.cyan, .purple, guidePink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let faceY = height / 2
            let feetLineBottomInset: CGFloat = 34
            let feetLineY = height - feetLineBottomInset
            let feetLineWidth: CGFloat = 80
            let bracketHeight: CGFloat = 8

            ZStack {
                // 4隅のビューファインダーブラケット (位置合わせに影響しないのでブレスアニメ対象)
                ViewfinderCorners()
                    .scaleEffect(breath, anchor: .center)

                // 顔ガイド (グラデのハート + 内側クロスヘア)
                faceGuide(centerX: centerX, centerY: faceY, screenWidth: width)

                // 足先ガイド (中央の横破線 + 下側ブラケット)
                feetCenterGuide(y: feetLineY, lineWidth: feetLineWidth, bracketHeight: bracketHeight, screenWidth: width)

                // FEET ラベル (左端、足元横破線まで点線で接続)
                feetLabelLeft(y: feetLineY, screenWidth: width, feetLineWidth: feetLineWidth)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    breath = 1.04
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 顔ガイド (ハート + 内側クロスヘア + FACEラベル)
    @ViewBuilder
    private func faceGuide(centerX: CGFloat, centerY: CGFloat, screenWidth: CGFloat) -> some View {
        let heartW: CGFloat = 72
        let heartH: CGFloat = 61

        // ハート (グラデ破線)
        HeartShape()
            .stroke(
                neonGradient,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [5, 4])
            )
            .frame(width: heartW, height: heartH)
            .shadow(color: guidePurple.opacity(0.6), radius: 8)
            .position(x: centerX, y: centerY)

        // 内側クロスヘア (小さく cyan opacity 0.5)
        CrosshairShape()
            .stroke(Color.cyan.opacity(0.5), lineWidth: 0.8)
            .frame(width: 8, height: 8)
            .position(x: centerX, y: centerY - 2)

        // FACE 接続線 (ハート右端から少し離して → ピル左端まで)
        let pillRightInset: CGFloat = 14
        let pillEstimatedWidth: CGFloat = 60
        let pillCenterX = screenWidth - pillRightInset - pillEstimatedWidth / 2
        let gap: CGFloat = 6
        let connectorStartX = centerX + heartW / 2 + gap
        let connectorEndX = pillCenterX - pillEstimatedWidth / 2 - gap

        Path { path in
            path.move(to: CGPoint(x: connectorStartX, y: centerY))
            path.addLine(to: CGPoint(x: connectorEndX, y: centerY))
        }
        .stroke(
            guidePurple.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
        )

        // FACE ピル
        labelPill(text: "♡ FACE")
            .position(x: pillCenterX, y: centerY)
    }

    // MARK: - 足先ガイド (中央配置)
    @ViewBuilder
    private func feetCenterGuide(y: CGFloat, lineWidth: CGFloat, bracketHeight: CGFloat, screenWidth: CGFloat) -> some View {
        let centerX = screenWidth / 2

        // 横破線
        Path { path in
            path.move(to: CGPoint(x: centerX - lineWidth / 2, y: y))
            path.addLine(to: CGPoint(x: centerX + lineWidth / 2, y: y))
        }
        .stroke(
            guidePurple.opacity(0.5),
            style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
        )
        .shadow(color: guidePurple.opacity(0.35), radius: 4)

        // 下側ブラケット (左)
        Path { path in
            path.move(to: CGPoint(x: centerX - lineWidth / 2, y: y))
            path.addLine(to: CGPoint(x: centerX - lineWidth / 2, y: y + bracketHeight))
        }
        .stroke(guidePurple.opacity(0.45), lineWidth: 1.5)

        // 下側ブラケット (右)
        Path { path in
            path.move(to: CGPoint(x: centerX + lineWidth / 2, y: y))
            path.addLine(to: CGPoint(x: centerX + lineWidth / 2, y: y + bracketHeight))
        }
        .stroke(guidePurple.opacity(0.45), lineWidth: 1.5)
    }

    // MARK: - FEET ラベル (左端、足元横破線まで接続。両端少し離す)
    @ViewBuilder
    private func feetLabelLeft(y: CGFloat, screenWidth: CGFloat, feetLineWidth: CGFloat) -> some View {
        let pillLeftInset: CGFloat = 14
        let pillEstimatedWidth: CGFloat = 46
        let pillCenterX = pillLeftInset + pillEstimatedWidth / 2
        let gap: CGFloat = 6
        let connectorStartX = pillCenterX + pillEstimatedWidth / 2 + gap
        let connectorEndX = screenWidth / 2 - feetLineWidth / 2 - gap

        Path { path in
            path.move(to: CGPoint(x: connectorStartX, y: y))
            path.addLine(to: CGPoint(x: connectorEndX, y: y))
        }
        .stroke(
            guidePurple.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
        )

        labelPill(text: "FEET")
            .position(x: pillCenterX, y: y)
    }

    // MARK: - ラベルピル (共通)
    private func labelPill(text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(1.0)
            .foregroundStyle(guidePurple)
            .shadow(color: guidePurple.opacity(0.6), radius: 3)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(guidePurple.opacity(0.18))
                    .overlay(
                        Capsule()
                            .stroke(guidePurple.opacity(0.45), lineWidth: 1)
                    )
            )
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
    }
}

// MARK: - Viewfinder Corner Brackets
struct ViewfinderCorners: View {
    var body: some View {
        GeometryReader { geo in
            let inset: CGFloat = 10
            let size: CGFloat = 26
            let lineWidth: CGFloat = 2
            let color = guidePink.opacity(0.55)
            let w = geo.size.width
            let h = geo.size.height

            // 左上
            Path { p in
                p.move(to: CGPoint(x: inset, y: inset + size))
                p.addLine(to: CGPoint(x: inset, y: inset))
                p.addLine(to: CGPoint(x: inset + size, y: inset))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // 右上
            Path { p in
                p.move(to: CGPoint(x: w - inset - size, y: inset))
                p.addLine(to: CGPoint(x: w - inset, y: inset))
                p.addLine(to: CGPoint(x: w - inset, y: inset + size))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // 左下
            Path { p in
                p.move(to: CGPoint(x: inset, y: h - inset - size))
                p.addLine(to: CGPoint(x: inset, y: h - inset))
                p.addLine(to: CGPoint(x: inset + size, y: h - inset))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // 右下
            Path { p in
                p.move(to: CGPoint(x: w - inset - size, y: h - inset))
                p.addLine(to: CGPoint(x: w - inset, y: h - inset))
                p.addLine(to: CGPoint(x: w - inset, y: h - inset - size))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - Crosshair Shape
struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let arm = rect.width / 2

        path.move(to: CGPoint(x: cx - arm, y: cy))
        path.addLine(to: CGPoint(x: cx + arm, y: cy))
        path.move(to: CGPoint(x: cx, y: cy - arm))
        path.addLine(to: CGPoint(x: cx, y: cy + arm))

        return path
    }
}

struct GuideOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            GuideOverlayView()
        }
        .ignoresSafeArea()
    }
}
