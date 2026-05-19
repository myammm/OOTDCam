//
//  CameraView.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI

struct CameraView: View {
    let onPhotoTaken: (UIImage) -> Void
    @StateObject private var viewModel = CameraViewModel()
    /// 3:4 可視領域のグローバル座標 (= フルスクリーンプレビューレイヤーの座標と等価)
    @State private var visibleCameraRect: CGRect = .zero

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06).ignoresSafeArea() // ベース #08080f

            // フルスクリーンの単一プレビュー (.resizeAspectFill)
            // 上下クロームの裏側にもカメラが見えるので、半透明クロームで透ける
            CameraPreviewView(service: viewModel.service, gravity: .resizeAspectFill)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                StatusBar()

                // 3:4 可視領域 (透明 — フルスクリーンプレビューが透けて見える)
                ZStack {
                    // 領域のグローバル座標を取得して保存範囲計算用に保持
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { visibleCameraRect = geo.frame(in: .global) }
                            .onChange(of: geo.frame(in: .global)) { _, newRect in
                                visibleCameraRect = newRect
                            }
                    }

                    // 撮影ガイド (4隅のブラケット含む)
                    GuideOverlayView()

                    // 日付スタンプ (右下)
                    DateStamp()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 14)
                        .padding(.trailing, 14)

                    // キラキラ演出
                    if viewModel.showSparkles {
                        SparkleOverlay()
                            .frame(width: 120, height: 120)
                            .transition(.opacity)
                    }
                }
                .aspectRatio(3.0 / 4.0, contentMode: .fit)

                Spacer(minLength: 0)

                CaptionStrip()

                ShutterArea(
                    isAnimating: viewModel.isShutterAnimating,
                    onTap: {
                        viewModel.send(.takePhoto(visibleRect: visibleCameraRect))
                    }
                )

                // 下部余白 (リキッドグラス)
                Color.clear
                    .frame(height: 26)
                    .background(Color.black.opacity(0.55))
            }
        }
        .alert("カメラ権限がありません", isPresented: $viewModel.cameraPermissionDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("カメラを使用するには設定で許可が必要です")
        }
        .alert("写真権限がありません", isPresented: $viewModel.photoLibraryPermissionDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("写真を保存するには設定で許可が必要です")
        }
        .onAppear { viewModel.send(.onAppear) }
        .onDisappear { viewModel.send(.onDisappear) }
        .onChange(of: viewModel.lastCapturedImage) { _, image in
            if let image {
                onPhotoTaken(image)
                viewModel.lastCapturedImage = nil
            }
        }
    }
}

// MARK: - Status Bar (fig.cam タイトルのみ)
struct StatusBar: View {
    var body: some View {
        Text("★ fig.cam ★")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(guidePink)
            .shadow(color: guidePink.opacity(0.4), radius: 3)
            .padding(.bottom, 8)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.55))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(red: 0.541, green: 0.169, blue: 0.886).opacity(0.25))
                    .frame(height: 1)
            }
    }
}

// MARK: - Date Stamp (レトロデジカメ風)
struct DateStamp: View {
    let date: Date

    init(date: Date = Date()) {
        self.date = date
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "''yy.MM.dd"
        return f
    }()

    var body: some View {
        Text(Self.formatter.string(from: date))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(1.0)
            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.21))
            .shadow(color: Color(red: 1.0, green: 0.42, blue: 0.21).opacity(0.67), radius: 4)
            .shadow(color: .black.opacity(0.6), radius: 0, x: 2, y: 2)
    }
}

// MARK: - Caption Strip
struct CaptionStrip: View {
    var body: some View {
        Text("♡に顔、点線に足先を合わせて撮ってね")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(Color.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.black.opacity(0.55))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(red: 0.541, green: 0.169, blue: 0.886).opacity(0.25))
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(red: 0.541, green: 0.169, blue: 0.886).opacity(0.25))
                    .frame(height: 1)
            }
    }
}

// MARK: - Shutter Area
struct ShutterArea: View {
    let isAnimating: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            ShutterButton(isAnimating: isAnimating, onTap: onTap)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(Color.black.opacity(0.55))
    }
}

// MARK: - Shutter Button (シアン系で維持)
struct ShutterButton: View {
    let isAnimating: Bool
    let onTap: () -> Void

    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 90, height: 90)
            .overlay(
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [.cyan, .purple, .pink, .cyan]),
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: isAnimating ? 8 : 2)
                    .opacity(isAnimating ? 1 : 0.6)
            )
            .shadow(color: .cyan.opacity(0.5), radius: 12)
            .scaleEffect(isAnimating ? 0.85 : 1.0)
            .onTapGesture { onTap() }
    }
}

// MARK: - Sparkle Effect
struct SparkleOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Circle()
                    .fill(LinearGradient(colors: [.white, .yellow.opacity(0.6), .clear],
                                         startPoint: .center, endPoint: .bottom))
                    .frame(width: 8, height: 20)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(onPhotoTaken: { _ in })
    }
}
