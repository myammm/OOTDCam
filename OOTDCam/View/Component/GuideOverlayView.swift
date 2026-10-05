//
//  GuideOverlayView.swift
//  OOTDCam
//
//  Created on 2025/09/23.
//

import SwiftUI

/// 撮影ガイド (パール/ガラス版)
/// ♡は枠の垂直中央に固定する。顔が中央にあるほど小さく写る、というのがこのアプリの核。
/// ♡から足元の線までを破線で縦に繋ぎ、「顔から下の全身をこの長さに収める」という
/// 一本のガイドとして読ませる。
/// 線はすべて白＋暗い縁取りの二重構造。単色だと背景によって消える。
struct GuideOverlayView: View {
    /// 足元線の下端の入り。日付スタンプの下余白 (右12pt/下10pt の下側) と揃える
    private let footInset: CGFloat = 10
    /// footMark フレームの高さ。線はフレーム下端に描かれる
    private let footMarkHeight: CGFloat = 12

    private let glowGradient = LinearGradient(
        colors: [Color(.irisPink), Color(.irisLavender), Color(.irisSky)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let heartCenterY = height / 2
            let footY = height - footInset - footMarkHeight / 2
            let heartWidth: CGFloat = 72
            let heartHeight: CGFloat = 61

            ZStack {
                // ♡の下端から足元線まで縦に繋ぐ破線スパイン
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: heartCenterY + heartHeight / 2 + 6))
                    path.addLine(to: CGPoint(x: centerX, y: footY - 8))
                }
                .stroke(
                    Color.white.opacity(0.75),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 8])
                )
                .shadow(color: Pearl.guideEdge.opacity(0.85), radius: 2)

                // ♡マーカー (白線 + 外側グロウ)
                ZStack {
                    HeartShape()
                        .stroke(glowGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .blur(radius: 5)
                        .opacity(0.85)
                    HeartShape()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .shadow(color: Pearl.guideEdge.opacity(0.9), radius: 2, y: 1)
                }
                .frame(width: heartWidth, height: heartHeight)
                .position(x: centerX, y: heartCenterY)

                // 足元マーカー (下端寄り)
                footMark
                    .position(x: centerX, y: footY)
            }
        }
        .allowsHitTesting(false)
    }

    private var footMark: some View {
        ZStack {
            FootTickShape()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            FootDashShape()
                .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: 2, dash: [5, 6]))
        }
        .frame(width: 112, height: footMarkHeight)
        .shadow(color: Pearl.glowPink.opacity(0.8), radius: 5)
        .shadow(color: Pearl.guideEdge.opacity(0.9), radius: 2, y: 1)
    }
}

/// 足元マーカーの両端 (横線 + 上向きの短い縦線)
struct FootTickShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.maxY - 1
        // 左端
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addLine(to: CGPoint(x: rect.minX + 22, y: y))
        path.move(to: CGPoint(x: rect.minX + 1, y: y))
        path.addLine(to: CGPoint(x: rect.minX + 1, y: rect.minY))
        // 右端
        path.move(to: CGPoint(x: rect.maxX - 22, y: y))
        path.addLine(to: CGPoint(x: rect.maxX, y: y))
        path.move(to: CGPoint(x: rect.maxX - 1, y: y))
        path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.minY))
        return path
    }
}

/// 足元マーカー中央の破線
struct FootDashShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.maxY - 1
        path.move(to: CGPoint(x: rect.minX + 28, y: y))
        path.addLine(to: CGPoint(x: rect.maxX - 28, y: y))
        return path
    }
}

#Preview {
    ZStack {
        Color(.photoBackdrop)
        GuideOverlayView()
    }
    .aspectRatio(3.0 / 4.0, contentMode: .fit)
}
