//
//  CameraView.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI

struct CameraView: View {
    let onPhotoTaken: (CapturedPhoto) -> Void
    /// 実測したプレビュー幅の通知先 (AppCoordinator.basePhotoWidth)
    let onPreviewWidthChanged: (CGFloat) -> Void
    @StateObject private var viewModel = CameraViewModel()
    /// プレビュー領域のサイズ。プレビューはガラス縁の内側にレイアウトするので、
    /// 可視矩形はレイヤーのローカル座標 (origin: .zero) で渡す
    @State private var previewSize: CGSize = .zero

    var body: some View {
        ZStack {
            PearlBackground()

            VStack(spacing: 0) {
                // 上部の帯は薄くし、余白を下側に寄せる
                Wordmark()
                    .frame(maxWidth: .infinity)
                    .frame(height: Pearl.topBarHeight)

                cameraPlate

                // ガラスピルに載せる (文字色・寸法は glassPill が持つ)
                Text("♡に顔、線に足先")
                    .glassPill()
                    .padding(.top, 14)

                // シャッターは説明文と画面下端の間で上下センター
                Spacer(minLength: 0)

                ShutterButton(isAnimating: viewModel.isShutterAnimating) {
                    viewModel.send(.takePhoto(visibleRect: CGRect(origin: .zero, size: previewSize)))
                }

                Spacer(minLength: 0)
            }
            // SE (667pt) はこの画面が縦ぴったりで、10pt だとシャッターが下端からはみ出す
            .padding(.bottom, 6)
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
        .onChange(of: viewModel.lastCapturedPhoto) { _, photo in
            if let photo {
                onPhotoTaken(photo)
                viewModel.lastCapturedPhoto = nil
            }
        }
    }

    // MARK: - Camera Plate (ガラス縁の 3:4 プレビュー)

    private var cameraPlate: some View {
        ZStack {
            // セッション起動前のプレースホルダ
            Color(.photoBackdrop)

            // 3:4 のプレビュー (センサーも 3:4 なので aspectFill でほぼ全域が映る)
            if let sample = ScreenshotMode.samplePhoto {
                Image(uiImage: sample)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                CameraPreviewView(service: viewModel.service, gravity: .resizeAspectFill)
            }

            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        previewSize = geo.size
                        onPreviewWidthChanged(geo.size.width)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        previewSize = newSize
                        onPreviewWidthChanged(newSize.width)
                    }
            }

            GuideOverlayView()

            // 位置は編集画面・保存時の焼き込みと揃える (右12pt / 下10pt)
            // スクショモードのサンプル写真はスタンプ焼き込み済みなのでライブ表示しない
            if !ScreenshotMode.isActive {
                DateStamp()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, 10)
                    .padding(.trailing, 12)
            }

            if viewModel.showSparkles {
                SparkleOverlay()
                    .transition(.opacity)
            }

            // 撮影フラッシュの膜 (最前面)
            Pearl.flash
                .opacity(viewModel.showFlash ? 1 : 0)
                .allowsHitTesting(false)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .pearlPlate()
        .padding(.horizontal, Pearl.plateHorizontalPadding)
        .padding(.top, Pearl.plateTopGap)
        // プレビューは全端末でフル幅を保ち、余白側 (Spacer) に縮んでもらう
        .layoutPriority(1)
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
        // 端末言語によらず日付スタンプの数字を欧文数字に固定する
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "''yy.MM.dd"
        return f
    }()

    var body: some View {
        Text(Self.formatter.string(from: date))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(1.0)
            .foregroundStyle(Color(.dateStampText))
            .shadow(color: Color(.dateStampGlow).opacity(0.75), radius: 4.5)
            .shadow(color: .black.opacity(0.7), radius: 1.5, y: 1)
    }
}

// MARK: - Shutter Button (ガラス球 + 虹色リム)
struct ShutterButton: View {
    let isAnimating: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // 虹色リング (iris トークン参照)。ロゴ・完了ボタンと同色になるため、
            // 主役性はサイズと外側のピンクの発光で保つ
            Circle()
                .stroke(Pearl.iris, lineWidth: 3)
                .frame(width: 88, height: 88)
                .opacity(0.9)
                .shadow(color: Pearl.glowPink.opacity(0.7), radius: isAnimating ? 14 : 8)

            // ガラス球
            Circle()
                .fill(RadialGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: Color(.shutterOrb1), location: 0.22),
                        .init(color: Color(.shutterOrb2), location: 0.52),
                        .init(color: Color(.shutterOrb3), location: 0.78),
                        .init(color: Color(.shutterOrb4), location: 1)
                    ],
                    center: UnitPoint(x: 0.34, y: 0.24),
                    startRadius: 0,
                    endRadius: 64
                ))
                .frame(width: 80, height: 80)
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                .shadow(color: Pearl.shadow.opacity(0.5), radius: 11, y: 5)

            // スペキュラハイライト
            Ellipse()
                .fill(Color.white.opacity(0.9))
                .frame(width: 24, height: 15)
                .blur(radius: 2)
                .offset(x: -11, y: -22)
        }
        .scaleEffect(isAnimating ? 0.88 : 1.0)
        .contentShape(Circle())
        .onTapGesture { onTap() }
        .accessibilityLabel("シャッター")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(onPhotoTaken: { _ in }, onPreviewWidthChanged: { _ in })
    }
}
