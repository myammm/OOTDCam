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

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06).ignoresSafeArea() // ベース #08080f

            VStack(spacing: 0) {
                StatusBar()

                // カメラ領域 (3:4 縦, 純正カメラと同じ比率)
                ZStack {
                    Color.black

                    CameraPreviewView(service: viewModel.service)

                    // 撮影ガイド (4隅のブラケット含む)
                    GuideOverlayView()

                    // 全身モード バッジ (左上)
                    FullBodyBadge()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, 14)
                        .padding(.leading, 14)

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
                .clipped()

                Spacer(minLength: 0)

                // 案内テキストストリップ
                CaptionStrip()

                // シャッター領域
                ShutterArea(
                    isAnimating: viewModel.isShutterAnimating,
                    onTap: { viewModel.send(.takePhoto) }
                )

                // 下部余白
                Color(red: 0.03, green: 0.03, blue: 0.06)
                    .frame(height: 26)
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

// MARK: - Status Bar (Y2Kcam タイトルのみ)
struct StatusBar: View {
    var body: some View {
        Text("★ Y2Kcam ★")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(Color.pink)
            .shadow(color: .pink.opacity(0.4), radius: 3)
            .padding(.bottom, 8)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.047, green: 0.047, blue: 0.094),
                        Color(red: 0.055, green: 0.055, blue: 0.102)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(red: 0.541, green: 0.169, blue: 0.886).opacity(0.25))
                    .frame(height: 1)
            }
    }
}

// MARK: - Full Body Mode Badge
struct FullBodyBadge: View {
    @State private var floatY: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            Text("📐")
                .font(.system(size: 11))
            Text("全身モード")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(Color(red: 0.541, green: 0.361, blue: 0.965))
                .shadow(color: Color(red: 0.541, green: 0.361, blue: 0.965).opacity(0.4), radius: 3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(red: 0.541, green: 0.361, blue: 0.965).opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.541, green: 0.361, blue: 0.965).opacity(0.33), lineWidth: 1)
                )
        )
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .offset(y: floatY)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                floatY = -4
            }
        }
    }
}

// MARK: - Date Stamp (レトロデジカメ風)
struct DateStamp: View {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "''yy.MM.dd"
        return f
    }()

    var body: some View {
        Text(Self.formatter.string(from: Date()))
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
            .foregroundStyle(Color.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(red: 0.055, green: 0.055, blue: 0.102))
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
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.055, green: 0.055, blue: 0.102),
                    Color(red: 0.03, green: 0.03, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
